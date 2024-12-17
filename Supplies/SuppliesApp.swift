//
//  SuppliesApp.swift
//  Supplies
//
//  Created by Marvin Polscheit on 17.12.24.
//

import SwiftUI
import SwiftData

@main
struct SuppliesApp: App {
    private let modelContainer: ModelContainer
    private let dataHandler: DataHandler
    private let itemsViewModel: ItemsViewModel

    init() {
     do {
        let schema = Schema([Item.self])
        let configuration = ModelConfiguration(schema: schema)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        dataHandler = DataHandler(modelContainer: modelContainer)
        itemsViewModel = ItemsViewModel(modelContainer: modelContainer, dataHandler: dataHandler)
        
        // Request notification authorization
        Task {
            try? await NotificationManager.shared.requestAuthorization()
        }
     } catch {
        fatalError("Could not initialize ModelContainer")
     }
    }
    
    var body: some Scene {
        WindowGroup {
            TabBar(viewModel: itemsViewModel)
        }
    }
}
