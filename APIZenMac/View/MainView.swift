//
//  MainView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 05/12/25.
//

import SwiftUI
import CoreData
import AZData

struct MainView: View {
    @Binding var selectedWorkspaceId: String
    @Binding var coreDataContainer: CoreDataContainer
    @Environment(\.managedObjectContext) private var ctx
    @State private var showNavigator = true  // Left pane
    @State private var showInspector = true  // Right pane
    @State private var showRequestComposer = true  // The center pane
    let windowIndex: Int
    private let db = CoreDataService.shared

    var body: some View {
        HSplitView {
            // Left pane
            if showNavigator {
                NavigatorView()
                    .frame(minWidth: 180, idealWidth: 220, maxWidth: 400)
            }
            
            // Center pane
            VSplitView {
                CenterTopPane()
                    .frame(minHeight: 150)

                CenterBottomPane()
                    .frame(minHeight: 150)
            }
            .frame(minWidth: 400, maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)   // middle gets priority

            // Right pane
            if showInspector {
                InspectorView()
                    .frame(minWidth: 180, idealWidth: 220, maxWidth: 400)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    withAnimation {
                        showNavigator.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.leading")
                }
                .help("Toggle Left Pane")

                Button {
                    withAnimation {
                        showInspector.toggle()
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

struct NavigatorView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Left Pane")
                .font(.headline)
                .padding(6)

            Divider()

            List(0..<10, id: \.self) { i in
                Text("Item \(i)")
            }
            .scrollContentBackground(.hidden)  // List background shows in a dark colour and the window has a different colour make it appear in a box. Removing the background make it cohesive with the window. Like the list starts from the edge.
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
            // Main content area
            VStack(alignment: .leading, spacing: 4) {
                Text("Center Bottom")
                    .font(.headline)

                Divider()

                Text("Logs / console / secondary view")
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity,
                           alignment: .topLeading)
            }
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // Bottom bar
            Divider()

            HStack {
                Spacer()

                Button {
                    print("Default Workspace tapped")
                } label: {
                    Text("Default Workspace")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.blue)
                        .underline(false)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InspectorView: View {
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
