//
//  VTextField.swift
//  APITesterPro
//
//  Created by Jaseem V V on 29.09.2024.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct VTextField: View {
    @State var placeholder: String = ""
    @Binding var text: String
    private let uiViewState = UIViewState.shared
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
            .background(self.uiViewState.getTextFieldBg())
            .cornerRadius(5)
    }
}
