//
//  MainViewPhone.swift
//  APITesterPro
//
//  Created by Jaseem V V on 25.09.2024.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
struct MainViewPhone: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<50) { index in
                    Text("List Item \(index)")
                }
            }
            .contentMargins(.top, 8)
            .listStyle(.automatic)
            .navigationTitle("Projects").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Settings button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        print("Settings tapped")
                    }) {
                        Image(systemName: "gear")
                    }
                }
                // Add button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Plus tapped")
                    }) {
                        Image(systemName: "plus")
                    }
                }
                // Bottom toolbar with workspace switcher
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    Button(action: {
                        print("Bottom toolbar tapped")
                    }) {
                        HStack {
                            Image(systemName: "iphone")
                            Text("Default workspace")
                        }.font(.subheadline)
                    }
                    Spacer()
                }
            }
        }
    }
}

//#Preview {
//    if #available(iOS 17.0, *) {
//        MainViewPhone()
//    } else {
//        // Fallback on earlier versions
//    }
//}
