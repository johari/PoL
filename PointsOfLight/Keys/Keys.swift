import llbuild2fx
import TSFCASFileTree
import TSCBasic
import llbuild2
import Foundation
import AppKit
import MillerKitExtras

struct ImageDimensionResult: Codable, FXValue {
    let size: CGSize?
}

struct ImageDimension: AsyncFXKey {
    typealias ValueType = ImageDimensionResult

    let imageID: LLBDataID

    func computeValue(_ fi: FXFunctionInterface<ImageDimension>, _ ctx: Context) async throws -> ValueType {
        let image = try await ctx.db.get(imageID, ctx).get()!.data.readableBytesView
        guard let image = NSImage(data: Data(image)) else {
            print("Unable to find sizes for \(imageID)")
            return ImageDimensionResult(size: nil)
        }
        return ImageDimensionResult(size: image.size)
    }
}

struct FetchTimelineResult: Codable, FXValue {
    let timelines: [Timeline]
}

struct FetchTimeline: AsyncFXKey {
    typealias ValueType = FetchTimelineResult

    let version: Int = 3

    let user: String

    func computeValue(_ fi: FXFunctionInterface<FetchTimeline>, _ ctx: Context) async throws -> ValueType {
        
        let api = FreeFeedAPI(ctx: ctx)
        // let nums = [0, 30, 60, 90, 120, 150, 180, 200]
        let nums = [0]
        let timelines = try await nums.parallelMap {
            try await api.fetchUserTimeline(username: user, offset: $0)
        }

        return FetchTimelineResult(timelines: timelines)
    }
}
