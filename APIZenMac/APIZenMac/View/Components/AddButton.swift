//
//  AddButton.swift
//  APIZenMac
//
//  Created by Jaseem V V on 11/12/25.
//

import SwiftUI

/// Add button that can be used in places like Add Workspace, Add Project.
struct AddButton: View {
    /// Button tap handler
    var onTap: () -> Void
    /// The hover help text
    var helpText: String
    
    var body: some View {
        Button {
            onTap()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 15, weight: .semibold))
                .imageScale(.medium)
                .padding(.horizontal, 8)  // Gives enough room for click by expanding the button area. It's not visible unless we apply a border to it.
                .padding(.vertical, 6)
                .contentShape(Rectangle())
//                .debugOverlay()
        }
        .buttonStyle(.borderless)
        .help(helpText)
    }
}
