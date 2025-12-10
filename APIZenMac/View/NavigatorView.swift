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
    let workspaceId: String
    private let db: CoreDataService = CoreDataService.shared

    @Environment(\.managedObjectContext) private var moc

    @State private var projects: [EProject] = []
    @State private var requests: [ERequest] = []

    @State private var pane: Pane = .project
    @State private var selectedProject: EProject? = nil
    @State private var isPushing: Bool = true

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
                    ProjectsListView(projects: projects, onSelect: { proj in
                        // prepare data, then push
                        selectedProject = proj
                        loadRequests(for: proj)
                        isPushing = true
                        withAnimation {
                            pane = .request
                        }
                    }, selectedProject: $selectedProject)
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
        .onAppear {
            loadProjects()
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
//                .overlay(
//                    RoundedRectangle(cornerRadius: 4)
//                        .stroke(Color.red.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
//                )
            } else {
                Text(headerTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .padding(.leading, 4)
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

    // MARK: - Data loading
    private func loadProjects() {  // TODO: use FRC. This can be moved to ProjectsListView with workspace id.
        projects = self.db.getProjects(wsId: workspaceId, ctx: moc)
    }

    private func loadRequests(for project: EProject) {
        requests = db.getRequests(projectId: project.getId(), ctx: moc)
    }
}


// MARK: - Project List View
struct ProjectsListView: View {
    let projects: [EProject]
    let onSelect: (EProject) -> Void
    @Binding var selectedProject: EProject?

    var body: some View {
        VStack {
            // We can't use selection based list like in workspace listing because we don't want project list to get selection highlight once selected before and navigated back.
            // For workspace we are displaying a checkmark. So this is fine. Here we don't use that pattern.
            List {
                ForEach(projects, id: \.objectID) { project in
                    Button {
                        onSelect(project)
                    } label: {
                        NameDescView(imageName: "project", name: project.getName(), desc: project.desc)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(SidebarListStyle())  // Sidebar list style does not show separator. This could be a distinction between projects and requests.
        }
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
