//
//  MainViewPhone.swift
//  APITesterPro
//
//  Created by Jaseem V V on 25.09.2024.
//  Copyright © 2024 Jaseem V V. All rights reserved.
//

import SwiftUI
import CoreData

@available(iOS 17.0, *)
struct MainViewPhone: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EProject.name, ascending: true)],
        animation: .default
    ) private var projects: FetchedResults<EProject>

    var body: some View {
        NavigationStack {
            List {
                ForEach(projects) { project in
                    Text(project.name ?? "")
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
