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
    @Binding var itemsDTO: [ItemDTO]

    var body: some View {
       ListView(itemsDTO: $itemsDTO, viewModel: viewModel)
        .tabItem {
            Label("Items", systemImage: "list.bullet")
        }
    }
}
