//
//  PointsOfLightApp.swift
//  PointsOfLight
//
//  Created by Nima Johari on 4/12/25.
//

import MillerKitExtras
import SwiftUI
import AppKit
import llbuild2fx
import TSFCASFileTree
import TSCBasic
import llbuild2

@main
struct TinyWindowsApp: App {
    @ObservedObject var globalState: GlobalState = GlobalState()

    var body: some Scene {
        WindowGroup {
            ContentView(globalState: globalState)
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
                        ctx.freefeedKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXBlIjoiYXBwLnYxIiwiaWQiOiIwMWVjM2FkMS1hNDlhLTQ3MmItYWQxMS1kMzZhODY3OGJlZDQiLCJpc3N1ZSI6MSwidXNlcklkIjoiM2M3NjMyNTUtMTY4ZC00NzM3LTgxYmItYzBlODZiYWUwNjc0IiwiaWF0IjoxNzQ1NDA3MzQ5fQ.0zDf5ZkvwoQpbXvjpaR0WzUSZG3EgsqCSoSVRn0yP58"
                        // try await spawnTinyWindows(ctx: ctx)
                        // sortAndLayoutWindowsIntoColumns()
                        try await spawnAggregateWindow(globalState: globalState, ctx: ctx)
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

//func spawnTinyWindows(ctx: Context) async throws {
//    let freefeed = try await Desktop(user: "ashsabzi", ctx: ctx)
//
//    let desktop1 = try await Desktop(
//        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop"),
//        ctx: ctx
//    )
////    let desktop2 = Desktop(path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents"))
//
//    let desktop3 = try await Desktop(
//        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").appendingPathComponent("pngs"),
//        ctx: ctx
//    )
//
////    let union = desktop1 + desktop2
//
//    let union = freefeed + desktop1 + desktop3
//
//    WindowManager.shared.entries = union.entries
//}

@MainActor
func spawnAggregateWindow(globalState: GlobalState, ctx: Context) async throws {
    let functionCachePath = NSString("~/.pol-function-cache/").expandingTildeInPath

    if !FileManager.default.fileExists(atPath: functionCachePath) {
        try FileManager.default.createDirectory(
            at: URL(
                fileURLWithPath: functionCachePath
            ),
            withIntermediateDirectories: false
        )
    }

    let functionCache = LLBFileBackedFunctionCache(group: .singletonMultiThreadedEventLoopGroup, path: AbsolutePath(functionCachePath))

    let engine = FXBuildEngine(
        group: .singletonMultiThreadedEventLoopGroup,
        db: ctx.db,
        functionCache: functionCache,
        executor: FXNullExecutor()
    )

    let freefeed = try await Desktop(user: "ashsabzi", engine: engine, ctx: ctx)

    let desktop1 = try await Desktop(
        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop"),
        engine: engine,
        ctx: ctx
    )
//    let desktop2 = Desktop(path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents"))

    let desktop3 = try await Desktop(
        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").appendingPathComponent("pngs"),
        engine: engine,
        ctx: ctx
    )
    let desktop4 = try await Desktop(
        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").appendingPathComponent("x").appendingPathComponent("x"),
        engine: engine,
        ctx: ctx
    )

    let desktopMDs = try await Desktop(
        path: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").appendingPathComponent("md"),
        engine: engine,
        ctx: ctx
    )

//    let union = desktop1 + desktop2

    // let union = freefeed + desktop3 + desktop1 + desktopMDs
    let union = freefeed + desktopMDs

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
            engine: engine,
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
