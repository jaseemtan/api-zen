//
//  NavigatorView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 10/12/25.
//

import SwiftUI
import CoreData
import AZData
import AZCommon

/// Left pane of the main window. Displays projects list for the selected workspace. Displays requests for if a project is selected.
struct NavigatorView: View {
    /// Selected workspace id.
    @Binding var workspaceId: String
    /// If a project is selected in the workspace, the window root will hold it.
    @Binding var project: EProject?

    @Environment(\.managedObjectContext) private var moc

    @State private var requests: [ERequest] = []
    @State private var pane: Pane = .project
    @State private var isPushing: Bool = true
    @State private var showAddProjectPopup = false
    @State private var newProjectName = ""
    @State private var newProjectDesc = ""
    /// For progress indicator at the add project button position that will be set on project operations like delete, copy, move etc.
    @State private var isProcessing = false
    /// Initially set to loading. Once the whole window loads, it's set to false.
    @State private var isLoading = true

    private let db: CoreDataService = CoreDataService.shared
    
    enum Pane {
        case project
        case request
    }

    var onSelectRequest: ((ERequest) -> Void)?
    
    var body: some View {
        if isLoading {
            // If there is request restored, the window will appear with projects list and make a transition to request view. This changing of the view is visible.
            // Adding this progress view hides this UX and window appears with the request list when it gets visible.
            ProgressView()
                .controlSize(.small)
                .onAppear {
                    if project != nil {
                        pane = .request
                    }
                    isLoading = false
                }
        } else {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 8)
                    .frame(height: 44)
                    .background(.ultraThinMaterial)
                    .overlay(Divider(), alignment: .bottom)
                
                ZStack {
                    if pane == .request, let sel = project {
                        RequestsListView(project: sel, requests: requests, onSelect: { req in
                            onSelectRequest?(req)
                        })
                        .transition(listTransition)
                    } else {
                        ProjectsListView(workspaceId: $workspaceId, onSelect: onProjectSelected(_:), project: $project, searchText: "", isProcessing: $isProcessing)
                            .transition(listTransition)
                    }
                }
                .animation(.default, value: pane)  // When pane changes, animate with the transition associated with the view.
                .animation(.default, value: isPushing)  // When isPushing changes, animate with the transition associated with the view.
            }
        }
    }

    private var listTransition: AnyTransition {
        if isPushing {
            // When pushing, projects is removed to the left (and requests will insert from right)
            // List moves from right to left.
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            )
        } else {
            // When popping, projects is inserted from the left.
            // List moves from left to right. Back button press animation.
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal:   .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }
    
    // MARK: - Header
    /// List header which shows Projects or project name with a back button.
    private var header: some View {
        HStack {
            // Request list
            if project != nil && pane == .request {
                Button {
                    isPushing = false
                    withAnimation {
                        pane = .project
                        project = nil  // clear selected project
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text(headerTitle)
                    }
                    .padding(.horizontal, 4)  // Gives enough room for click by expanding the button area. It's not visible unless we apply a border to it.
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Back")
//                .debugOverlay()
            } else {
                // Project list
                HStack {
                    Text(headerTitle)
                        .font(.headline)
                        .lineLimit(1)
                        .padding(.leading, 8)
                    Spacer()
                    if isProcessing {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 8)
                    } else {
                        // Add project button
                        AddButton(onTap: {
                            Log.debug("add project clicked")
                            showAddProjectPopup.toggle()
                        }, helpText: "Add Project")
                        .popover(
                            isPresented: $showAddProjectPopup,
                            attachmentAnchor: .rect(.bounds),
                            arrowEdge: .bottom  // opens popup to the bottom of the button
                        ) {
                            AddProjectView(workspaceId: workspaceId, name: $newProjectName, desc: $newProjectDesc, isProcessing: $isProcessing, onSave: { _ in
                                isProcessing = false
                            })
                            .frame(width: 400, height: 240)  // popup dimension
                        }
                    }
                }
            }
            
            Spacer()
        }
    }

    private var headerTitle: String {
        switch pane {
        case .project:
            return "Projects"
        case .request:
            if let p = project {
                return p.getName()
            }
            return "Projects"
        }
    }

    private func onProjectSelected(_ project: EProject) {
        self.project = project
        loadRequests(for: project)
        isPushing = true
        withAnimation {
            pane = .request
        }
    }
    
    // MARK: - Data loading
    private func loadRequests(for project: EProject) {
        requests = db.getRequests(projectId: project.getId(), ctx: moc)
    }
}

// MARK: - Request List View
struct RequestsListView: View {
    let project: EProject
    let requests: [ERequest]
    let onSelect: (ERequest) -> Void

    var body: some View {
        List {
            ForEach(requests, id: \.objectID) { req in
                HStack {
                    Image(systemName: "doc.text")
                    Text(req.name ?? "No name")
                    Spacer()
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(req)
                }
            }
        }
        .listStyle(SidebarListStyle())
    }
}
