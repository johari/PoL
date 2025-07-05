import SwiftUI
import MillerKitExtras
import llbuild2fx

// MARK: Helper data types

struct LayoutRegion {
    var origin: CGPoint
    var size: CGSize
}

struct WindowLayout: Equatable {
    var position: CGPoint
    var scale: CGFloat
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        if size == 0 {
            return []
        }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

extension Color {
    static func temperatureGradient(_ value: Double) -> Color {
        let clamped = min(max(value, 0.0), 1.0)
        let hue = (1.0 - clamped) * 0.65 // 0.65 = blue, 0 = red
        return Color(hue: hue, saturation: 1.0, brightness: 1.0)
    }
}


let IMAGE_FORMATS = ["png", "jpg", "jpg", "JPG", "gif", "webp", "jpeg"]
let VIDEO_FORMATS = ["mov", "mkv", "mp4", "avi", "webm"]
let TEXT_FORMATS = ["txt", "md", "html"]

enum Artifact: Identifiable, Codable, Hashable, Equatable {
    case localFile(path: String, mime: String?)
    case casBlob(id: LLBDataID, label: String)
    case feed(id: String, post: Post, timeline: Timeline)

    var id: URL {
        switch self {
        case .feed(id: let id, _, _): URL(string: "https://freefeed.net/feed/\(id)")!
        case .casBlob(id: let id, label: _): URL(string: "x-cas://\(id)")!
        case .localFile(path: let path, mime: _): URL(string: "file:///\(path)")!
        }
    }
}

struct GlobalStateData: Codable, Equatable {
    var selected: Set<Artifact> = []
    var tags: [String: Set<Artifact>] = [:]
    var tagFilter: Set<String> = []
}

class GlobalState: ObservableObject {
    @Published var data = GlobalStateData()

    func isIndirectlyTagged(artifact: Artifact, tag t: String) -> Bool {
        switch artifact {
        case .localFile(let path, let mime):
            break
        case .casBlob(let id, let label):
            return (data.tags[t] ?? []).contains(where: { artifact in
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
            return (data.tags[t] ?? []).contains(where: { artifact in
                switch artifact {
                case .localFile(let path, let mime):
                    false
                case .casBlob(let id_, let label_):
                    false
                case .feed(let id_):
                    id_ == id
                }
            })
        }
        return false
    }

    func isTagged(_ item: WindowMetadata) -> Bool {
        // If tagFilter is empty, display everything that is untagged
        if data.tagFilter.isEmpty {
            for t in data.tags.keys {
                // If the artifact exists in verbatim form, it should not be displayed
                if (data.tags[t] ?? []).contains(item.artifact) {
                    return false
                }
                if isIndirectlyTagged(artifact: item.artifact, tag: t) {
                    return false
                }
            }
            return true
        }

        // Otherwise, display things that match the tag filter
        for t in data.tagFilter {
            if (data.tags[t] ?? []).contains(item.artifact) {
                return true
            }
            if isIndirectlyTagged(artifact: item.artifact, tag: t) {
                data.tags[t]?.insert(item.artifact)
                return true
            }
        }
        return false
    }
}
