//
//  WorkspaceWindowRoot.swift
//  APIZenMac
//
//  Created by Jaseem V V on 06/12/25.
//

import SwiftUI
import AZData
import AZCommon

struct WorkspaceWindowRoot: View {
    let db: CoreDataService
    
    // Per window persisted state. These values are automatically kept separate for each window.
    @SceneStorage(AZConst.selectedWorkspaceIdKey)
    private var selectedWorkspaceId: String = "default"
    
    // CoreDataContainer value for the selected workspace.
    @SceneStorage(AZConst.selectedWorkspaceContainerKey)
    private var selectedWorkspaceContainer: String = CoreDataContainer.local.rawValue
    
    var body: some View {
        MainView(
            selectedWorkspaceId: $selectedWorkspaceId
        )
        .environment(\.managedObjectContext, self.db.getMainMOC(container: CoreDataContainer(rawValue: selectedWorkspaceContainer)!))
    }
    
}

