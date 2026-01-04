//
//  ExpandingSearchField.swift
//  APIZenMac
//
//  Created by Jaseem V V on 08/12/25.
//

import SwiftUI

/// A search icon on the right. Clicking on it will display a text field on the left of it. Entering text in search field will show a clear icon on the right.
/// Pressing enter or clicking search again when there is text content will perform a search. Clicking search icon again when there is not content will hide the text field and show just the icon.
struct ExpandingSearchField: View {
    @State var text: String = ""  // Using this as a @Binding will allow search to be performed as typed, because the change is trigged on each char change. Here we are using a @State because we perform search on pressing enter or button click. This is better for performance.
    /// Optional binding which can be tracked to see if search field is in active or expanded state or not.
    /// We are using this additional binding variable and not changing the `isExpanded` to binding because not in all cases does the parent view need to track this state.
    /// For example, if there are no changes the parent view needs to do if toggling between expanded, then we don't need this. Making it mandatory is is not a good design.
    @Binding var isActive: Bool?
    var onSearch: (String) -> Void = { _ in }

    /// Internally tracks if search is expanded to display text field.
    @State private var isExpanded = false
    @FocusState private var isTextFieldFocused: Bool
    
    init(isActive: Binding<Bool?> = .constant(nil), onSearch: @escaping (String) -> Void) {
        self._isActive = isActive
        self.onSearch = onSearch
    }

    var body: some View {
        HStack(spacing: 8) {
            if isExpanded {
                ZStack {
                    // Background + text field
                    TextField("Search", text: $text, onCommit: {
                        runSearchIfNeeded()
                    })
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quinary)
                    )

                    // Clear button inside the field, aligned to the trailing edge
                    HStack {
                        Spacer()
                        if !text.isEmpty {
                            Button {
                                text = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .imageScale(.small)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .padding(.trailing, 6)
                        }
                    }
                }
            } else {
                // When collapsed, field is hidden, but HStack still fills width
                Spacer(minLength: 0)
            }

            // Search icon on the right
            Button {
                handleSearchButtonTap()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .regular))
                    .imageScale(.medium)
            }
            .buttonStyle(.borderless)
        }
        .frame(maxWidth: .infinity)  // field takes all available width
        .animation(.default, value: isExpanded)
        .onChange(of: isExpanded) { _, newValue in
            isActive = newValue
        }
    }

    private func handleSearchButtonTap() {
        if isExpanded {
            if text.isEmpty {
                // No content => collapse
                withAnimation {
                    isExpanded = false
                }
                isTextFieldFocused = false
            } else {
                // Has content => perform search
                runSearchIfNeeded()
            }
        } else {
            // Expand and focus text field
            withAnimation {
                isExpanded = true
            }
            DispatchQueue.main.async {
                isTextFieldFocused = true
            }
        }
    }

    private func runSearchIfNeeded() {
        onSearch(text)
    }
}
