//
//  RequestListView.swift
//  APIZenMac
//
//  Created by Jaseem V V on 14/12/25.
//

import SwiftUI
import CoreData
import AZData
import AZCommon
 
/// Requests list view for a selected project.
struct RequestsListView: View {
    /// Selected workspace id
    @Binding var workspaceId: String
    @Binding var project: EProject?
    @Binding var isProcessing: Bool
    
    @State private var searchText: String = ""
    @State private var isSearchActive: Bool? = false  // Is search button clicked and search field display? If so we are hiding other items on the bottom bar, except sort.
    @State private var requests: [ERequest] = []
    @State private var dataManager: CoreDataManager<ERequest>?
    @State private var sortField: SortField = .manual
    @State private var sortAscending: Bool = true
    @State private var requestPendingDelete: ERequest?  // Holds the project that is user is deleting
    @State private var showDeleteConfirmation = false
    @State private var selectedRequestIds: Set<String> = []
    @State private var isDragMode = false
    
    @Environment(\.managedObjectContext) private var moc
    @Environment(\.colorScheme) private var colorScheme
    
    private let toolbarHeight: CGFloat = 32.0
    private let db = CoreDataService.shared
    private let theme = ThemeManager.shared
    
    /// This is request list state which for the given project. So it is identified using project id.
    struct RequestsListState: Identifiable, Codable {
        var projectId: String = ""
        var sortField: SortField = .manual
        var sortAscending: Bool = true
        
        var id: String { projectId }
        
        func encode() -> Data? {
            return try? JSONEncoder().encode(self)
        }
        
        func decode(_ data: Data?) -> RequestsListState? {
            guard let data = data else { return nil }
            return try? JSONDecoder().decode(RequestsListState.self, from: data)
        }
        
        /// Saves the state to user defaults.
        func saveRequestsListState() {
            if let data = self.encode() {
                AZUtils.shared.setValue(key: self.getUserDefaultsKey(), value: data)
                Log.debug("reqlist: saved req list state: sortField: \(sortField) - sortAsc: \(sortAscending) - projId: \(projectId)")
            }
        }
        
        /// Restore the state from user defaults. Updates the current object. This should be invoked after setting the workspaceId.
        mutating func restoreRequestsListState() {
            if projectId.isEmpty { return }
            if let data = AZUtils.shared.getValue(self.getUserDefaultsKey()) as? Data {
                if let state = self.decode(data) {
                    Log.debug("reqlist: restored req list state: sortField: \(sortField) - sortAsc: \(sortAscending) - projId: \(projectId)")
                    self.sortField = state.sortField
                    self.sortAscending = state.sortAscending
                }
            }
        }
        
        /// Requests list state needs to be deleted when the project is deleted. And that happens in the projects list view. So keeping this static.
        static func deleteRequestsListState(_ projectId: String) {
            AZUtils.shared.removeValue("\(AZMConst.requestsListStateKey)-\(projectId)")
        }
        
        private func getUserDefaultsKey() -> String {
            return "\(AZMConst.requestsListStateKey)-\(self.projectId)"
        }
    }
    
    @State private var state: RequestsListState = RequestsListState()
    
    // Explicit init with only the required params because we have many properties and default init becomes internal.
    init(workspaceId: Binding<String>, project: Binding<EProject?>, searchText: String, isProcessing: Binding<Bool>) {
        Log.debug("reqlist: view init")
        self._workspaceId = workspaceId
        self._project = project  // selected project
        self.searchText = searchText
        self._isProcessing = isProcessing
    }

    var body: some View {
        Group {
            List(selection: $selectedRequestIds) {
                ForEach(requests) { req in
                    NameDescView(name: "\(req.getName()) - \(req.order!)", isDisplayDragIndicator: isDragMode)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .tag(req.getId())
                        .onTapIf(!isDragMode) {  // This overrides the default selection check on the list.
                            Log.debug("reqlist: tap")
//                            onSelect(req)
                        }
                        .contextMenu {
                            Button("Copy") {
                                Log.debug("reqlist: req copy: \(req.getName())")
                            }
                            
                            Button("Cut") {
                                Log.debug("reqlist: req cut: \(req.getName())")
                            }
                            
                            Button("Paste") {
                                Log.debug("reqlist: req paste: \(req.getName())")
                            }
                            
                            Button("Delete", role: .destructive) {
                                Log.debug("reqlist: delete on req: \(req.getName()) - \(req.getId())")
                                Log.debug("reqlist: selected req ids: \(selectedRequestIds)")
                                requestPendingDelete = req
                                showDeleteConfirmation = true  // Display delete confirmation dialog
                            }
                        }
                }
                .onMove { indexSet, order in
                    Log.debug("reqlist: on move")
                    guard sortField == .manual && sortAscending else { return }
                    reorderRequest(from: indexSet, to: order)
                }
            }
            .padding(.bottom, toolbarHeight)
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
            
            bottomToolbarView
        }
        .onAppear {
            Log.debug("reqlist: on appear: wsId: \(workspaceId)")
            selectedRequestIds.removeAll()
            if let proj = project {
                state.projectId = proj.getId()
                state.restoreRequestsListState()
                self.initDataManager()
            }
        }
        .task {
            sortField = state.sortField
            sortAscending = state.sortAscending
        }
        .onChange(of: project) { _, newProj in
            guard let proj = newProj else { return }
            Log.debug("reqlist: project ichanged: \(proj.getName())")
            self.updateState(proj)
            self.initDataManager()  // reinit data maanger with new predicate for project to update request listing
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
        .onChange(of: isDragMode, { _, dragMode in
            if !dragMode {
                selectedRequestIds.removeAll()
            }
        })
        .confirmationDialog(isThereMultipleRequestsToDelete() ? "Are you sure you want to delete the selected requests?" : "Are you sure you want to delete this request?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteRequests()
            }

            Button("Cancel", role: .cancel) {
                requestPendingDelete = nil
                isProcessing = false
            }
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
                        state.saveRequestsListState()
                    },
                    onSortAscendingChanged: { flag in
                        sortAscending = flag
                        state.sortAscending = sortAscending
                        state.saveRequestsListState()
                    },
                    helpText: "Sort Projects"
                )
                .padding(.leading, 12)

                if !(isSearchActive ?? false) {
                    AddButton(onTap: {}, helpText: "Add Group")
                    // Drag mode button
                    Button {
                        Log.debug("drag mode toggle")
                        withAnimation {
                            isDragMode.toggle()
                        }
                    } label: {
                        Image(systemName: "arrow.up.and.down.text.horizontal")
                            .font(.system(size: 15, weight: .regular))
                            .imageScale(.medium)
                            .contentShape(Rectangle())
                            .foregroundStyle(getDragModeIconColor())
                    }
                    .buttonStyle(.borderless)
                    .help("Drag Mode")
                    .disabled(!isDraggable())
                }
                
                Spacer()

                // Search button on right. Hides other toolbar items when expanded.
                ExpandingSearchField(isActive: $isSearchActive) { query in
                    let text = query.trim()
                    Log.debug("Search for: \(query)")
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
        Log.debug("reqlist: view: init data manager - \(self.db.getContainer(moc)) - projId: \(project?.getId() ?? "nil")")
        guard let project = project else { return }
        let fr = ERequest.fetchRequest()
        fr.sortDescriptors = self.getSortDescriptors()
        if searchText.isNotEmpty {
            fr.predicate = NSPredicate(
                format: """
                project.id == %@ AND (
                    name CONTAINS[cd] %@ OR 
                    desc CONTAINS[cd] %@ OR
                    url CONTAINS[cd] %@
                )
                """,
                project.getId(), searchText, searchText, searchText)  // c: case-insensitive; d: diacritic-insensitive
        } else {
            fr.predicate = NSPredicate(format: "project.id == %@ AND name != %@ AND markForDelete == %hdd", project.getId(), "", false)
        }
        fr.fetchBatchSize = 50
        dataManager = CoreDataManager(fetchRequest: fr, ctx: moc, onChange: { requests in
            withAnimation {
                self.requests = requests
            }
        })
    }
    
    /// Update user preference state
    func updateState(_ proj: EProject) {
        isDragMode = false
        state = RequestsListState(projectId: proj.getId())
        state.restoreRequestsListState()
        sortField = state.sortField
        sortAscending = state.sortAscending
    }
    
    func reorderRequest(from source: IndexSet, to destination: Int) {
        guard source.first != nil else { return }
        isProcessing = true
        var requests = requests.map { $0 }
        requests.move(fromOffsets: source, toOffset: destination)
        DispatchQueue.main.async {
            for (index, request) in requests.enumerated() {
                request.order = NSDecimalNumber(string: "\(index)")
            }
            self.db.saveMainContext()
            isProcessing = false
        }
    }
    
    func deleteRequests() {
        if let request = requestPendingDelete {
            isProcessing = true
            if selectedRequestIds.contains(request.getId()) {
                // Delete all selected requests. Current request is part of it.
                var requestsToDelete: [ERequest] = []
                selectedRequestIds.forEach { id in
                    if let req = self.requests.first(where: { elem in
                        elem.getId() == id
                    }) {
                        requestsToDelete.append(req)
                    }
                }
                requestsToDelete.forEach { req in
                    self.db.deleteEntity(req, ctx: moc)
                }
            } else {
                // Delete only the item on which the context menu delete was clicked.
                self.db.deleteEntity(request, ctx: moc)
            }
            self.db.saveMainContext { _ in
                isProcessing = false
            }
            // TODO: delete any request preferences
        }
        requestPendingDelete = nil
    }
    
    /// Checks if there are multiple requests selected and user clicked the delete on one of the items' context menu.
    /// If there are multiple requests selected and user clicked the context menu of another request, there is only that request which needs to be deleted.
    func isThereMultipleRequestsToDelete() -> Bool {
        if let request = requestPendingDelete {
            if selectedRequestIds.contains(request.getId()) {
                return true
            }
        }
        return false
    }
    
    /// Check if the request list is draggable, which will be the case only when sorting is manual and order is ascending.
    private func isDraggable() -> Bool {
        return sortField == .manual && sortAscending
    }

    private func getDragModeIconColor() -> Color {
        if !isDraggable() {
            return theme.getDisabledIconColor(colorScheme)
        }
        if isDragMode {
            return theme.getAccentColor()
        }
        return .secondary
    }
    
    private func getSortDescriptors() -> [NSSortDescriptor] {
        let sortDescriptor: NSSortDescriptor
        switch sortField {
        case .manual:
            sortDescriptor = NSSortDescriptor(keyPath: \ERequest.order, ascending: sortAscending)
        case .name:
            sortDescriptor = NSSortDescriptor(keyPath: \ERequest.name, ascending: sortAscending)
        case .created:
            sortDescriptor = NSSortDescriptor(keyPath: \ERequest.created, ascending: sortAscending)
        }
        return [sortDescriptor]
    }
}
