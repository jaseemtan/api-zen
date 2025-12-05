//
//  ContentView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 05/12/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showLeft  = true
    @State private var showRight = true

    var body: some View {
        HSplitView {
            // Left pane
            if showLeft {
                LeftPane()
                    .frame(minWidth: 180, idealWidth: 220, maxWidth: 350)
            }

            // Center view
            VSplitView {
                CenterTopPane()
                    .frame(minHeight: 150)

                CenterBottomPane()
                    .frame(minHeight: 150)
            }
            .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)   // middle gets priority

            // Right pane
            if showRight {
                RightPane()
                    .frame(minWidth: 200, idealWidth: 260, maxWidth: 380)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    withAnimation {
                        showLeft.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.leading")
                }
                .help("Toggle Left Pane")

                Button {
                    withAnimation {
                        showRight.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.trailing")
                }
                .help("Toggle Right Pane")
            }
        }
    }
}

// MARK: - Panes

struct LeftPane: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Left Pane")
                .font(.headline)
                .padding(6)

            Divider()

            List(0..<10, id: \.self) { i in
                Text("Item \(i)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct CenterTopPane: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Center Top")
                .font(.headline)
                .padding(6)

            Divider()

            Text("Main editor / content")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CenterBottomPane: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Center Bottom")
                .font(.headline)
                .padding(6)

            Divider()

            Text("Logs / console / secondary view")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RightPane: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Right Pane")
                .font(.headline)
                .padding(6)

            Divider()

            Form {
                Toggle("Option 1", isOn: .constant(true))
                Toggle("Option 2", isOn: .constant(false))
            }
            .padding(6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
