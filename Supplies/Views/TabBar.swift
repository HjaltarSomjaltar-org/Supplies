//
//  ContentView.swift
//  Supplies
//
//  Created by Marvin Polscheit on 17.12.24.
//

import SwiftUI
import SwiftData

struct TabBar: View {
    let viewModel: ItemsViewModel

    var body: some View {
       TabView {
        ListView(viewModel: viewModel)
            .tabItem {
                Label("Items", systemImage: "list.bullet")
            }
       }
    }
}
