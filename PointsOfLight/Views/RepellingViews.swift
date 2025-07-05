import SwiftUI
import llbuild2fx

// MARK: RepellingViews
struct RepellingViews: View {
    @State private var entries: [WindowMetadata]
    @State private var layout: [Artifact: WindowLayout] = [:]
    @ObservedObject private var globalState: GlobalState
    private var engine: FXBuildEngine
    private var ctx: Context

    public init(entries: [WindowMetadata], globalState: GlobalState, engine: FXBuildEngine, ctx: Context) {
        self._entries = State(initialValue: entries)
        self.globalState = globalState
        self.ctx = ctx
        self.engine = engine
    }

    var rows: [[String]] {
        return Array(
            $globalState.data.tags.wrappedValue.keys.sorted()
        ).chunked(into: ($globalState.data.wrappedValue.tags.keys.count) / 4)
    }

    var body: some View {
        VStack {
            Color.clear.frame(height: 40) // adds exact 40pt space
            VStack {
                ForEach(rows, id: \.self) { row in
                    HStack {
                        ForEach(row, id: \.self) { tag in
                            let tagCount = globalState.data.tags[tag]?.count ?? 0

                            Button("\(tag) \(tagCount)") {
                                if globalState.data.tagFilter.contains(tag) {
                                    globalState.data.tagFilter.remove(tag)
                                } else {
                                    globalState.data.tagFilter.insert(tag)
                                }
                                globalState.data.selected = []
                            }
                            .border(globalState.data.tagFilter.contains(tag) ? .purple : .clear, width: 5)
                            .tint(Color.temperatureGradient(Double(tagCount)/20.0))
                        }
                    }
                }
            }.task {
            }
            body_
        }.onAppear {
            if let gs = try? JSONDecoder().decode(GlobalStateData.self, from: Data(contentsOf: configURL)) {
                globalState.data = gs
                print("[tags]", globalState.data.tags.keys)
            } else {
                print("Failed to parse global state")
            }
            layout = computeOrganicExposeLayout(entries: entries.filter { globalState.isTagged($0) })
        }.onChange(of: globalState.data) {
            layout = computeOrganicExposeLayout(entries: entries.filter { globalState.isTagged($0) })
            try? JSONEncoder().encode(globalState.data).write(to: configURL)
        }
    }

    let configURL = URL(filePath: NSString("~/.pol.json").expandingTildeInPath)

    var body_: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(entries, id: \.self) { entry in
                    if let info = layout[entry.id] {
                        TinyWindowContent(metadata: entry, engine: engine, ctx: ctx)
                            .border(
                                globalState.data.selected.contains(entry.id) ? .black : Color.blue,
                                width: globalState.data.selected.contains(entry.id) ? 10 : 2
                            )
                            .frame(width: entry.size.width, height: entry.size.height)
                            .onTapGesture {
                                if globalState.data.selected.contains(entry.id) {
                                    globalState.data.selected.remove(entry.id)
                                } else {
                                    globalState.data.selected.insert(entry.id)
                                }
                            }
                            .scaleEffect(info.scale)
                            .position(info.position)
                            .animation(.easeInOut(duration: 0.3), value: layout)
                    }
                }
            }
            .background(Color.clear)
        }
    }

    // MARK: computeOrganicExposeLayout6
    func computeOrganicExposeLayout6(entries: [WindowMetadata]) -> [Artifact: WindowLayout] {
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

        var roughPositions: [Artifact: CGPoint] = [:]
        var rects: [Artifact: CGRect] = [:]

        for (index, entry) in sorted.enumerated() {
            let angle = CGFloat(index) * .pi * 0.382 // golden angle spiral
            let radius = spacingBase * sqrt(CGFloat(index))
            let pos = CGPoint(
                x: radius * cos(angle),
                y: radius * sin(angle)
            )
            roughPositions[entry.artifact] = pos

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
        var layout: [Artifact: WindowLayout] = [:]
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

    // MARK: computeOrganicExposeLayout5
    func computeOrganicExposeLayout5(entries: [WindowMetadata]) -> [Artifact: WindowLayout] {
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

        var roughPositions: [Artifact: CGPoint] = [:]
        var rects: [Artifact: CGRect] = [:]

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
        var layout: [Artifact: WindowLayout] = [:]
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

    
    // MARK: Spiral
    func computeOrganicExposeLayout7(entries: [WindowMetadata]) -> [Artifact: WindowLayout] {
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
        var roughPositions: [Artifact: CGPoint] = [:]
        var rects: [Artifact: CGRect] = [:]
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
        var layout: [Artifact: WindowLayout] = [:]
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

    // MARK: computeOrganicExposeLayout
    func computeOrganicExposeLayout(entries: [WindowMetadata]) -> [Artifact: WindowLayout] {
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

        var layout: [Artifact: WindowLayout] = [:]
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

    

    // MARK: commented out old code
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

    // MARK: computeOrganicExposeLayout2
    func computeOrganicExposeLayout2(entries: [WindowMetadata], canvasSize: CGSize) -> [Artifact: WindowLayout] {
        let padding: CGFloat = 16
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)

        // Sort largest windows first
        let sorted = entries.sorted { $0.size.width * $0.size.height > $1.size.width * $1.size.height }

        var layout: [Artifact: WindowLayout] = [:]
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

    // MARK: computeExposeLayout
    func computeExposeLayout(entries: [WindowMetadata], canvasSize: CGSize) -> [Artifact: WindowLayout] {
        let padding: CGFloat = 12

        // 1. Calculate how many rows/columns fit best
        let count = entries.count
        let aspect = canvasSize.width / canvasSize.height
        let cols = ceil(sqrt(CGFloat(count) * aspect)).rounded(.up)
        let rows = ceil(CGFloat(count) / cols).rounded(.up)

        let cellWidth = canvasSize.width / cols
        let cellHeight = canvasSize.height / rows

        var layout: [Artifact: WindowLayout] = [:]

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
