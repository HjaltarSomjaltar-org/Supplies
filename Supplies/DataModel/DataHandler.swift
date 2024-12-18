import Foundation
import SwiftData

protocol Storage {
    func addItem(name: String, date: Date, quantity: Int, duration: Int, notifyDays: Int?) async throws -> ItemDTO
    func removeItem(id: UUID) async throws
    func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Int, notifyDays: Int?) async throws -> ItemDTO
    func getItems(with descriptor: FetchDescriptor<Item>) async throws -> [ItemDTO]
    func updateOrderStatus(id: UUID, isOrdered: Bool) async throws -> ItemDTO
}

@ModelActor
actor DataHandler: Storage {
    func addItem(name: String, date: Date, quantity: Int, duration: Int, notifyDays: Int?) async throws -> ItemDTO {
        let item = Item(id: UUID(), name: name, date: date, quantity: quantity, duration: duration, notifyDays: notifyDays)
        modelContext.insert(item)
        try modelContext.save()
        return ItemDTO(id: item.id, name: item.name, date: item.date, quantity: item.quantity, duration: item.duration, notifyDays: item.notifyDays)
    }
    
    func removeItem(id: UUID) async throws {
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        try modelContext.delete(model: Item.self, where: predicate)
        try modelContext.save()
    }
    
    func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Int, notifyDays: Int?) async throws -> ItemDTO {
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        
        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        let items = try modelContext.fetch(descriptor)
        
        guard let itemToUpdate = items.first else {
            throw NSError(domain: "Item not found", code: 404)
        }
        
        itemToUpdate.name = name
        itemToUpdate.date = date
        itemToUpdate.quantity = quantity
        itemToUpdate.duration = duration
        itemToUpdate.notifyDays = notifyDays
        
        try modelContext.save()
        
        return ItemDTO(
            id: itemToUpdate.id, 
            name: itemToUpdate.name, 
            date: itemToUpdate.date, 
            quantity: itemToUpdate.quantity, 
            duration: itemToUpdate.duration,
            notifyDays: itemToUpdate.notifyDays,
            isOrdered: itemToUpdate.isOrdered
        )
    }
    
    func getItems(with descriptor: FetchDescriptor<Item>) async throws -> [ItemDTO] {
        return try modelContext.fetch(descriptor).map { 
            ItemDTO(id: $0.id, 
                   name: $0.name, 
                   date: $0.date, 
                   quantity: $0.quantity, 
                   duration: $0.duration,
                   notifyDays: $0.notifyDays,
                   isOrdered: $0.isOrdered)
        }
    }
    
    func updateOrderStatus(id: UUID, isOrdered: Bool) async throws -> ItemDTO {
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        
        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        let items = try modelContext.fetch(descriptor)
        
        guard let itemToUpdate = items.first else {
            throw NSError(domain: "Item not found", code: 404)
        }
        
        itemToUpdate.isOrdered = isOrdered
        try modelContext.save()
        
        return ItemDTO(id: itemToUpdate.id, 
                      name: itemToUpdate.name, 
                      date: itemToUpdate.date, 
                      quantity: itemToUpdate.quantity, 
                      duration: itemToUpdate.duration,
                      notifyDays: itemToUpdate.notifyDays,
                      isOrdered: itemToUpdate.isOrdered)
    }
}
