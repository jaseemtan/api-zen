//
//  MainView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 05/12/25.
//

import SwiftUI
import CoreData
import AZData
import AZCommon

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
                .font(.body)
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
                .font(.body)
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
    @State private var showWorkspacePopup = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content area
            VStack(alignment: .leading, spacing: 4) {
                Text("Center Bottom")
                    .font(.body)

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
                    showWorkspacePopup.toggle()
                } label: {
                    Text("Default Workspace")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.blue)
                        .underline(false)
                }
                .buttonStyle(.plain)
                .popover(
                    isPresented: $showWorkspacePopup,
                    attachmentAnchor: .rect(.bounds),
                    arrowEdge: .bottom  // button at bottom of window and popover above it
                ) {
                    WorkspacesPopupView()
                        .frame(width: 320, height: 400)
                }
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
                .font(.body)
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

// Workspace list view

struct WorkspacesPopupView: View {
    @State private var showingAddForm = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    ExpandingSearchField(text: $searchText) { query in
                        // TODO: search impl
                        Log.debug("Search for: \(query)")
                    }
                    Spacer()
                }
                .padding(.bottom, 4)
                
                Picker("", selection: .constant(0)) {
                    Text("Local").tag(0)
                    Text("iCloud").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
                
                List(0..<10, id: \.self) { i in
                    Text("Workspace long workspace name here \(i)")
                        .padding(.vertical, 4)
                }
                

                HStack {
                    Spacer()
                    
                    Button {
                        showingAddForm = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .regular))
                            .imageScale(.medium)
                    }
                    .buttonStyle(.plain)
                    .help("Add Workspace")
                    .padding(.top, 4)
                }
            }
            .padding()
            .navigationDestination(isPresented: $showingAddForm) {
                AddWorkspaceFormView()
            }
        }
        .frame(width: 300, height: 400)
    }
}

// TODO: fix UI
struct AddWorkspaceFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            TextField("Name", text: .constant(""))
            Button("Save") { dismiss() }
        }
        .padding()
        .navigationTitle("New Workspace")
    }
}
