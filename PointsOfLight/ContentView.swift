//
//  ContentView.swift
//  PointsOfLight
//
//  Created by Nima Johari on 4/12/25.
//

import SwiftUI

struct LayoutRegion {
    var origin: CGPoint
    var size: CGSize
}

struct WindowLayout: Equatable {
    var position: CGPoint
    var scale: CGFloat
}

struct RepellingViews: View {
    @State private var entries: [WindowMetadata]
    @State private var layout: [String: WindowLayout] = [:]
    @Binding private var globalState: GlobalState

    public init(entries: [WindowMetadata], globalState: Binding<GlobalState>) {
        self._entries = State(initialValue: entries)
        self._globalState = globalState
    }

    var body: some View {
        VStack {
            Color.clear.frame(height: 40) // adds exact 40pt space
            HStack {
                ForEach(Array(globalState.tags.keys.sorted()), id: \.self) { tag in
                    Button(tag) {
                        if globalState.tagFilter.contains(tag) {
                            globalState.tagFilter.remove(tag)
                        } else {
                            globalState.tagFilter.insert(tag)
                        }
                        globalState.selected = []
                    }.border(globalState.tagFilter.contains(tag) ? .purple : .clear, width: 5)
                }
            }
            body_
        }
    }

    let configURL = URL(filePath: NSString("~/.pol.json").expandingTildeInPath)

    var body_: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(entries, id: \.self) { entry in
                    if let info = layout[entry.id] {
                        TinyWindowContent(metadata: entry)
                            .border(globalState.selected.contains(entry.id) ? .black : Color.blue, width: globalState.selected.contains(entry.id) ? 10 : 2)
                            .frame(width: entry.size.width, height: entry.size.height)
                            .onTapGesture {
                                if globalState.selected.contains(entry.id) {
                                    globalState.selected.remove(entry.id)
                                } else {
                                    globalState.selected.insert(entry.id)
                                }
                            }
                            .scaleEffect(info.scale)
                            .position(info.position)
                            .animation(.easeInOut(duration: 0.3), value: layout)
                    }
                }
            }
            .background(Color.clear)
            .onAppear {
                if let gs = try? JSONDecoder().decode(GlobalState.self, from: Data(contentsOf: configURL)) {
                    globalState = gs
                }
                layout = computeOrganicExposeLayout(entries: entries.filter { globalState.isTagged($0) })
            }.onChange(of: globalState) {
                layout = computeOrganicExposeLayout(entries: entries.filter { globalState.isTagged($0) })
                try? JSONEncoder().encode(globalState).write(to: configURL)
            }
        }
    }

    func computeOrganicExposeLayout6(entries: [WindowMetadata]) -> [String: WindowLayout] {
        guard let screen = NSScreen.main else { return [:] }

        let marginFactor: CGFloat = 0.2
        let screenFrame = screen.frame
        let usableSize = CGSize(
            width: screenFrame.width * (1 - 2 * marginFactor),
            height: screenFrame.height * (1 - 2 * marginFactor)
        )
        let layoutOrigin = CGPoint(
            x: screenFrame.minX + screenFrame.width * marginFactor,
            y: screenFrame.minY + screenFrame.height * marginFactor
        )
        let usableCenter = CGPoint(
            x: layoutOrigin.x + usableSize.width / 2,
            y: layoutOrigin.y + usableSize.height / 2
        )

        let padding: CGFloat = 8
        let spacingBase: CGFloat = 30 // smaller = tighter spiral

        let sorted = entries.sorted { $0.size.width * $0.size.height > $1.size.width * $1.size.height }

        var roughPositions: [String: CGPoint] = [:]
        var rects: [String: CGRect] = [:]

        for (index, entry) in sorted.enumerated() {
            let angle = CGFloat(index) * .pi * 0.382 // golden angle spiral
            let radius = spacingBase * sqrt(CGFloat(index))
            let pos = CGPoint(
                x: radius * cos(angle),
                y: radius * sin(angle)
            )
            roughPositions[entry.id] = pos

            let frame = CGRect(
                origin: CGPoint(x: pos.x - entry.size.width / 2, y: pos.y - entry.size.height / 2),
                size: entry.size
            ).insetBy(dx: -padding / 2, dy: -padding / 2)

            rects[entry.id] = frame
        }

        // Compute bounding rect of unscaled layout
        let allRects = rects.values
        let boundingRect = allRects.reduce(nil as CGRect?) { acc, rect in
            acc == nil ? rect : acc!.union(rect)
        } ?? .zero

        let scaleX = usableSize.width / boundingRect.width
        let scaleY = usableSize.height / boundingRect.height
        let globalScale = min(scaleX, scaleY, 1.0)

        // Center and scale positions into usable area
        var layout: [String: WindowLayout] = [:]
        for entry in sorted {
            guard let rough = roughPositions[entry.id] else { continue }

            let translated = CGPoint(
                x: (rough.x - boundingRect.midX) * globalScale + usableCenter.x,
                y: (rough.y - boundingRect.midY) * globalScale + usableCenter.y
            )

            layout[entry.id] = WindowLayout(position: translated, scale: globalScale)
        }

        return layout
    }

    func computeOrganicExposeLayout5(entries: [WindowMetadata]) -> [String: WindowLayout] {
        guard let screen = NSScreen.main else { return [:] }

        let marginFactor: CGFloat = 0.2
        let screenFrame = screen.frame
        let usableSize = CGSize(
            width: screenFrame.width * (1 - 2 * marginFactor),
            height: screenFrame.height * (1 - 2 * marginFactor)
        )
        let layoutOrigin = CGPoint(
            x: screenFrame.minX + screenFrame.width * marginFactor,
            y: screenFrame.minY + screenFrame.height * marginFactor
        )
        let usableCenter = CGPoint(
            x: layoutOrigin.x + usableSize.width / 2,
            y: layoutOrigin.y + usableSize.height / 2
        )

        let padding: CGFloat = 8
        let spacingBase: CGFloat = 30 // smaller = tighter spiral

        let sorted = entries.sorted { $0.size.width * $0.size.height > $1.size.width * $1.size.height }

        var roughPositions: [String: CGPoint] = [:]
        var rects: [String: CGRect] = [:]

        for (index, entry) in sorted.enumerated() {
            let angle = CGFloat(index) * .pi * 0.382 // golden angle spiral
            let radius = spacingBase * sqrt(CGFloat(index))
            let pos = CGPoint(
                x: radius * cos(angle),
                y: radius * sin(angle)
            )
            roughPositions[entry.id] = pos

            let frame = CGRect(
                origin: CGPoint(x: pos.x - entry.size.width / 2, y: pos.y - entry.size.height / 2),
                size: entry.size
            ).insetBy(dx: -padding / 2, dy: -padding / 2)

            rects[entry.id] = frame
        }

        // Compute bounding rect of unscaled layout
        let allRects = rects.values
        let boundingRect = allRects.reduce(nil as CGRect?) { acc, rect in
            acc == nil ? rect : acc!.union(rect)
        } ?? .zero

        let scaleX = usableSize.width / boundingRect.width
        let scaleY = usableSize.height / boundingRect.height
        let globalScale = min(scaleX, scaleY, 1.0)

        // Center and scale positions into usable area
        var layout: [String: WindowLayout] = [:]
        for entry in sorted {
            guard let rough = roughPositions[entry.id] else { continue }

            let translated = CGPoint(
                x: (rough.x - boundingRect.midX) * globalScale + usableCenter.x,
                y: (rough.y - boundingRect.midY) * globalScale + usableCenter.y
            )

            layout[entry.id] = WindowLayout(position: translated, scale: globalScale)
        }

        return layout
    }

    
    // Spiral
    func computeOrganicExposeLayout7(entries: [WindowMetadata]) -> [String: WindowLayout] {
        guard let screen = NSScreen.main else { return [:] }

        let marginFactor: CGFloat = 0.2
        let screenFrame = screen.frame
        let usableSize = CGSize(
            width: screenFrame.width * (1 - 2 * marginFactor),
            height: screenFrame.height * (1 - 2 * marginFactor)
        )
        let layoutOrigin = CGPoint(
            x: screenFrame.minX + screenFrame.width * marginFactor,
            y: screenFrame.minY + screenFrame.height * marginFactor
        )
        let usableCenter = CGPoint(x: layoutOrigin.x + usableSize.width / 2,
                                    y: layoutOrigin.y + usableSize.height / 2)

        // Step 1: Organic spiral layout (no bounds constraint yet)
        var roughPositions: [String: CGPoint] = [:]
        var rects: [String: CGRect] = [:]
        let padding: CGFloat = 16
        let sorted = entries.sorted { $0.size.width * $0.size.height > $1.size.width * $1.size.height }

        for (index, entry) in sorted.enumerated() {
            let angle = CGFloat(index) * .pi * 0.382 // golden angle-ish
            let radius = CGFloat(index) * 60
            let pos = CGPoint(
                x: radius * cos(angle),
                y: radius * sin(angle)
            )
            roughPositions[entry.id] = pos
            let frame = CGRect(origin: CGPoint(x: pos.x - entry.size.width / 2, y: pos.y - entry.size.height / 2),
                               size: entry.size).insetBy(dx: -padding/2, dy: -padding/2)
            rects[entry.id] = frame
        }

        // Step 2: Compute bounding box
        let allRects = rects.values
        let boundingRect = allRects.reduce(nil as CGRect?) { acc, rect in
            acc == nil ? rect : acc!.union(rect)
        } ?? .zero

        // Step 3: Compute scale factor to fit in usable area
        let scaleX = usableSize.width / boundingRect.width
        let scaleY = usableSize.height / boundingRect.height
        let globalScale = min(scaleX, scaleY, 1.0)

        // Step 4: Center and scale everything
        var layout: [String: WindowLayout] = [:]
        for entry in sorted {
            guard let rough = roughPositions[entry.id] else { continue }
            let translated = CGPoint(
                x: (rough.x - boundingRect.midX) * globalScale + usableCenter.x,
                y: (rough.y - boundingRect.midY) * globalScale + usableCenter.y
            )
            layout[entry.id] = WindowLayout(position: translated, scale: globalScale)
        }

        return layout
    }

    func computeOrganicExposeLayout(entries: [WindowMetadata]) -> [String: WindowLayout] {
        guard let screen = NSScreen.main else { return [:] }

        let marginFactor: CGFloat = 0.05
        let screenFrame = screen.frame
        let usableSize = CGSize(
            width: screenFrame.width * (1 - 2 * marginFactor),
            height: screenFrame.height * (1 - 2 * marginFactor) - 200
        )
        let layoutOrigin = CGPoint(
            x: screenFrame.minX + screenFrame.width * marginFactor,
            y: screenFrame.minY + screenFrame.height * marginFactor
        )
        let center = CGPoint(x: layoutOrigin.x + usableSize.width / 2,
                             y: layoutOrigin.y + usableSize.height / 2)

        let sorted = entries.sorted { $0.size.width * $0.size.height > $1.size.width * $1.size.height }
        let padding: CGFloat = 16

        var layout: [String: WindowLayout] = [:]
        var globalScale: CGFloat = 1.0

        retry: while globalScale > 0.05 {
            layout = [:]
            var placedRects: [CGRect] = []
            var failed = false

            for entry in sorted {
                let originalSize = entry.size
                let maxCellSize = CGSize(width: usableSize.width / 4, height: usableSize.height / 4)

                let scale = min(
                    maxCellSize.width / originalSize.width,
                    maxCellSize.height / originalSize.height,
                    1.0
                ) * globalScale

                let fittedSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)

                // Spiral outward from center to find non-overlapping position
                let maxRadius = hypot(usableSize.width, usableSize.height)
                let step: CGFloat = 40
                var position = center
                var found = false

                outer: for r in stride(from: 0, through: maxRadius, by: step) {
                    for angle in stride(from: 0.0, to: 2 * .pi, by: .pi / 16) {
                        let x = center.x + r * cos(angle)
                        let y = center.y + r * sin(angle)

                        let frame = CGRect(
                            x: x - fittedSize.width / 2,
                            y: y - fittedSize.height / 2,
                            width: fittedSize.width,
                            height: fittedSize.height
                        ).insetBy(dx: -padding / 2, dy: -padding / 2)

                        let overlaps = placedRects.contains { $0.intersects(frame) }

                        if !overlaps,
                           frame.minX >= layoutOrigin.x,
                           frame.minY >= layoutOrigin.y,
                           frame.maxX <= layoutOrigin.x + usableSize.width,
                           frame.maxY <= layoutOrigin.y + usableSize.height {
                            position = CGPoint(x: x, y: y)
                            placedRects.append(frame)
                            found = true
                            break outer
                        }
                    }
                }

                if !found {
                    globalScale *= 0.95
                    failed = true
                    continue retry
                }

                layout[entry.id] = WindowLayout(position: position, scale: scale)
            }

            if !failed { break }
        }

        return layout
    }

    

//    func computeOrganicExposeLayout(entries: [WindowMetadata]) -> [String: WindowLayout] {
//        guard let screen = NSScreen.main else { return [:] }
//
//        let marginFactor: CGFloat = 0.1
//        let screenFrame = screen.frame
//        let usableSize = CGSize(
//            width: screenFrame.width * (1 - 2 * marginFactor),
//            height: screenFrame.height * (1 - 2 * marginFactor)
//        )
//        let layoutOrigin = CGPoint(
//            x: screenFrame.minX + screenFrame.width * marginFactor,
//            y: screenFrame.minY + screenFrame.height * marginFactor
//        )
//        let center = CGPoint(x: layoutOrigin.x + usableSize.width / 2,
//                             y: layoutOrigin.y + usableSize.height / 2)
//
//        let padding: CGFloat = 16
//        let sorted = entries.sorted { $0.size.width * $0.size.height > $1.size.width * $1.size.height }
//
//        var layout: [String: WindowLayout] = [:]
//        var placedRects: [CGRect] = []
//
//        for entry in sorted {
//            let originalSize = entry.size
//            let maxCellSize = CGSize(width: usableSize.width / 4, height: usableSize.height / 4)
//
//            let scale = min(
//                maxCellSize.width / originalSize.width,
//                maxCellSize.height / originalSize.height,
//                1.0
//            )
//
//            let fittedSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
//
//            // Spiral outward from center to find non-overlapping position
//            let maxRadius = hypot(usableSize.width, usableSize.height)
//            let step: CGFloat = 40
//            var position = center
//
//            outer: for r in stride(from: 0, through: maxRadius, by: step) {
//                for angle in stride(from: 0.0, to: 2 * .pi, by: .pi / 16) {
//                    let x = center.x + r * cos(angle)
//                    let y = center.y + r * sin(angle)
//
//                    let frame = CGRect(
//                        x: x - fittedSize.width / 2,
//                        y: y - fittedSize.height / 2,
//                        width: fittedSize.width,
//                        height: fittedSize.height
//                    ).insetBy(dx: -padding / 2, dy: -padding / 2)
//
//                    let overlaps = placedRects.contains { $0.intersects(frame) }
//
//                    if !overlaps,
//                       frame.minX >= layoutOrigin.x,
//                       frame.minY >= layoutOrigin.y,
//                       frame.maxX <= layoutOrigin.x + usableSize.width,
//                       frame.maxY <= layoutOrigin.y + usableSize.height {
//                        position = CGPoint(x: x, y: y)
//                        placedRects.append(frame)
//                        break outer
//                    }
//                }
//            }
//
//            layout[entry.id] = WindowLayout(position: position, scale: scale)
//        }
//
//        return layout
//    }

    func computeOrganicExposeLayout2(entries: [WindowMetadata], canvasSize: CGSize) -> [String: WindowLayout] {
        let padding: CGFloat = 16
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

        // Sort largest windows first
        let sorted = entries.sorted { $0.size.width * $0.size.height > $1.size.width * $1.size.height }

        var layout: [String: WindowLayout] = [:]
        var placedRects: [CGRect] = []

        for entry in sorted {
            let originalSize = entry.size
            let maxCellSize = CGSize(width: canvasSize.width / 4, height: canvasSize.height / 4)

            let scale = min(
                maxCellSize.width / originalSize.width,
                maxCellSize.height / originalSize.height,
                1.0
            )

            let fittedSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)

            // Spiral outward from center to find non-overlapping position
            let maxRadius = max(canvasSize.width, canvasSize.height)
            let step: CGFloat = 40
            var position = center

            outer: for r in stride(from: 0, through: maxRadius, by: step) {
                for angle in stride(from: 0.0, to: 2 * .pi, by: .pi / 12) {
                    let x = center.x + r * cos(angle)
                    let y = center.y + r * sin(angle)

                    let frame = CGRect(
                        x: x - fittedSize.width / 2,
                        y: y - fittedSize.height / 2,
                        width: fittedSize.width,
                        height: fittedSize.height
                    ).insetBy(dx: -padding / 2, dy: -padding / 2)

                    let overlaps = placedRects.contains { $0.intersects(frame) }

                    if !overlaps {
                        position = CGPoint(x: x, y: y)
                        placedRects.append(frame)
                        break outer
                    }
                }
            }

            layout[entry.id] = WindowLayout(position: position, scale: scale)
        }

        return layout
    }

    func computeExposeLayout(entries: [WindowMetadata], canvasSize: CGSize) -> [String: WindowLayout] {
        let padding: CGFloat = 12

        // 1. Calculate how many rows/columns fit best
        let count = entries.count
        let aspect = canvasSize.width / canvasSize.height
        let cols = ceil(sqrt(CGFloat(count) * aspect)).rounded(.up)
        let rows = ceil(CGFloat(count) / cols).rounded(.up)

        let cellWidth = canvasSize.width / cols
        let cellHeight = canvasSize.height / rows

        var layout: [String: WindowLayout] = [:]

        for (index, entry) in entries.enumerated() {
            let col = CGFloat(index).truncatingRemainder(dividingBy: cols)
            let row = floor(CGFloat(index) / cols)

            let cellCenter = CGPoint(
                x: (col + 0.5) * cellWidth,
                y: (row + 0.5) * cellHeight
            )

            let availableSize = CGSize(width: cellWidth - padding * 2, height: cellHeight - padding * 2)
            let scale = min(availableSize.width / entry.size.width, availableSize.height / entry.size.height)

            layout[entry.id] = WindowLayout(position: cellCenter, scale: min(scale, 1.0))

        }

        return layout
    }


}

struct ContentView: View {
    var globalState: Binding<GlobalState>
    @State var tagValue: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                groupByKindAndLayout()
            }) {
                Text("Group by Kind")
            }
            Button(action: {
                groupByMonthAndLayout()
            }, label: {
                Text("Group by Month of Creation")
            })
            Button(action: {
                sortAndLayoutWindowsIntoColumns()
            }, label: {
                Text("Sort by First Letter")
            })
            Button(action: {
                globalState.selected.wrappedValue.map { s in
                    var currentTags = globalState.tags.wrappedValue[tagValue]
                    globalState.tags.wrappedValue[tagValue] = (currentTags ?? []).union([s])
                }
                globalState.selected.wrappedValue = []
            }, label: {
                Text("Tag \(globalState.selected.wrappedValue.count) items as:")
                TextField("something", text: $tagValue)
            })
            HStack {
                Group {
                    ForEach(Array(globalState.selected.wrappedValue), id: \.self) { t in
                        Text(t.description.debugDescription)
                    }
                }
                Group {
                    ForEach(Array(arrayLiteral: globalState.tags.wrappedValue), id: \.self) { t in
                        Text(t.description.debugDescription)
                    }
                }
            }
        }
        .padding()
    }
}

struct AggregateView: View {
    var entries: [WindowMetadata]

    var body: some View {
        ForEach(entries) { entry in
            TinyWindowContent(metadata: entry)
        }
    }
}


extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

