//
//  NameDescView.swift
//  APIZen
//
//  Created by Jaseem V V on 05.10.2024.
//

import SwiftUI

// Here we use plain variables instead of @State because this value is obtained from parent and this view does not own this.
// @State means this view owns this piece of data and is the source of truth for it. SwiftUI will store and preserve it across view reloads. External changes will not reflect once set unless synced in some way.
// So NameDescView is a pure view of the data. It doesn't own the data.
struct NameDescView: View {
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
            HStack {
                VStack(alignment: .leading) {
                    Text(self.name)
                    if let desc = self.desc, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundStyle(theme.getDescriptionColor(colorScheme))
                    }
                }
                Spacer()
                if self.isDisplayCheckmark {
                    Image(systemName: "checkmark")
                }
            }
        }
        .contentShape(Rectangle())
    }
}
