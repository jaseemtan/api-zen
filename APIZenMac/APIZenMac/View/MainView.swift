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
import AppKit

/// The main view shows the panes. Each pane state is stored in the window registry and restore on launch. Since the changing of pane display from view to hide makes UI to change, it looks like a flicker.
/// So a progress indicator is displayed until the view loads fully.
struct MainView: View {
    @Binding var selectedWorkspaceId: String
    @Binding var coreDataContainer: CoreDataContainer
    @Binding var workspaceName: String
    @Binding var project: EProject?
    @Binding var request: ERequest?
    @Binding var showNavigator: Bool  // Left pane
    @Binding var showInspector: Bool  // Right pane
    @Binding var showRequestComposer: Bool  // The center pane
    @Binding var showCodeView: Bool  // Center bottom pane
    
    @Environment(\.managedObjectContext) private var ctx
    
    @State private var isLoading: Bool = true
    
    let windowIndex: Int
    
    private let db = CoreDataService.shared

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                ThreeColumnSplitView(
                    left: NavigatorView(workspaceId: $selectedWorkspaceId, project: $project),
                    center: VStack {
                        VSplitView {
                            RequestComposerView()
                                .frame(minHeight: 150)
                            if showCodeView {
                                CodeView(workspaceName: $workspaceName, selectedWorkspaceId: $selectedWorkspaceId, coreDataContainer: $coreDataContainer)
                                    .frame(minHeight: 80)
                            }
                        }
                        Divider()
                        MainToolbarView(workspaceName: $workspaceName, selectedWorkspaceId: $selectedWorkspaceId, coreDataContainer: $coreDataContainer, showCodeView: $showCodeView)
                            .frame(height: 24)  // fixed height for status bar
                            .padding(.horizontal, 8)
                    },
                    right: InspectorView(),
                    showNavigator: $showNavigator,
                    showInspector: $showInspector
                )
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
        .task {
            Log.debug("mainview: task invoked")
            isLoading = false  // This needs to be done in task instead of onAppear. onAppear will show the flicker.
        }
    }
}

// MARK: - Panes

/// Request composer view displayed in the center pane at the top half.
struct RequestComposerView: View {
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

/// Code view displayed at the lower half of the center pane after the request composer view.
struct CodeView: View {
    @Binding var workspaceName: String
    @Binding var selectedWorkspaceId: String
    @Binding var coreDataContainer: CoreDataContainer
    
    private let utils = AZUtils.shared
    private let theme = ThemeManager.shared
    
    var body: some View {
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
    }
}

/// Toolbar view displayed at the bottom of the request composer (center) pane.
struct MainToolbarView: View {
    @Binding var workspaceName: String
    @Binding var selectedWorkspaceId: String
    @Binding var coreDataContainer: CoreDataContainer
    @Binding var showCodeView: Bool
    
    @State private var showWorkspacePopup = false
    
    private let utils = AZUtils.shared
    private let theme = ThemeManager.shared
    
    var body: some View {
        HStack {
            // Code icon
            Button {
                Log.debug("code button tapped")
                showCodeView.toggle()
            } label: {
                Image(systemName: "curlybraces.square")  // curlybraces.square.fill
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .font(.body)
                    .frame(width: 16, height: 16, alignment: .center)
            }
            .help("Code view")
            .buttonStyle(.plain)
            
            Spacer()

            // Workspace switcher button
            Button {
                Log.debug("workspace button tapped")
                showWorkspacePopup.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: theme.getWorkspaceTypeIconName(coreDataContainer: coreDataContainer))
                        .font(.system(size: 13))
                    Text(utils.truncateText(workspaceName, len: 32))
                        .font(.system(size: 13, weight: .regular))
                }
                .foregroundColor(theme.getAccentColor())
                .underline(false)
                .padding(.horizontal, 10)  // Gives enough room for click by expanding the button area. It's not visible unless we apply a border to it.
                .padding(.vertical, 6)
                .contentShape(Rectangle())
//                .debugOverlay()
            }
            .buttonStyle(.plain)
            .popover(
                isPresented: $showWorkspacePopup,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .top  // opens popup to the top of the button
            ) {
                WorkspacePopupView(selectedWorkspaceId: $selectedWorkspaceId, workspaceName: $workspaceName, coreDataContainer: $coreDataContainer)
                    .frame(width: 600, height: 500)  // popup dimension
            }
            Spacer()
        }
        .padding(.bottom, 8)
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
