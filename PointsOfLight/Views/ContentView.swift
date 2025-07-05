//
//  ContentView.swift
//  PointsOfLight
//
//  Created by Nima Johari on 4/12/25.
//

import SwiftUI
import llbuild2fx
import MillerKitExtras

// MARK: ContentView
struct ContentView: View {
    @ObservedObject var globalState: GlobalState
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
                $globalState.data.selected.wrappedValue.map { s in
                    var currentTags = $globalState.data.tags.wrappedValue[tagValue]
                    $globalState.data.tags.wrappedValue[tagValue] = (currentTags ?? []).union([s])
                }
                $globalState.data.selected.wrappedValue = []
            }, label: {
                Text("Tag \($globalState.data.selected.wrappedValue.count) items as:")
                TextField("something", text: $tagValue)
            })
            HStack {
                Group {
                    ForEach(Array(arrayLiteral: $globalState.data.selected.wrappedValue), id: \.self) { t in
                        Text(t.description.debugDescription)
                    }
                }
                Group {
                    ForEach(Array(arrayLiteral: $globalState.data.tags.wrappedValue), id: \.self) { t in
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
    var engine: FXBuildEngine
    var ctx: Context

    var body: some View {
        ForEach(entries) { entry in
            TinyWindowContent(metadata: entry, engine: engine, ctx: ctx)
        }
    }
}


