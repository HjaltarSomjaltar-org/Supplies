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
    @StateObject private var themeManager = ThemeManager.shared
    private let modelContainer: ModelContainer
    private let dataHandler: DataHandler
    private let itemsViewModel: ItemsViewModel

    // Sheet-State für Deeplink-Edit
    @State private var deeplinkEditItem: ItemDTO?
    @State private var itemsDTO: [ItemDTO] = []

    init() {
     do {
        let schema = Schema([Item.self])
        let configuration = ModelConfiguration(groupContainer: .identifier("group.supplies.com"))
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
            TabBar(viewModel: itemsViewModel, itemsDTO: $itemsDTO)
                .preferredColorScheme(themeManager.colorScheme)
                .sheet(item: $deeplinkEditItem) { item in
                    NavigationStack {
                        DetailView(item: item) { id, name, date, quantity, duration, notifyDays, lastUsed, supplySize, durationAdjustmentFactor, minimumUpdatePercentage in
                            try await itemsViewModel.updateItem(
                                id: id,
                                name: name,
                                date: date,
                                quantity: quantity,
                                duration: duration,
                                notifyDays: notifyDays,
                                lastUsed: lastUsed,
                                supplySize: supplySize,
                                durationAdjustmentFactor: durationAdjustmentFactor,
                                minimumUpdatePercentage: minimumUpdatePercentage
                            )
                            // Items nach Update neu laden
                            let predicate = #Predicate<Item> { $0.name != "" }
                            itemsDTO = try await itemsViewModel.fetchItems(with: predicate)
                            // Sheet nach erfolgreichem Speichern schließen
                            deeplinkEditItem = nil
                        }
                    }
                }
                .onOpenURL { url in
                    guard url.scheme == "supplies",
                          url.host == "edit",
                          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                          let idQuery = components.queryItems?.first(where: { $0.name == "id" }),
                          let idString = idQuery.value,
                          let uuid = UUID(uuidString: idString)
                    else { return }
                    
                    // ItemDTO aus ViewModel holen und Sheet öffnen
                    Task {
                        let predicate = #Predicate<Item> { $0.id == uuid }
                        if let item = try? await itemsViewModel.fetchItems(with: predicate).first {
                            deeplinkEditItem = item
                        }
                    }
                }
        }
    }
}
