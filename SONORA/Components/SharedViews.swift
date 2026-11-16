
import SwiftUI
import SwiftData

struct ArtworkView: View {
    var data: Data?
    var size: CGFloat = 52
    var corner: CGFloat = 10
    var body: some View {
        Group {
            if let data, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [DS.accentSecondary, DS.surface], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "music.note").foregroundStyle(.white.opacity(0.85))
                        .font(.system(size: size * 0.38))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: corner))
    }
}

struct SourceBadge: View {
    var source: TrackSource
    var isDemo: Bool = false
    var body: some View {
        Text(isDemo ? "DEMO" : source.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(DS.accent.opacity(0.22), in: Capsule())
            .foregroundStyle(DS.accent)
    }
}

struct SongRow: View {
    var track: TrackSnapshot
    var isCurrent: Bool = false
    var showArtwork: Bool = true
    var onTap: () -> Void
    var menuContent: (() -> AnyView)? = nil
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if showArtwork { ArtworkView(data: track.artworkData, size: 50) }
                VStack(alignment: .leading, spacing: 3) {
                    Text(track.title).font(.subheadline.weight(.semibold))
                        .foregroundStyle(isCurrent ? DS.accent : DS.textPrimary).lineLimit(1)
                    Text(track.artistName).font(.caption).foregroundStyle(DS.textSecondary).lineLimit(1)
                }
                Spacer()
                SourceBadge(source: track.source, isDemo: track.isDemo)
                if track.duration > 0 {
                    Text(DS.timeString(track.duration)).font(.caption).foregroundStyle(DS.textSecondary)
                        .monospacedDigit()
                }
                if isCurrent { Image(systemName: "waveform").foregroundStyle(DS.accent).symbolEffect(.variableColor.iterative, isActive: true) }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct SectionHeader: View {
    var title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack {
            Text(title).font(.title3.bold()).foregroundStyle(DS.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action).font(.subheadline).foregroundStyle(DS.accent)
            }
        }
    }
}

struct EmptyStateView: View {
    var icon: String
    var title: String
    var message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 44)).foregroundStyle(DS.accent)
            Text(title).font(.title3.bold()).foregroundStyle(DS.textPrimary)
            Text(message).font(.subheadline).foregroundStyle(DS.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).font(.headline)
                        .padding(.horizontal, 22).padding(.vertical, 12)
                        .background(DS.accent, in: Capsule()).foregroundStyle(.black)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

struct TrackCard: View {
    var track: TrackSnapshot
    var width: CGFloat = 150
    var onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ArtworkView(data: track.artworkData, size: width, corner: 14)
                Text(track.title).font(.subheadline.weight(.semibold)).foregroundStyle(DS.textPrimary).lineLimit(1)
                Text(track.artistName).font(.caption).foregroundStyle(DS.textSecondary).lineLimit(1)
            }
            .frame(width: width)
        }
        .buttonStyle(.plain)
    }
}

/// Shared importer modifier: fileImporter + import + result alert.
struct ImportModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    @State private var resultMessage: String?
    func body(content: Content) -> some View {
        content
            .fileImporter(isPresented: $isPresented, allowedContentTypes: LocalMusicService.supportedTypes, allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    Task {
                        let r = await LocalMusicService.importFiles(urls, into: context)
                        resultMessage = "Imported \(r.imported) track(s). \(r.duplicates) duplicate(s) skipped, \(r.failed) failed."
                    }
                case .failure(let error):
                    resultMessage = error.localizedDescription
                }
            }
            .alert("Import Music", isPresented: Binding(get: { resultMessage != nil }, set: { if !$0 { resultMessage = nil } })) {
                Button("OK") { resultMessage = nil }
            } message: { Text(resultMessage ?? "") }
    }
}
extension View {
    func musicImporter(isPresented: Binding<Bool>) -> some View { modifier(ImportModifier(isPresented: isPresented)) }
}

/// Context-menu helper used across lists.
struct TrackActionsMenu: View {
    var track: TrackSnapshot
    var onEditMetadata: (() -> Void)? = nil
    @Environment(PlaybackManager.self) private var playback
    @Environment(DownloadManager.self) private var downloads
    @Environment(\.modelContext) private var context
    var body: some View {
        Group {
            Button { playback.playNext(track) } label: { Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward") }
            Button { playback.addToQueue(track) } label: { Label("Add to Queue", systemImage: "text.badge.plus") }
            Button { toggleFavorite() } label: { Label("Toggle Favorite", systemImage: "heart") }
            if let onEditMetadata {
                Button { onEditMetadata() } label: { Label("Edit Metadata", systemImage: "pencil") }
            }
            if track.downloadable {
                Button { downloads.download(track) } label: { Label("Download (Demo)", systemImage: "arrow.down.circle") }
            }
        }
    }
    private func toggleFavorite() {
        let all = (try? context.fetch(FetchDescriptor<TrackEntity>())) ?? []
        if let entity = all.first(where: { $0.id == track.id }) {
            entity.isFavorite.toggle(); try? context.save()
        }
    }
}
