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
    var searchText: String = ""
    
    @State private var projects: [EProject] = []
    @State private var dataManager: CoreDataManager<EProject>?
    @State private var sortField: ProjectSortField = .manual
    @State private var sortAscending: Bool = true
    
    @Environment(\.managedObjectContext) private var moc
    
    private let projectsCacheName: String = "projects-cache"
    private let toolbarHeight: CGFloat = 32.0
    private let db = CoreDataService.shared
    private let theme = ThemeManager.shared
    
    enum ProjectSortField: String, CaseIterable, Codable, Equatable {
        case manual
        case name
        case created
    }
    
    /// This is projects list state which is one per workspace. So it is identified using workspace id.
    struct ProjectsListState: Identifiable, Codable {
        var workspaceId: String = ""
        var sortField: ProjectSortField = .manual
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
    init(workspaceId: String, onSelect: @escaping (EProject) -> Void, selectedProject: Binding<EProject?>, searchText: String) {
        Log.debug("proj list view: ws id: \(workspaceId)")
        self.workspaceId = workspaceId
        self.onSelect = onSelect
        self._selectedProject = selectedProject
        self.searchText = searchText
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
            VStack(spacing: 0) {
                Spacer() // push toolbar to bottom
                Divider()
                HStack {
                    Menu {  // Using toggle so that the alignment of text shows fixed center with space for checkmark left as a constant. Using Button with HStack with Image and Text doesn't align the text by leaving the checkmark space constant when not checked.
                        // Section: Sort By
                        Text("Sort")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .disabled(true)

                        Toggle(isOn: Binding(
                            get: { sortField == .manual },
                            set: { isOn in
                                if isOn {
                                    sortField = .manual
                                     state.sortField = sortField
                                     state.saveProjectPopupState()
                                }
                            }
                        )) {
                            Text("manual")
                        }
                        
                        Toggle(isOn: Binding(
                            get: { sortField == .name },
                            set: { isOn in
                                if isOn {
                                    sortField = .name
                                    state.sortField = sortField
                                    state.saveProjectPopupState()
                                }
                            }
                        )) {
                            Text("by Name")
                        }

                        Toggle(isOn: Binding(
                            get: { sortField == .created },
                            set: { isOn in
                                if isOn {
                                    sortField = .created
                                    state.sortField = sortField
                                    state.saveProjectPopupState()
                                }
                            }
                        )) {
                            Text("by Created")
                        }

                        Divider()

                        // SECTION: Order
                        Text("Order")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .disabled(true)

                        Toggle(isOn: Binding(
                            get: { sortAscending },
                            set: { isOn in
                                if isOn {
                                    sortAscending = true
                                    state.sortAscending = sortAscending
                                    state.saveProjectPopupState()
                                }
                            }
                        )) {
                            Text("Ascending")
                        }

                        Toggle(isOn: Binding(
                            get: { !sortAscending },
                            set: { isOn in
                                if isOn {
                                    sortAscending = false
                                    state.sortAscending = sortAscending
                                    state.saveProjectPopupState()
                                }
                            }
                        )) {
                            Text("Descending")
                        }

                    } label: {
                        Image(systemName: theme.getSortIconName())
                            .font(.system(size: 15, weight: .regular))
                            .imageScale(.medium)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(sortField == .manual && sortAscending ? .primary : theme.getForegroundStyle())
                    }
                    .help("Sort Projects")
                    .buttonStyle(.borderless)
                    .padding(.leading, 8)

                    Spacer()

                    // Search button on right
                    Button(action: {
                        Log.debug("Project search clicked")
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.body)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: toolbarHeight)
                .background(.ultraThinMaterial) // subtle translucent background (iOS/macOS)
                .ignoresSafeArea(edges: .bottom) // let the background extend into safe area if needed
            }
            // ensure the overlay doesn't intercept touch events except the toolbar
            .allowsHitTesting(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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
        .onChange(of: workspaceId) { _, wsId in
            self.updateState(wsId)  // clear project list state and restore state if present for the given workspace.
        }
    }
    
    /// The query is cached. So multiple searches of the same parameters would not be that costly.
    func initDataManager() {
        Log.debug("proj list view: init data manager")
        let fr = EProject.fetchRequest()
        fr.sortDescriptors = self.getSortDescriptors()
        if searchText.isNotEmpty {
            // fr.predicate = NSPredicate(format: "(name CONTAINS[cd] %@) OR (desc CONTAINS[cd] %@)", searchText, searchText)  // c: case-insensitive; d: diacritic-insensitive
        } else {
            fr.predicate = NSPredicate(format: "workspace.id == %@ AND name != %@ AND markForDelete == %hdd", workspaceId, "", false)
        }
        fr.fetchBatchSize = 50
        if let dm = self.dataManager { dm.clearCache() }  // clear previous cache if already initialized before.
        dataManager = CoreDataManager(fetchRequest: fr, ctx: moc, cacheName: self.projectsCacheName, onChange: { projects in
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
