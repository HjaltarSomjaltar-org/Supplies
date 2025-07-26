import Foundation
import SwiftData

@Observable
final class ItemsViewModel: Sendable {
    private let modelContainer: ModelContainer
    private let dataHandler: DataHandler
    
    init(modelContainer: ModelContainer, dataHandler: DataHandler) {
       self.modelContainer = modelContainer
       self.dataHandler = dataHandler
    }
    
    func fetchItems(with predicate: Predicate<Item>) async throws -> [ItemDTO] {
       let fetchDescriptor = FetchDescriptor<Item>(predicate: predicate, sortBy: [SortDescriptor(\Item.date, order: .reverse)])
        let items = try await dataHandler.getItems(with: fetchDescriptor)
        await dataHandler.saveTop3ItemsForWidget(items)
        return items
    }
    
    func addItem(name: String, date: Date, quantity: Int, duration: Double, notifyDays: Int?, lastUsed: Date, supplySize: Int, durationAdjustmentFactor: Double = 0.7, minimumUpdatePercentage: Double = 0.6) async throws -> ItemDTO {
        try await dataHandler.addItem(name: name, date: date, quantity: quantity, duration: duration, notifyDays: notifyDays, lastUsed: lastUsed, supplySize: supplySize, durationAdjustmentFactor: durationAdjustmentFactor, minimumUpdatePercentage: minimumUpdatePercentage)
    }
    
    func removeItem(id: UUID) async throws {
        try await dataHandler.removeItem(id: id)
    }
    
    func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Double, notifyDays: Int?, lastUsed: Date, supplySize: Int, durationAdjustmentFactor: Double, minimumUpdatePercentage: Double) async throws -> ItemDTO {
        try await dataHandler.updateItem(id: id, name: name, date: date, quantity: quantity, duration: duration, notifyDays: notifyDays, lastUsed: lastUsed, supplySize: supplySize, durationAdjustmentFactor: durationAdjustmentFactor, minimumUpdatePercentage: minimumUpdatePercentage)
    }
    
    func updateOrderStatus(id: UUID, isOrdered: Bool) async throws -> ItemDTO {
        try await dataHandler.updateOrderStatus(id: id, isOrdered: isOrdered)
    }
    
    func stockUp(id: UUID) async throws -> ItemDTO {
        try await dataHandler.stockUp(id: id)
    }
    
    func useItem(id: UUID, forceUse: Bool = false) async throws -> (item: ItemDTO, requiresConfirmation: Bool) {
        try await dataHandler.useItem(id: id, forceUse: forceUse)
    }
} 
