//
//  PointsOfLightApp.swift
//  PointsOfLight
//
//  Created by Nima Johari on 4/12/25.
//

import SwiftUI
import AppKit
import llbuild2fx
import TSFCASFileTree
import TSCBasic

let IMAGE_FORMATS = ["png", "jpg", "jpg", "JPG", "gif", "webp", "jpeg"]
let VIDEO_FORMATS = ["mov", "mkv", "mp4", "avi", "webm"]
let TEXT_FORMATS = ["txt", "md", "html"]

enum Artifact: Identifiable, Codable, Hashable {
    case localFile(path: String, mime: String?)
    case casBlob(id: LLBDataID, label: String)
    case feed(id: String)

    var id: URL {
        switch self {
        case .feed(id: let id): URL(string: "https://freefeed.net/feed/\(id)")!
        case .casBlob(id: let id, label: _): URL(string: "x-cas://\(id)")!
        case .localFile(path: let path, mime: _): URL(string: "file:///\(path)")!
        }
    }
}

struct GlobalState: Hashable, Codable {
    var selected: Set<Artifact> = []
    var tags: [String: Set<Artifact>] = [:]
    var tagFilter: Set<String> = []

    func isIndirectlyTagged(artifact: Artifact, tag t: String) -> Bool {
        switch artifact {
        case .localFile(let path, let mime):
            break
        case .casBlob(let id, let label):
            return (tags[t] ?? []).contains(where: { artifact in
                switch artifact {
                case .localFile(let path, let mime):
                    false
                case .casBlob(let id_, let label_):
                    id_ == id || label_ == label
                case .feed(let id):
                    false
                }
            })
        case .feed(let id):
            break
        }
        return false
    }

    mutating func isTagged(_ item: WindowMetadata) -> Bool {
        // If tagFilter is empty, display everything that is untagged
        if tagFilter.isEmpty {
            for t in tags.keys {
                // If the artifact exists in verbatim form, it should not be displayed
                if (tags[t] ?? []).contains(item.artifact) {
                    return false
                }
                if isIndirectlyTagged(artifact: item.artifact, tag: t) {
                    return false
                }
            }
            return true
        }

        // Otherwise, display things that match the tag filter
        for t in tagFilter {
            if (tags[t] ?? []).contains(item.artifact) {
                return true
            }
            if isIndirectlyTagged(artifact: item.artifact, tag: t) {
                tags[t]?.insert(item.artifact)
                return true
            }
        }
        return false
    }
}

@main
struct TinyWindowsApp: App {
    @State var globalState: GlobalState = GlobalState()

    var body: some Scene {
        WindowGroup {
            ContentView(globalState: $globalState)
                .onAppear {
                    Task {
                        var ctx = Context()
                        let casPath = NSString("~/.pol-cas/").expandingTildeInPath

                        if !FileManager.default.fileExists(atPath: casPath) {
                            try FileManager.default.createDirectory(
                                at: URL(
                                    fileURLWithPath: casPath
                                ),
                                withIntermediateDirectories: false
                            )
                        }
                        ctx.db = LLBFileBackedCASDatabase(
                            group: .singletonMultiThreadedEventLoopGroup,
                            path: AbsolutePath(casPath)
                        )
                        try await spawnTinyWindows(ctx: ctx)
                        // sortAndLayoutWindowsIntoColumns()
                        try await spawnAggregateWindow(globalState: $globalState, ctx: ctx)
                    }
                }
        }
    }
}

// MARK: spawnHeaderWindows
/*
func spawnHeaderWindows(titles: [String], offset: [Int: Int]) {
    let screenHeight = NSScreen.main?.frame.height ?? 1000
    let y = screenHeight - 40 // just 40px from top

    for (index, title) in titles.enumerated() {
        let window = NSWindow(
            contentRect: NSRect(x: 100 + offset[index]! * 100, y: Int(y), width: 80, height: 30),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        let hostingView = NSHostingView(
            rootView: TinyWindowContent(
                metadata: WindowMetadata(
//                    window: window,
                    kind: "",
                    creationDate: Date.now,
                    width: 30,
                    height: 30,
                    title: title,
                    color: .green,
                    path: ""
                )
            )
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.contentView = hostingView
        window.title = "header:\(title)"
        window.ignoresMouseEvents = true
        window.makeKeyAndOrderFront(nil)
        WindowManager.shared.headers.append(window)
    }
}
*/

//func spawnTinyWindows() {
//    for i in 0..<100 {
//        let title = randomName()
//        let hostingView = NSHostingView(rootView: TinyWindowContent(title: title))
//        let window = NSWindow(
//            contentRect: NSRect(x: 0, y: 0, width: 30, height: 30),
//            styleMask: [.borderless],
//            backing: .buffered,
//            defer: false
//        )
//        window.isOpaque = false
//        window.backgroundColor = .clear
//        window.hasShadow = true
//        window.level = .floating
//        window.contentView = hostingView
//        window.title = title
//        window.makeKeyAndOrderFront(nil)
//
//        let kind = String(title.last ?? "X")
//
//        let randomTimeInterval = TimeInterval.random(in: 0...(DateComponents(calendar: .current, year: 2030).date!.timeIntervalSince1970))
//        let creationDate = Date(timeIntervalSince1970: randomTimeInterval)
//        let metadata = WindowManager.WindowMetadata(window: window, kind: kind, creationDate: creationDate)
//
//        WindowManager.shared.entries.append(metadata)
//    }
//}

func spawnTinyWindows(ctx: Context) async throws {
    let desktop1 = try await Desktop(
        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop"),
        ctx: ctx
    )
//    let desktop2 = Desktop(path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents"))

    let desktop3 = try await Desktop(
        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").appendingPathComponent("pngs"),
        ctx: ctx
    )

//    let union = desktop1 + desktop2

    let union = desktop1 + desktop3

    WindowManager.shared.entries = union.entries
}

@MainActor
func spawnAggregateWindow(globalState: Binding<GlobalState>, ctx: Context) async throws {
    let desktop1 = try await Desktop(
        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop"),
        ctx: ctx
    )
//    let desktop2 = Desktop(path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents"))

    let desktop3 = try await Desktop(
        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").appendingPathComponent("pngs"),
        ctx: ctx
    )
    let desktop4 = try await Desktop(
        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").appendingPathComponent("x").appendingPathComponent("x"),
        ctx: ctx
    )

    let desktopMDs = try await Desktop(
        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").appendingPathComponent("md"),
        ctx: ctx
    )

//    let union = desktop1 + desktop2

    let union = desktop3 + desktopMDs // + desktop3 + desktop4

    WindowManager.shared.entries = union.entries

    // Window
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: NSScreen.main!.frame.width, height: NSScreen.main!.frame.height),
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )

//    let hostingView = NSHostingView(rootView: AggregateView(entries: union.entries))
    let hostingView = NSHostingView(
        rootView: RepellingViews(
            entries: union.entries,
            globalState: globalState,
            ctx: ctx
        )
    )

    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true
    window.level = .floating
    window.contentView = hostingView
    window.title = "BetterDesktop"
    window.makeKeyAndOrderFront(nil)
}

//
//func spawnTinyWindows() {
//    let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
//
//    guard let contents = try? FileManager.default.contentsOfDirectory(at: desktopURL, includingPropertiesForKeys: [.creationDateKey, .isDirectoryKey], options: [.skipsHiddenFiles]) else {
//        print("Failed to read Desktop contents")
//        return
//    }
//
//    for fileURL in contents.prefix(200) {
//        let title = fileURL.lastPathComponent
//        let ext = fileURL.pathExtension.lowercased()
//        let kind = ext.isEmpty ? "unknown" : ext
//
//        let resourceValues = try? fileURL.resourceValues(forKeys: [.creationDateKey, .isDirectoryKey])
//        let creationDate = resourceValues?.creationDate ?? Date()
//
//        // View
//        let hostingView = NSHostingView(rootView: TinyWindowContent(title: title))
//
//        // Window
//        let window = NSWindow(
//            contentRect: NSRect(x: 0, y: 0, width: 80, height: 80),
//            styleMask: [.borderless],
//            backing: .buffered,
//            defer: false
//        )
//        window.isOpaque = false
//        window.backgroundColor = .clear
//        window.hasShadow = true
//        window.level = .floating
//        window.contentView = hostingView
//        window.title = title
//        window.makeKeyAndOrderFront(nil)
//
//        // Metadata
//        let metadata = WindowManager.WindowMetadata(window: window, kind: kind, creationDate: creationDate)
//        WindowManager.shared.entries.append(metadata)
//    }
//}

func randomName() -> String {
    let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return String((0..<5).map { _ in letters.randomElement()! })
}

struct TinyWindowContent: View {
    let metadata: WindowMetadata
    let ctx: Context
    @State var fileContents: LLBByteBuffer? = nil
    @State var fileLabel: String? = nil

    init(metadata: WindowMetadata, ctx: Context, fileContents: LLBByteBuffer? = nil) {
        self.metadata = metadata
        self.ctx = ctx
        self.fileContents = fileContents
    }

    var body: some View {
        Group {
            if let fileContents, let fileLabel {
                let ext = URL(fileURLWithPath: fileLabel).pathExtension
                if IMAGE_FORMATS.contains(ext) {
                    Image(nsImage: NSImage(data: Data(fileContents.readableBytesView))!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: metadata.width, height: metadata.height)
                        .font(.caption2)
                        .background(metadata.color.opacity(0.9))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 0.5))
                } else if TEXT_FORMATS.contains(ext) {
                    Text(String(bytes: fileContents.readableBytesView, encoding: .utf8)!)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: metadata.width, height: metadata.height)
                        .font(.caption2)
                        .background(metadata.color.opacity(0.9))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 0.5))
                } else {
                    Text(metadata.title)
                        .font(.caption2)
                        .frame(width: metadata.width, height: metadata.height)
                        .background(metadata.color.opacity(0.9))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 0.5))
                }
            } else {
                Text("Loading image from CAS database")
            }
        }.onAppear {
            Task {
                let client = LLBCASFSClient(self.ctx.db)
                print("Loading \(self.metadata.artifact)")
                switch self.metadata.artifact {
                case .localFile(let path, let mime):
                    throw StringError("Not implmeneted")
                case .casBlob(let id, let label):
                    if let ic = try? await client.load(id, self.ctx).get().blob?.read(self.ctx).get() {
                        self.fileContents = LLBByteBuffer(ic)
                        self.fileLabel = label
                    }
                case .feed(let id):
                    throw StringError("Not implemented")
                }
            }
        }
    }
}

struct WindowMetadata: Identifiable, Hashable {
    var id: Artifact {
        artifact
    }

//    let window: NSWindow
    let kind: String // mock grouping
    let creationDate: Date
    let width: CGFloat
    let height: CGFloat
    let title: String
    let color: Color
    let artifact: Artifact

    var size: CGSize {
        CGSize(width: width, height: height)
    }
}

class WindowManager {
    static let shared = WindowManager()
    var headers: [NSWindow] = []

    var entries: [WindowMetadata] = []

//    var windows: [NSWindow] {
//        entries.map(\.window)
//    }
}

func sortAndLayoutWindowsIntoColumns() {
    let grouped = Dictionary(grouping: WindowManager.shared.entries, by: { "\($0.title.first ?? ")")" }).sorted(by: { $0.key < $1.key })
    
    layoutGrouped(grouped)
}

func groupByKindAndLayout() {
    let grouped = Dictionary(grouping: WindowManager.shared.entries, by: \.kind).sorted(by: { $0.key < $1.key })
    layoutGrouped(grouped)
}

func groupByMonthAndLayout() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM"

    let grouped = Dictionary(grouping: WindowManager.shared.entries) { entry in
        dateFormatter.string(from: entry.creationDate)
    }.sorted(by: { $0.key < $1.key })


    layoutGrouped(grouped)
}

let screenHeight = NSScreen.main?.frame.height ?? 1000
let startY = Int(screenHeight - 100)

let startX = 100
let columnSpacing = 100
let rowSpacing = 10


func layoutGrouped(_ grouped: [(String, [WindowMetadata])]) {
    let screenHeight = NSScreen.main?.frame.height ?? 1000
    let startX = 100
    let topY = screenHeight - 40
    let contentStartY = screenHeight - 100
    let columnSpacing = 100
    let rowSpacing = 90

    var offset: [Int: Int] = [:]

    // 3. Layout content windows
    var columnOffset = 0
    for (columnIndex, (_, group)) in grouped.enumerated() {
        offset[columnIndex] = columnIndex + columnOffset

        var prevY = Int(contentStartY)
        for (rowIndex, entry) in group.sorted(by: { $0.width*$0.height > $1.width*$1.height }).enumerated() {
            let x = startX + (columnIndex + columnOffset) * columnSpacing
            let y = prevY - Int(entry.height)
//            entry.window.setFrameOrigin(NSPoint(x: x, y: y))
            prevY -= Int(entry.height) + 10
            if prevY < 300 {
                columnOffset += 1
                prevY = Int(contentStartY)
            }
        }
    }

    // 1. Clear existing headers
    for header in WindowManager.shared.headers {
        header.close()
    }
    WindowManager.shared.headers.removeAll()

    // 2. Create new headers
    let columnLabels = grouped.map { $0.0 }
    //spawnHeaderWindows(titles: columnLabels, offset: offset)
}

func imageDimensions(at path: String) -> CGSize? {
    guard let image = NSImage(contentsOfFile: path) else {
        print("Unable to find sizes for \(path)")
        return nil
    }
    print(image.size)
    return image.size
}

struct Desktop {
    var entries: [WindowMetadata]
    var ctx: Context

    init(path: URL, ctx: Context) async throws {
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

            var size: CGSize? = nil
            if IMAGE_FORMATS.contains(kind) {
                size = imageDimensions(at: url.path(percentEncoded: false))
            } else if TEXT_FORMATS.contains(kind) {
                size = CGSize(width: 400, height: 400)
            }

            let client = LLBCASFSClient(ctx.db)
            let dataID = try await client.store(Data(contentsOf: url), ctx).get()

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
