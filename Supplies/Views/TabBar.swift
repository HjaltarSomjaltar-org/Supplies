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
    @State var itemsDTO = [ItemDTO]()

    var body: some View {
       TabView {
        ListView(viewModel: viewModel, itemsDTO: $itemsDTO)
            .tabItem {
                Label("Items", systemImage: "list.bullet")
            }
       }
    }
}
