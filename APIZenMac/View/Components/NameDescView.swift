//
//  NameDescView.swift
//  APIZen
//
//  Created by Jaseem V V on 05.10.2024.
//

import SwiftUI

/// Displays name, description with an image as a list item. The texts will wrap to new line to display full text content. Used in workspace, project listing.
struct NameDescView: View {
    // Here we use plain variables instead of @State because this value is obtained from parent and this view does not own this.
    // @State means this view owns this piece of data and is the source of truth for it. SwiftUI will store and preserve it across view reloads. External changes will not reflect once set unless synced in some way.
    // So NameDescView is a pure view of the data. It doesn't own the data.
    var imageName: String
    var name: String
    var desc: String?
    var isDisplayCheckmark = false
    
    @Environment(\.colorScheme) private var colorScheme
    private let theme = ThemeManager.shared
    
    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(theme.getForegroundStyle())
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20, alignment: .center)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)  // Allows wrap and display full text content
                if let desc = desc, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundStyle(theme.getDescriptionColor(colorScheme))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)  // Allows wrap and display full text content
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)  // claim remaining width
            .layoutPriority(1)  // wins when space is constrained
            
            Spacer()
            
            if self.isDisplayCheckmark {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
    }
}
