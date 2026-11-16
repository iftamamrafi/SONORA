
import Foundation
import SwiftData

struct DownloadTaskInfo: Identifiable {
    var id: UUID { track.id }
    var track: TrackSnapshot
    var progress: Double = 0
    var isPaused: Bool = false
}

/// Downloads only tracks whose provider permits offline storage (demo tracks set downloadable=true).
@MainActor
@Observable
final class DownloadManager: NSObject {
    var active: [UUID: DownloadTaskInfo] = [:]
    var errorMessage: String?
    private var tasks: [UUID: URLSessionDownloadTask] = [:]
    private var resumeData: [UUID: Data] = [:]
    private lazy var session: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    var modelContext: ModelContext?

    func download(_ track: TrackSnapshot) {
        guard track.downloadable, let s = track.streamURLString, let url = URL(string: s) else {
            errorMessage = "This track's provider does not permit offline downloads."; return
        }
        guard active[track.id] == nil else { return }
        active[track.id] = DownloadTaskInfo(track: track)
        let task = session.downloadTask(with: url)
        tasks[track.id] = task
        task.resume()
    }
    func pause(_ track: TrackSnapshot) {
        tasks[track.id]?.cancel(byProducingResumeData: { [weak self] data in
            Task { @MainActor in
                if let data { self?.resumeData[track.id] = data }
                self?.active[track.id]?.isPaused = true
            }
        })
    }
    func resume(_ track: TrackSnapshot) {
        guard let data = resumeData[track.id] else { download(track); return }
        let task = session.downloadTask(withResumeData: data)
        tasks[track.id] = task
        active[track.id]?.isPaused = false
        task.resume()
    }
    func cancel(_ track: TrackSnapshot) {
        tasks[track.id]?.cancel()
        tasks[track.id] = nil; active[track.id] = nil; resumeData[track.id] = nil
    }
    fileprivate func finish(trackID: UUID, location: URL) {
        guard let info = active[trackID] else { return }
        let dest = LocalMusicService.downloadsFolder.appendingPathComponent(trackID.uuidString + "-" + location.lastPathComponent)
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            if let ctx = modelContext {
                let rel = "Downloads/" + dest.lastPathComponent
                var snap = info.track
                snap.source = .downloaded; snap.localRelativePath = rel; snap.streamURLString = info.track.streamURLString
                let entity = TrackEntity(id: snap.id, title: snap.title, artistName: snap.artistName,
                                         albumTitle: snap.albumTitle, genre: snap.genre, duration: snap.duration,
                                         sourceRaw: TrackSource.downloaded.rawValue, localRelativePath: rel,
                                         providerID: snap.providerName, providerTrackID: snap.providerTrackID,
                                         streamURLString: snap.streamURLString, artworkData: snap.artworkData)
                // Replace any existing entity with same id.
                let existing = (try? ctx.fetch(FetchDescriptor<TrackEntity>())) ?? []
                if let found = existing.first(where: { $0.id == snap.id }) {
                    found.sourceRaw = TrackSource.downloaded.rawValue
                    found.localRelativePath = rel
                    if found.artworkData == nil { found.artworkData = snap.artworkData }
                } else { ctx.insert(entity) }
                try? ctx.save()
            }
        } catch { errorMessage = error.localizedDescription }
        active[trackID] = nil; tasks[trackID] = nil
    }
    fileprivate func updateProgress(trackID: UUID, progress: Double) { active[trackID]?.progress = progress }
    fileprivate func task(for task: URLSessionTask) -> UUID? { tasks.first { $0.value == task }?.key }
}

extension DownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Move file synchronously to a temp location before the callback returns.
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "-" + (downloadTask.response?.suggestedFilename ?? "audio.mp3"))
        try? FileManager.default.copyItem(at: location, to: tmp)
        Task { @MainActor in
            if let id = self.task(for: downloadTask) { self.finish(trackID: id, location: tmp) }
        }
    }
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let p = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor in
            if let id = self.task(for: downloadTask) { self.updateProgress(trackID: id, progress: p) }
        }
    }
}
