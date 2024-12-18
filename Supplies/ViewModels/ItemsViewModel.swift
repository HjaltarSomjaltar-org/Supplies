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
        return try await dataHandler.getItems(with: fetchDescriptor)
    }
    
    func addItem(name: String, date: Date, quantity: Int, duration: Int, notifyDays: Int?) async throws -> ItemDTO {
        try await dataHandler.addItem(name: name, date: date, quantity: quantity, duration: duration, notifyDays: notifyDays)
    }
    
    func removeItem(id: UUID) async throws {
        try await dataHandler.removeItem(id: id)
    }
    
    func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Int, notifyDays: Int?) async throws -> ItemDTO {
        try await dataHandler.updateItem(id: id, name: name, date: date, quantity: quantity, duration: duration, notifyDays: notifyDays)
    }
    
    func updateOrderStatus(id: UUID, isOrdered: Bool) async throws -> ItemDTO {
        try await dataHandler.updateOrderStatus(id: id, isOrdered: isOrdered)
    }
} 
