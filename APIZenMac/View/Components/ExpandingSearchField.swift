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
    @Binding var text: String
    var onSearch: (String) -> Void = { _ in }

    @State private var isExpanded = false
    @FocusState private var isTextFieldFocused: Bool

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
                            .fill(.quaternary)
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
//            .focusable(false)  // prevents default focus highlight on popup open
        }
        .frame(maxWidth: .infinity)  // field takes all available width
        .animation(.default, value: isExpanded)
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
//        if !text.isEmpty {
//            onSearch(text)
//        } else {
//            // Optional: default pattern search
//            // onSearch("*")
//        }
    }
}
