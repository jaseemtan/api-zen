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
 
/// Projects list view.
struct ProjectsListView: View {
    /// Selected workspace id
    @Binding var workspaceId: String
    /// We need to invoke the parent view function so that the navigator can navigate to request view on selecting a project.
    let onSelect: (EProject) -> Void
    @Binding var project: EProject?
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
    @State private var selectedProjectIds: Set<String> = []
    
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.colorScheme) private var colorScheme
    
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
        func saveProjectsListState() {
            if let data = self.encode() {
                AZUtils.shared.setValue(key: self.getUserDefaultsKey(), value: data)
                Log.debug("projlist: saved proj state: sortField: \(sortField) - sortAsc: \(sortAscending) - wsId: \(workspaceId)")
            }
        }
        
        /// Restore the state from user defaults. Updates the current object. This should be invoked after setting the workspaceId.
        mutating func restoreProjectsListState() {
            if workspaceId.isEmpty { return }
            if let data = AZUtils.shared.getValue(self.getUserDefaultsKey()) as? Data {
                if let state = self.decode(data) {
                    Log.debug("projlist: restored proj state: sortField: \(sortField) - sortAsc: \(sortAscending) - wsId: \(workspaceId)")
                    self.sortField = state.sortField
                    self.sortAscending = state.sortAscending
                }
            }
        }
        
        /// Projects list state is per workspace. So it gets deleted when workspace is deleted. And that happens in workspaces list view. So this is static.
        static func deleteProjectsListState(_ workspaceId: String) {
            AZUtils.shared.removeValue("\(AZMConst.projectsListStateKey)-\(workspaceId)")
        }
        
        private func getUserDefaultsKey() -> String {
            return "\(AZMConst.projectsListStateKey)-\(self.workspaceId)"
        }
    }
    
    @State private var state: ProjectsListState = ProjectsListState()
    
    // Explicit init with only the required params because we have many properties and default init becomes internal.
    init(workspaceId: Binding<String>, onSelect: @escaping (EProject) -> Void, project: Binding<EProject?>, searchText: String, isProcessing: Binding<Bool>) {
        Log.debug("projlist: view init: ws id: \(workspaceId.wrappedValue)")
        self._workspaceId = workspaceId
        self.onSelect = onSelect
        self._project = project  // selected project
        self.searchText = searchText
        self._isProcessing = isProcessing
    }

    var body: some View {
        Group {
            List(selection: $selectedProjectIds) {  // The scroll offset is automatically preserved when navigated back.
                ForEach(projects) { proj in
                    NameDescView(imageName: "project", name: "\(proj.getName()) - \(proj.order!)", desc: proj.desc)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .tag(proj.getId())
                        .contextMenu {
                            if selectedProjectIds.count <= 1 {
                                Button("Edit") {
                                    Log.debug("projlist: edit on proj: \(proj.getName())")
                                    editProject = proj
                                    editProjectName = proj.getName()
                                    editProjectDesc = proj.desc ?? ""
                                    showEditProjectPopup.toggle()
                                }
                            }
                            
                            Button("Delete", role: .destructive) {
                                Log.debug("projlist: delete on proj: \(proj.getName()) - \(proj.getId())")
                                Log.debug("projlist: selected project ids: \(selectedProjectIds)")
                                projectPendingDelete = proj
                                showDeleteConfirmation = true  // Display delete confirmation dialog
                            }
                        }
                }
                .onMove { indexSet, order in
                    Log.debug("projlist: on move")
                    guard sortField == .manual && sortAscending else { return }
                    reorderProject(from: indexSet, to: order)
                }
            }
            .padding(.bottom, toolbarHeight)
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
            
            bottomToolbarView
        }
        .onAppear {
            Log.debug("projlist: onAppear: wsId: \(workspaceId)")
            selectedProjectIds = []
            state.workspaceId = workspaceId
            state.restoreProjectsListState()
            self.initDataManager()
        }
        .task {
            sortField = state.sortField
            sortAscending = state.sortAscending
        }
        .onChange(of: selectedProjectIds) { _, projIds in
            Log.debug("projlist: project selection changed to: \(projIds)")
            if UI.isCommandClicked() {
                Log.debug("projlist: command clicked. do nothing.")
            } else {
                // Navigate to requests list only if one project is selected.
                if projIds.count == 1 {
                    if let projId = projIds.first, let proj = self.projects.first(where: { project in
                        project.getId() == projId
                    }) {
                        onSelect(proj)
                        Task { @MainActor in
                            await Task.yield()   // wait one SwiftUI commit
                            withTransaction(Transaction(animation: nil)) {
                                selectedProjectIds.removeAll()
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: workspaceId) { oldId, newId in
            if oldId != newId {
                Log.debug("projlist: workspace id changed: \(newId)")
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
        .popover(item: $editProject, attachmentAnchor: .rect(.bounds), arrowEdge: .trailing) { proj in
            // Edit project
            AddProjectView(workspaceId: workspaceId, name: $editProjectName, desc: $editProjectDesc, isEdit: true, isProcessing: $isProcessing, project: proj) { _ in
                Log.debug("projlist: on proj edit save")
                self.editProject = nil
                self.initDataManager()
                isProcessing = false
            }
            .frame(width: 400, height: 240)
        }
        .confirmationDialog(isThereMultipleProjectsToDelete() ? "Are you sure you want to delete the selected projects?" : "Are you sure you want to delete this project?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteProjects()
            }

            Button("Cancel", role: .cancel) {
                projectPendingDelete = nil
                isProcessing = false
            }
        }
        .onDisappear {
            Log.debug("projlist: on disappear")
        }
    }
    
    var bottomToolbarView: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                SortMenu(
                    sortField: $sortField,
                    sortAscending: $sortAscending,
                    onSortFieldChanged: { field in
                        sortField = field
                        state.sortField = sortField
                        state.saveProjectsListState()
                    },
                    onSortAscendingChanged: { flag in
                        sortAscending = flag
                        state.sortAscending = sortAscending
                        state.saveProjectsListState()
                    },
                    helpText: "Sort Projects"
                )
                .padding(.leading, 12)

                if !(isSearchActive ?? false) {
                    AddButton(onTap: {}, helpText: "Add Group")
                }
                
                Spacer()

                // Search button on right. Hides other toolbar items when expanded.
                ExpandingSearchField(isActive: $isSearchActive) { query in
                    let text = query.trim()
                    Log.debug("projlist: search for: \(query)")
                    searchText = text
                }
                .padding(.leading, 4)
                .padding(.trailing, 12)
            }
            .frame(height: toolbarHeight)
            .background(.ultraThinMaterial) // subtle translucent background (iOS/macOS)
            .ignoresSafeArea(edges: .bottom) // let the background extend into safe area if needed
        }
        // ensure the overlay doesn't intercept touch events except the toolbar
        .allowsHitTesting(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    
    func initDataManager() {
        Log.debug("projlist: view: init data manager - \(self.db.getContainer(moc)) - wsId: \(workspaceId)")
        let fr = EProject.fetchRequest()
        fr.sortDescriptors = self.getSortDescriptors()
        if searchText.isNotEmpty {
            fr.predicate = NSPredicate(format: "(name CONTAINS[cd] %@) OR (desc CONTAINS[cd] %@)", searchText, searchText)  // c: case-insensitive; d: diacritic-insensitive
        } else {
            fr.predicate = NSPredicate(format: "workspace.id == %@ AND name != %@ AND markForDelete == %hdd", workspaceId, "", false)
        }
        fr.fetchBatchSize = 50
        dataManager = CoreDataManager(fetchRequest: fr, ctx: moc, onChange: { projects in
            withAnimation {
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
    
    func reorderProject(from source: IndexSet, to destination: Int) {
        guard source.first != nil else { return }
        isProcessing = true
        var projects = projects.map { $0 }
        projects.move(fromOffsets: source, toOffset: destination)
        DispatchQueue.main.async {
            for (index, project) in projects.enumerated() {
                project.order = NSDecimalNumber(string: "\(index)")
            }
            self.db.saveMainContext()
            isProcessing = false
        }
    }
    
    /// Delete projects after the confirmation. If multiple projects are selected and the delete context menu is inside the selection, all those projects are deleted.
    /// If there are multiple projects selected and delete context menu is for a project outside the selection, then only that specific project is deleted. This is the standard macOS behaviour.
    func deleteProjects() {
        if let project = projectPendingDelete {
            isProcessing = true
            if selectedProjectIds.contains(project.getId()) {
                // Delete all selected projects. Current project is part of it.
                var projectsToDelete: [EProject] = []
                selectedProjectIds.forEach { id in
                    if let proj = self.projects.first(where: { elem in
                        elem.getId() == id
                    }) {
                        projectsToDelete.append(proj)
                    }
                }
                projectsToDelete.forEach { proj in
                    self.db.deleteEntity(proj, ctx: moc)
                    RequestsListView.RequestsListState.deleteRequestsListState(proj.getId())  // Clear request list preferences associated with this project.
                }
            } else {
                // Delete only the item on which the context menu delete was clicked.
                self.db.deleteEntity(project, ctx: moc)
                RequestsListView.RequestsListState.deleteRequestsListState(project.getId())  // Clear request list preferences associated with this project.
            }
            self.db.saveMainContext { _ in
                isProcessing = false
            }
        }
        projectPendingDelete = nil
    }
    
    /// Checks if there are multiple projects selected and user clicked the delete on one of the items' context menu.
    /// If there are multiple projects selected and user clicked the context menu of a new item, there is only that project which needs to be deleted.
    func isThereMultipleProjectsToDelete() -> Bool {
        if let project = projectPendingDelete {
            if selectedProjectIds.contains(project.getId()) {
                return true
            }
        }
        return false
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
