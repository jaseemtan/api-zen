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
    let workspaceId: String
    private let db: CoreDataService = CoreDataService.shared

    @Environment(\.managedObjectContext) private var moc

    @State private var requests: [ERequest] = []

    @State private var pane: Pane = .project
    @State private var selectedProject: EProject? = nil
    @State private var isPushing: Bool = true
    @State private var showAddProjectPopup = false
    
    @State private var newProjectName = ""
    @State private var newProjectDesc = ""

    enum Pane {
        case project
        case request
    }

    var onSelectRequest: ((ERequest) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 8)
                .frame(height: 44)
                .background(.ultraThinMaterial)
                .overlay(Divider(), alignment: .bottom)

            ZStack {
                if pane == .project {
                    ProjectsListView(workspaceId: workspaceId, onSelect: onProjectSelected(_:), selectedProject: $selectedProject, searchText: "")
                    .transition(listTransition)
                }

                if pane == .request, let sel = selectedProject {
                    RequestsListView(project: sel, requests: requests, onSelect: { req in
                        onSelectRequest?(req)
                    })
                    .transition(listTransition)
                }
            }
            .animation(.default, value: pane)  // When pane changes, animate with the transition associated with the view.
            .animation(.default, value: isPushing)  // When isPushing changes, animate with the transition associated with the view.
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
            if pane == .request {
                Button {
                    isPushing = false
                    withAnimation {
                        pane = .project
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
                HStack {
                    Text(headerTitle)
                        .font(.headline)
                        .lineLimit(1)
                        .padding(.leading, 4)
                    Spacer()
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
                        AddProjectView(workspaceId: workspaceId, name: $newProjectName, desc: $newProjectDesc)
                            .frame(width: 400, height: 240)  // popup dimension
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
            if let p = selectedProject {
                return p.getName()
            }
            return "Requests"
        }
    }

    private func onProjectSelected(_ project: EProject) {
        selectedProject = project
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
