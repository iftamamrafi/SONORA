
import Foundation
import AVFoundation
import MediaPlayer
import UIKit

enum PlaybackStatus { case idle, loading, playing, paused, failed }

/// Central playback engine. One AVPlayer handles local files and remote streams.
/// When EQ is enabled and the track is a local file, playback routes through LocalEQPlayer instead.
@MainActor
@Observable
final class PlaybackManager {
    var queue = PlaybackQueue()
    var status: PlaybackStatus = .idle
    var currentTime: Double = 0
    var duration: Double = 0
    var volume: Float = 1.0 { didSet { applyVolume() } }
    var isMuted: Bool = false { didSet { applyVolume() } }
    var playbackSpeed: Double = 1.0 { didSet { if status == .playing { player.rate = Float(playbackSpeed) } } }
    var errorMessage: String?
    var sleepTimerRemaining: TimeInterval?
    /// Set by the app so playback events persist history / play counts.
    var onTrackStarted: ((TrackSnapshot) -> Void)?
    var onListeningProgress: ((TrackSnapshot, Double) -> Void)?

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var itemObserver: NSObjectProtocol?
    private let eqPlayer = LocalEQPlayer()
    private(set) var usingEQEngine = false
    var eqEnabled: Bool = false { didSet { /* routing decided at next play() */ } }
    var eqGains: [Float] = EQPreset.named("Normal").gains { didSet { eqPlayer.applyGains(eqGains) } }
    private var sleepTimer: Timer?
    private var fadeTimer: Timer?
    private var wasPlayingBeforeInterruption = false
    private var progressTicker: Timer?
    private var lastReportedTrackID: UUID?

    var currentTrack: TrackSnapshot? { queue.current }
    var isPlaying: Bool { status == .playing }
    var progress: Double { duration > 0 ? min(currentTime / duration, 1) : 0 }

    init() {
        configureAudioSession()
        setupRemoteCommands()
        setupNotifications()
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                if !self.usingEQEngine {
                    self.currentTime = CMTimeGetSeconds(time)
                    if let d = self.player.currentItem?.duration.seconds, d.isFinite { self.duration = d }
                }
            }
        }
        eqPlayer.onFinished = { [weak self] in
            Task { @MainActor in self?.handleTrackEnded() }
        }
        // Tick for EQ engine position (reads real node time, not a fake timer).
        progressTicker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.usingEQEngine else { return }
                self.currentTime = self.eqPlayer.currentTime
                self.duration = self.eqPlayer.duration
            }
        }
    }

    // MARK: - Session / remote / interruptions
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { errorMessage = "Audio session error: \(error.localizedDescription)" }
    }
    private func setupNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            guard let self, let info = note.userInfo,
                  let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            let opts = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor in
                switch type {
                case .began: self.wasPlayingBeforeInterruption = self.isPlaying; self.pauseInternal()
                case .ended:
                    if AVAudioSession.InterruptionOptions(rawValue: opts).contains(.shouldResume), self.wasPlayingBeforeInterruption { self.resume() }
                @unknown default: break
                }
            }
        }
        nc.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            guard let self, let info = note.userInfo,
                  let raw = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable else { return }
            Task { @MainActor in self.pauseInternal() }  // headphones unplugged
        }
        itemObserver = nc.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.handleTrackEnded() }
        }
        nc.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: nil, queue: .main) { [weak self] note in
            let message = (note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error)?.localizedDescription ?? "The stream could not be played."
            Task { @MainActor in
                guard let self, !self.usingEQEngine else { return }
                self.status = .failed
                self.errorMessage = SonoraError.playbackFailed(message).localizedDescription
                self.updateNowPlayingInfo()
            }
        }
    }
    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in self?.resume(); return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in self?.togglePlayPause(); return .success }
        center.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        center.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let e = event as? MPChangePlaybackPositionCommandEvent { self?.seek(to: e.positionTime) }
            return .success
        }
    }
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else { MPNowPlayingInfoCenter.default().nowPlayingInfo = nil; return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artistName,
            MPMediaItemPropertyAlbumTitle: track.albumTitle,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration > 0 ? duration : track.duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackSpeed : 0
        ]
        if let data = track.artworkData, let img = UIImage(data: data) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Public controls
    func play(tracks: [TrackSnapshot], startAt index: Int = 0) {
        queue.setQueue(tracks, startAt: index)
        if queue.isShuffled { queue.setShuffle(true) }
        startCurrent()
    }
    func playSingle(_ track: TrackSnapshot) { play(tracks: [track]) }
    func togglePlayPause() { isPlaying ? pause() : resume() }
    func pause() { pauseInternal() }
    private func pauseInternal() {
        if usingEQEngine { eqPlayer.pause() } else { player.pause() }
        status = currentTrack == nil ? .idle : .paused
        updateNowPlayingInfo()
        if let track = currentTrack { LiveActivityManager.shared.update(track: track, isPlaying: false, progress: progress) }
    }
    func resume() {
        guard currentTrack != nil else { return }
        configureAudioSession()
        if usingEQEngine { eqPlayer.play() } else { player.play(); player.rate = Float(playbackSpeed) }
        status = .playing
        updateNowPlayingInfo()
        if let track = currentTrack { LiveActivityManager.shared.update(track: track, isPlaying: true, progress: progress) }
    }
    func stop() {
        player.pause(); eqPlayer.stop()
        queue.clear(); status = .idle; currentTime = 0; duration = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    func next() { if let t = queue.advance(auto: false) { startTrack(t) } else { startCurrent() } }
    func previous() {
        if currentTime > 3 { seek(to: 0); return }
        if let t = queue.back() { startTrack(t) }
    }
    func seek(to time: Double) {
        if usingEQEngine { eqPlayer.seek(to: time); currentTime = time }
        else { player.seek(to: CMTime(seconds: time, preferredTimescale: 600)); currentTime = time }
        updateNowPlayingInfo()
    }
    func toggleShuffle() { queue.setShuffle(!queue.isShuffled) }
    func cycleRepeat() { queue.repeatMode = queue.repeatMode.next }
    func addToQueue(_ track: TrackSnapshot) { queue.append(track) }
    func playNext(_ track: TrackSnapshot) { queue.insertNext(track) }
    func removeFromQueue(_ track: TrackSnapshot) {
        let wasCurrent = currentTrack?.id == track.id
        queue.remove(trackID: track.id)
        if wasCurrent { if let t = queue.current { startTrack(t) } else { stop() } }
    }
    func clearQueue() { queue.clearUpcoming() }
    func jumpToQueueItem(_ track: TrackSnapshot) {
        if let t = queue.jump(to: track.id) { startTrack(t) }
    }

    // MARK: - Engine routing
    private func startCurrent() { if let t = queue.current { startTrack(t) } }
    private func startTrack(_ track: TrackSnapshot) {
        errorMessage = nil
        status = .loading
        currentTime = 0
        duration = track.duration
        guard let url = track.playbackURL else {
            status = .failed; errorMessage = SonoraError.fileMissing(track.title).localizedDescription; return
        }
        if track.isLocalFile && !FileManager.default.fileExists(atPath: url.path) {
            status = .failed; errorMessage = SonoraError.fileMissing(track.title).localizedDescription; return
        }
        let routeEQ = eqEnabled && track.isLocalFile
        if routeEQ {
            player.pause()
            do {
                try eqPlayer.load(url: url)
                eqPlayer.applyGains(eqGains)
                eqPlayer.setVolume(isMuted ? 0 : volume)
                usingEQEngine = true
                eqPlayer.play()
                status = .playing
            } catch {
                usingEQEngine = false
                status = .failed; errorMessage = SonoraError.playbackFailed(error.localizedDescription).localizedDescription; return
            }
        } else {
            eqPlayer.stop()
            usingEQEngine = false
            let item = AVPlayerItem(url: url)
            player.replaceCurrentItem(with: item)
            player.volume = isMuted ? 0 : volume
            player.play()
            player.rate = Float(playbackSpeed)
            status = .playing
        }
        if lastReportedTrackID != track.id {
            lastReportedTrackID = track.id
            onTrackStarted?(track)
        }
        updateNowPlayingInfo()
        LiveActivityManager.shared.update(track: track, isPlaying: true, progress: 0)
    }
    private func handleTrackEnded() {
        if let track = currentTrack { onListeningProgress?(track, duration) }
        if queue.repeatMode == .one {
            seek(to: 0); resume(); return
        }
        if let next = queue.advance(auto: true) { startTrack(next) }
        else {
            status = .paused; currentTime = 0
            player.seek(to: .zero)
            updateNowPlayingInfo()
            LiveActivityManager.shared.end()
        }
    }
    private func applyVolume() {
        player.volume = isMuted ? 0 : volume
        eqPlayer.setVolume(isMuted ? 0 : volume)
    }

    // MARK: - Sleep timer (with fade-out)
    func setSleepTimer(minutes: Double) {
        cancelSleepTimer()
        let total = minutes * 60
        sleepTimerRemaining = total
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let remaining = self.sleepTimerRemaining else { return }
                self.sleepTimerRemaining = remaining - 1
                if remaining <= 10 { // fade out over final 10 seconds
                    let f = Float(max(remaining - 1, 0)) / 10
                    self.player.volume = (self.isMuted ? 0 : self.volume) * f
                    self.eqPlayer.setVolume((self.isMuted ? 0 : self.volume) * f)
                }
                if remaining <= 0 {
                    self.pauseInternal()
                    self.player.volume = self.isMuted ? 0 : self.volume
                    self.cancelSleepTimer()
                }
            }
        }
    }
    func cancelSleepTimer() {
        sleepTimer?.invalidate(); sleepTimer = nil; fadeTimer = nil
        sleepTimerRemaining = nil
    }
}
