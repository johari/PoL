import SwiftUI
import llbuild2fx
import TSFUtility
import TSFCASFileTree
import TSCBasic
import MillerKitExtras

struct AsyncImage2<V1: View, V2: View>: View {
    let url: URL
    let placeholder: () -> V1
    let finishedView: (NSImage) -> V2

    @State var imageContents: NSImage? = nil
    let ctx: Context
    let engine: FXBuildEngine

    init(
        engine: FXBuildEngine,
        ctx: Context,
        url: URL,
        _ finishedView: @escaping (NSImage) -> V2,
        placeholder: @escaping () -> V1
    ) {
        self.url = url
        self.placeholder = placeholder
        self.ctx = ctx
        self.engine = engine
        self.finishedView = finishedView
    }

    var body: some View {
        Group {
            if let imageContents {
                finishedView(imageContents)
            } else {
                placeholder()
            }
        }.task {
            if let res = try? await engine.build(key: FetchHTTP(url: url), ctx).get() {
                imageContents = NSImage(data: res.data)
            } else {
                print("Unable to fetch HTTP")
            }
        }
    }
}

struct TinyWindowContent: View {
    let metadata: WindowMetadata
    let ctx: Context
    let engine: FXBuildEngine

    @State var fileContents: LLBByteBuffer? = nil
    @State var fileLabel: String? = nil

    init(
        metadata: WindowMetadata,
        engine: FXBuildEngine,
        ctx: Context,
        fileContents: LLBByteBuffer? = nil
    ) {
        self.metadata = metadata
        self.ctx = ctx
        self.fileContents = fileContents
        self.engine = engine
    }

    func img(_ attachment: Attachment) -> some View {
        AsyncImage2(engine: engine, ctx: ctx, url: URL(string: attachment.url)!, { (image: NSImage) in
            return Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
        }, placeholder: {
            return Text("Loading image from FreeFeed")
        })
    }

    var body: some View {
        Group {
            switch self.metadata.artifact {
            case .feed(id: let id, post: let post, timeline: let timeline):
                VStack {
                    Text(metadata.title)
                        .font(.caption2)
                        .background(metadata.color.opacity(0.9))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 0.5))
                    HStack {
                        let ats = post.attachments ?? []
                        ForEach(ats, id: \.self) { attachment in
                            if let attachment = timeline.findAttachment(id: attachment) {
                                Group {
                                    img(attachment)
                                }
                            } else {
                                Group {
                                    Text("Attachment \(id) not found")
                                }
                            }
                        }
                    }
                }.frame(width: metadata.width, height: metadata.height)
            case .casBlob(id: let id, label: let label):
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
            case .localFile(path: _, mime: _):
                Text(".localFile not imple,implemented")
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
                case .feed(let id, post: let post, timeline: let timeline):
                    self.fileContents = LLBByteBuffer(string: "")
                    self.fileLabel = "ff"
                }
            }
        }
    }
}
