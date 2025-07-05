
import llbuild2fx
import Foundation
import TSCBasic
import TSFCASFileTree
import SwiftUI

struct Desktop {
    var entries: [WindowMetadata]
    var ctx: Context

    init(user: String, engine: FXBuildEngine, ctx: Context) async throws {
        self.ctx = ctx

        let timelines = try await engine.build(key: FetchTimeline(user: user), ctx).get().timelines

        self.entries = timelines.map { timeline in
            timeline.posts.map {
                WindowMetadata(
                    kind: "md",
                    creationDate: Date.now,
                    width: 400,
                    height: 100,
                    title: $0.body,
                    color: .green,
                    artifact: .feed(id: $0.id, post: $0, timeline: timeline)
                )
            }
        }.flatMap { $0 }
    }

    init(path: URL, engine: FXBuildEngine, ctx: Context) async throws {
        var collected: [WindowMetadata] = []

        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: path,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            self.entries = []
            throw StringError("Unable to fetch contents of directory: '\(path)'")
        }

        // Fetch size data first
        var sizes: [Int] = []
        var fileData: [(url: URL, values: URLResourceValues)] = []

        for url in contents {
            guard let values = try? url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey, .isDirectoryKey]),
                  values.isDirectory != true else { continue }

            if let size = values.fileSize {
                sizes.append(size)
                fileData.append((url, values))
            }
        }

        // Determine min/max for scaling
        let minSize = Double(sizes.min() ?? 1)
        let maxSize = Double(sizes.max() ?? 1)
        let sizeRange = max(maxSize - minSize, 1)

        // Convert size to window size range (60...200 pts)
        func sizeToWindowSize(_ size: Int) -> CGFloat {
            let normalized = (Double(size) - minSize) / sizeRange
            return CGFloat(100+normalized * 200)
        }


        for (url, values) in fileData {
            let title = url.lastPathComponent
            let kind = url.pathExtension.isEmpty ? "unknown" : url.pathExtension
            let creationDate = values.creationDate ?? Date()
            let fileSize = values.fileSize ?? 1
            let windowSize = sizeToWindowSize(fileSize)


//
//            // Window
//            let window = NSWindow(
//                contentRect: NSRect(x: 0, y: 0, width: windowSize, height: windowSize),
//                styleMask: [.borderless],
//                backing: .buffered,
//                defer: false
//            )
//
            func colorByKind(_ kind: String) -> Color {
                if IMAGE_FORMATS.contains(kind) {
                    return .purple
                } else if VIDEO_FORMATS.contains(kind) {
                    return .blue
                } else if kind == "md" {
                    return .yellow
                } else {
                    return .white
                }
            }

            let client = LLBCASFSClient(ctx.db)
            let dataID = try await client.store(Data(contentsOf: url), ctx).get()

            var size: CGSize? = nil
            if IMAGE_FORMATS.contains(kind) {
                size = try await engine.build(key: ImageDimension(imageID: dataID), ctx).get().size
            } else if TEXT_FORMATS.contains(kind) {
                size = CGSize(width: 400, height: 400)
            }



            let metadata = WindowMetadata(
//                window: window,
                kind: kind,
                creationDate: creationDate,
                width: size?.width ?? CGFloat(Int.random(in: 50..<120)),
                height: size?.height ?? CGFloat(Int.random(in: 50..<120)),
                title: title,
                color: colorByKind(kind),
                artifact: .casBlob(id: dataID, label: "\(url)")
            )
//
//            let hostingView = NSHostingView(rootView: TinyWindowContent(metadata: metadata))
//
//
//            window.isOpaque = false
//            window.backgroundColor = .clear
//            window.hasShadow = true
//            window.level = .floating
//            window.contentView = hostingView
//            window.title = title
//            window.makeKeyAndOrderFront(nil)
//

            collected.append(
                metadata
            )
        }

        self.entries = collected
        self.ctx = ctx
    }

    static func + (lhs: Desktop, rhs: Desktop) -> Desktop {
        Desktop(entries: lhs.entries + rhs.entries, ctx: lhs.ctx)
    }

    private init(entries: [WindowMetadata], ctx: Context) {
        self.entries = entries
        self.ctx = ctx
    }
}
