//
//  SortMenu.swift
//  APIZenMac
//
//  Created by Jaseem V V on 12/12/25.
//

import SwiftUI

enum SortField: String, CaseIterable, Codable, Equatable {
    case manual
    case name
    case created
}

/// A sort menu icon with manual, name, created sort items with ascending and descending order items.
struct SortMenu: View {
    /// The field by which the sorting will be done.
    @Binding var sortField: SortField
    /// The order of the sorting
    @Binding var sortAscending: Bool
    
    /// On sort field change, this handler will be invoked with the sort field value.
    var onSortFieldChanged: ((SortField) -> Void)?
    /// On sort ascending change, this handler will be invoked with the new value.
    var onSortAscendingChanged: ((Bool) -> Void)?
    
    /// The hover help text for this menu.
    var helpText: String
    
    private let theme = ThemeManager.shared
    
    var body: some View {
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
                        onSortFieldChanged?(.manual)
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
                        onSortFieldChanged?(.name)
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
                        onSortFieldChanged?(.created)
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
                        onSortAscendingChanged?(true)
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
                        onSortAscendingChanged?(false)
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
        .help(helpText)
        .buttonStyle(.borderless)
    }
}
