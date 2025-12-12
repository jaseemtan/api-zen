//
//  ProjectsListView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 11/12/25.
//

import SwiftUI
import CoreData
import AZData
import AZCommon
 
/// Projects list view that preserves scroll offset when navigating back from requests view. The offset works by default because this view is inside an AppKit split view controller.
struct ProjectsListView: View {
    /// Selected workspace id
    let workspaceId: String
    /// We need to invoke the parent view function so that the navigator can navigate to request view on selecting a project.
    let onSelect: (EProject) -> Void
    @Binding var selectedProject: EProject?
    @Binding var isProcessing: Bool
    
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool? = false  // Is search button clicked and search field display? If so we are hiding other items on the bottom bar, except sort.
    @State private var projects: [EProject] = []
    @State private var dataManager: CoreDataManager<EProject>?
    @State private var sortField: SortField = .manual
    @State private var sortAscending: Bool = true
    @State private var showEditProjectPopup: Bool = false
    @State private var editProject: EProject?  // Holds the project that is under editing.
    @State private var editProjectName: String = ""
    @State private var editProjectDesc: String = ""
    @State private var projectPendingDelete: EProject?  // Holds the project that is user is deleting
    @State private var showDeleteConfirmation = false
    
    @Environment(\.managedObjectContext) private var moc
    
    private let projectsCacheName: String = "projects-cache"
    private let toolbarHeight: CGFloat = 32.0
    private let db = CoreDataService.shared
    private let theme = ThemeManager.shared
    
    /// This is projects list state which is one per workspace. So it is identified using workspace id.
    struct ProjectsListState: Identifiable, Codable {
        var workspaceId: String = ""
        var sortField: SortField = .manual
        var sortAscending: Bool = true
        
        var id: String { workspaceId }
        
        func encode() -> Data? {
            return try? JSONEncoder().encode(self)
        }
        
        func decode(_ data: Data?) -> ProjectsListState? {
            guard let data = data else { return nil }
            return try? JSONDecoder().decode(ProjectsListState.self, from: data)
        }
        
        /// Saves the state to user defaults.
        func saveProjectPopupState() {
            if let data = self.encode() {
                AZUtils.shared.setValue(key: self.getUserDefaultsKey(), value: data)
                Log.debug("saved proj state: sortField: \(sortField) - sortAsc: \(sortAscending) - wsId: \(workspaceId)")
            }
        }
        
        /// Restore the state from user defaults. Updates the current object. This should be invoked after setting the workspaceId.
        mutating func restoreProjectsListState() {
            if workspaceId.isEmpty { return }
            if let data = AZUtils.shared.getValue(self.getUserDefaultsKey()) as? Data {
                if let state = self.decode(data) {
                    Log.debug("restored proj state: sortField: \(sortField) - sortAsc: \(sortAscending) - wsId: \(workspaceId)")
                    self.sortField = state.sortField
                    self.sortAscending = state.sortAscending
                }
            }
        }
        
        /// Workspace delete is done in the list view. So keeping this static.
        static func deleteProjectsListState(_ workspaceId: String) {
            AZUtils.shared.removeValue("\(AZMConst.projectsListStateKey)-\(workspaceId)")
        }
        
        private func getUserDefaultsKey() -> String {
            return "\(AZMConst.projectsListStateKey)-\(self.workspaceId)"
        }
    }
    
    @State private var state: ProjectsListState = ProjectsListState()
    
    // Explicit init with only the required params is required because we have many properties and default init becomes internal.
    init(workspaceId: String, onSelect: @escaping (EProject) -> Void, selectedProject: Binding<EProject?>, searchText: String, isProcessing: Binding<Bool>) {
        Log.debug("proj list view: ws id: \(workspaceId)")
        self.workspaceId = workspaceId
        self.onSelect = onSelect
        self._selectedProject = selectedProject
        self.searchText = searchText
        self._isProcessing = isProcessing
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Safe top padding that doesn't affect scroll offset calculation.
                    // NB: The manual calc of scroll view offset is removed now. But keeping this implementation as is since it works.
                    Color.clear.frame(height: 12)
                    // NOTE: No top padding here — avoid adding .padding() that affects top
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(projects) { project in
                            // List style does not show separator. This could be a distinction between projects and requests.
                            Button {
                                // allow preference system to settle then navigate
                                DispatchQueue.main.async {
                                    onSelect(project)
                                }
                            } label: {
                                NameDescView(imageName: "project", name: project.getName(), desc: project.desc)
                                    .padding(.vertical, 6)
                                    .padding(.leading, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .id(project.objectID)
                            .contextMenu {
                                Button("Edit") {
                                    Log.debug("edit on proj: \(project.getName())")
                                    editProject = project
                                    editProjectName = project.getName()
                                    editProjectDesc = project.desc ?? ""
                                    showEditProjectPopup.toggle()
                                }
                                
                                Button("Delete", role: .destructive) {
                                    Log.debug("delete on proj: \(project.getName())")
                                    projectPendingDelete = project
                                    showDeleteConfirmation = true  // Display delete confirmation dialog
                                }
                            }
                        }
                    }
                    // horizontal padding only if you want — no top padding
                    .padding(.horizontal, 8)
                    // Safe bottom padding that doesn't affect scroll offset calculation
                    Color.clear.frame(height: 12 + toolbarHeight)  // Bottom list padding + toolbar height offset.
                }
            }
            .onAppear {
                self.initDataManager()
            }
            .onChange(of: workspaceId) { oldId, newId in
                if oldId != newId {
                    Log.debug("proj list: workspace id changed: \(newId)")
                    self.updateState(newId)  // clear project list state and restore state if present for the given workspace.
                    self.initDataManager()  // reinit data maanger with new predicate for workspaceId to update project listing
                }
            }
            .onChange(of: sortField, { _, _ in
                self.initDataManager()  // reinit data manager with new sort descriptor to update the list ordering
            })
            .onChange(of: sortAscending, { _, _ in
                self.initDataManager()  // reinit data manager with new sort descriptor to update the list ordering
            })
            .onChange(of: searchText, { _, _ in
                self.initDataManager()
            })
            // Fixed bottom toolbar overlay
            bottomToolbarView
        }
        .onAppear {
            Log.debug("proj list onAppear: wsId: \(workspaceId)")
            state.workspaceId = workspaceId
            state.restoreProjectsListState()
        }
        .task {
            sortField = state.sortField
            sortAscending = state.sortAscending
        }
        .popover(item: $editProject, attachmentAnchor: .rect(.bounds), arrowEdge: .trailing) { proj in
            AddProjectView(workspaceId: workspaceId, name: $editProjectName, desc: $editProjectDesc, isEdit: true, project: proj) { _ in
                Log.debug("on proj save")
                self.editProject = nil
                self.initDataManager()
            }
            .frame(width: 400, height: 240)
        }
        .confirmationDialog("Are you sure you want to delete this project?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let project = projectPendingDelete {
                    isProcessing = true
                    self.db.deleteEntity(project, ctx: moc)
                    self.db.saveMainContext { _ in
                        isProcessing = false
                    }
                    // TODO: delete any request list preferences
                }
                projectPendingDelete = nil
            }

            Button("Cancel", role: .cancel) {
                projectPendingDelete = nil
                isProcessing = false
            }
        }
    }
    
    var bottomToolbarView: some View {
        VStack(spacing: 0) {
            Spacer() // push toolbar to bottom
            Divider()
            HStack {
                SortMenu(
                    sortField: $sortField,
                    sortAscending: $sortAscending,
                    onSortFieldChanged: { field in
                        sortField = field
                        state.sortField = sortField
                        state.saveProjectPopupState()
                    },
                    onSortAscendingChanged: { flag in
                        sortAscending = flag
                        state.sortAscending = sortAscending
                        state.saveProjectPopupState()
                    },
                    helpText: "Sort Projects"
                )
                .padding(.leading, 8)

                Spacer()

                // Search button on right. Hides other toolbar items when expanded.
                ExpandingSearchField(isActive: $isSearchActive) { query in
                    let text = query.trim()
                    Log.debug("Search for: \(query)")
                    searchText = text
                }
                .padding(.horizontal, 8)
            }
            .frame(height: toolbarHeight)
            .background(.ultraThinMaterial) // subtle translucent background (iOS/macOS)
            .ignoresSafeArea(edges: .bottom) // let the background extend into safe area if needed
        }
        // ensure the overlay doesn't intercept touch events except the toolbar
        .allowsHitTesting(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    
    /// The query is cached. So multiple searches of the same parameters would not be that costly.
    func initDataManager() {
        Log.debug("proj list view: init data manager - \(self.db.getContainer(moc))" )
        let fr = EProject.fetchRequest()
        fr.sortDescriptors = self.getSortDescriptors()
        if searchText.isNotEmpty {
            fr.predicate = NSPredicate(format: "(name CONTAINS[cd] %@) OR (desc CONTAINS[cd] %@)", searchText, searchText)  // c: case-insensitive; d: diacritic-insensitive
        } else {
            fr.predicate = NSPredicate(format: "workspace.id == %@ AND name != %@ AND markForDelete == %hdd", workspaceId, "", false)
        }
        fr.fetchBatchSize = 50
        if let dm = self.dataManager { dm.clearCache() }  // clear previous cache if already initialized before.
        dataManager = CoreDataManager(fetchRequest: fr, ctx: moc, cacheName: self.projectsCacheName, onChange: { projects in
            withAnimation {
                self.projects = []  // force reload. For some reason, editing local project is not reloading the list. Edit cloud project is reflecting properly.
                self.projects = projects
            }
        })
    }
    
    /// Update user preference state
    func updateState(_ wsId: String) {
        state = ProjectsListState(workspaceId: wsId)
        state.restoreProjectsListState()
        sortField = state.sortField
        sortAscending = state.sortAscending
    }
    
    private func getSortDescriptors() -> [NSSortDescriptor] {
        let sortDescriptor: NSSortDescriptor
        switch sortField {
        case .manual:
            sortDescriptor = NSSortDescriptor(keyPath: \EProject.order, ascending: sortAscending)
        case .name:
            sortDescriptor = NSSortDescriptor(keyPath: \EProject.name, ascending: sortAscending)
        case .created:
            sortDescriptor = NSSortDescriptor(keyPath: \EProject.created, ascending: sortAscending)
        }
        return [sortDescriptor]
    }
}
