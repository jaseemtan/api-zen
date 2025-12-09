//
//  NameDescView.swift
//  APIZen
//
//  Created by Jaseem V V on 05.10.2024.
//

import SwiftUI

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
