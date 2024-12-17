import Foundation
import SwiftData

protocol Storage {
    func addItem(name: String, date: Date, quantity: Int, duration: Int, limit: Int) async throws -> ItemDTO
    func removeItem(id: UUID) async throws
    func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Int, limit: Int) async throws -> ItemDTO
    func getItems() async throws -> [ItemDTO]
}

@ModelActor
actor DataHandler: Storage {
    func addItem(name: String, date: Date, quantity: Int, duration: Int, limit: Int) async throws -> ItemDTO {
        let item = Item(id: UUID(), name: name, date: date, quantity: quantity, duration: duration, limit: limit)
        modelContext.insert(item)
        try modelContext.save()
        return ItemDTO(id: item.id, name: item.name, date: item.date, quantity: item.quantity, duration: item.duration, limit: item.limit)
    }
    
    func removeItem(id: UUID) async throws {
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        try modelContext.delete(model: Item.self, where: predicate)
        try modelContext.save()
    }
    
    func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Int, limit: Int) async throws -> ItemDTO {
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        
        let descriptor = FetchDescriptor<Item>(predicate: predicate, sortBy: [SortDescriptor(\Item.date, order: .reverse)])
        let items = try modelContext.fetch(descriptor)
        
        guard let itemToUpdate = items.first else {
            throw NSError(domain: "Item not found", code: 404)
        }
        
        itemToUpdate.name = name
        itemToUpdate.date = date
        itemToUpdate.quantity = quantity
        itemToUpdate.duration = duration
        itemToUpdate.limit = limit
        
        try modelContext.save()
        
        return ItemDTO(id: itemToUpdate.id, 
                      name: itemToUpdate.name, 
                      date: itemToUpdate.date, 
                      quantity: itemToUpdate.quantity, 
                      duration: itemToUpdate.duration,
                      limit: itemToUpdate.limit)
    }
    
    func getItems() async throws -> [ItemDTO] {
        let descriptor = FetchDescriptor<Item>()
        return try modelContext.fetch(descriptor).map { 
            ItemDTO(id: $0.id, 
                   name: $0.name, 
                   date: $0.date, 
                   quantity: $0.quantity, 
                   duration: $0.duration,
                   limit: $0.limit)
        }
    }
}
