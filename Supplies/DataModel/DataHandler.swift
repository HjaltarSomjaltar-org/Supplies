import Foundation
import SwiftData

protocol Storage {
    func addItem(name: String, date: Date, quantity: Int, duration: Double, notifyDays: Int?, lastUsed: Date, supplySize: Int, durationAdjustmentFactor: Double, minimumUpdatePercentage: Double) async throws -> ItemDTO
    func removeItem(id: UUID) async throws
    func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Double, notifyDays: Int?, lastUsed: Date, supplySize: Int, durationAdjustmentFactor: Double, minimumUpdatePercentage: Double) async throws -> ItemDTO
    func getItems(with descriptor: FetchDescriptor<Item>) async throws -> [ItemDTO]
    func updateOrderStatus(id: UUID, isOrdered: Bool) async throws -> ItemDTO
    func stockUp(id: UUID) async throws -> ItemDTO
    func useItem(id: UUID, forceUse: Bool) async throws -> (item: ItemDTO, requiresConfirmation: Bool)
}

@ModelActor
actor DataHandler: Storage {
    func addItem(name: String, date: Date, quantity: Int, duration: Double, notifyDays: Int?, lastUsed: Date, supplySize: Int, durationAdjustmentFactor: Double, minimumUpdatePercentage: Double) async throws -> ItemDTO {
        let item = Item(id: UUID(), name: name, date: date, quantity: quantity, duration: duration, notifyDays: notifyDays, supplySize: supplySize, durationAdjustmentFactor: durationAdjustmentFactor, minimumUpdatePercentage: minimumUpdatePercentage)
        item.lastUsed = lastUsed
        modelContext.insert(item)
        try modelContext.save()
        return ItemDTO(id: item.id, name: item.name, date: item.date, quantity: item.quantity, duration: item.duration, notifyDays: item.notifyDays, lastUsed: item.lastUsed, supplySize: item.supplySize, durationAdjustmentFactor: item.durationAdjustmentFactor, minimumUpdatePercentage: item.minimumUpdatePercentage)
    }
    
    func removeItem(id: UUID) async throws {
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        try modelContext.delete(model: Item.self, where: predicate)
        try modelContext.save()
    }
    
    func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Double, notifyDays: Int?, lastUsed: Date, supplySize: Int, durationAdjustmentFactor: Double, minimumUpdatePercentage: Double) async throws -> ItemDTO {
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
        itemToUpdate.lastUsed = lastUsed
        itemToUpdate.supplySize = supplySize
        itemToUpdate.durationAdjustmentFactor = durationAdjustmentFactor
        itemToUpdate.minimumUpdatePercentage = minimumUpdatePercentage
        
        try modelContext.save()
        
        return ItemDTO(
            id: itemToUpdate.id, 
            name: itemToUpdate.name, 
            date: itemToUpdate.date, 
            quantity: itemToUpdate.quantity, 
            duration: itemToUpdate.duration,
            notifyDays: itemToUpdate.notifyDays,
            isOrdered: itemToUpdate.isOrdered,
            lastUsed: itemToUpdate.lastUsed,
            supplySize: itemToUpdate.supplySize,
            durationAdjustmentFactor: itemToUpdate.durationAdjustmentFactor,
            minimumUpdatePercentage: itemToUpdate.minimumUpdatePercentage
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
                   isOrdered: $0.isOrdered,
                   lastUsed: $0.lastUsed,
                   supplySize: $0.supplySize,
                   durationAdjustmentFactor: $0.durationAdjustmentFactor,
                   minimumUpdatePercentage: $0.minimumUpdatePercentage)
        }
    }
    
    func updateItemDuration(id: UUID) async throws -> ItemDTO {
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        
        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        let items = try modelContext.fetch(descriptor)
        
        guard let itemToUpdate = items.first else {
            throw NSError(domain: "Item not found", code: 404)
        }
        
        // Update the last used date to today
        itemToUpdate.lastUsed = Date()
        try modelContext.save()
        
        return ItemDTO(id: itemToUpdate.id, 
                      name: itemToUpdate.name, 
                      date: itemToUpdate.date, 
                      quantity: itemToUpdate.quantity, 
                      duration: itemToUpdate.duration,
                      notifyDays: itemToUpdate.notifyDays,
                      isOrdered: itemToUpdate.isOrdered,
                      lastUsed: itemToUpdate.lastUsed,
                      supplySize: itemToUpdate.supplySize,
                      durationAdjustmentFactor: itemToUpdate.durationAdjustmentFactor,
                      minimumUpdatePercentage: itemToUpdate.minimumUpdatePercentage)
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
                      isOrdered: itemToUpdate.isOrdered,
                      lastUsed: itemToUpdate.lastUsed,
                      supplySize: itemToUpdate.supplySize,
                      durationAdjustmentFactor: itemToUpdate.durationAdjustmentFactor,
                      minimumUpdatePercentage: itemToUpdate.minimumUpdatePercentage)
    }
    
    func stockUp(id: UUID) async throws -> ItemDTO {
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        
        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        let items = try modelContext.fetch(descriptor)
        
        guard let itemToUpdate = items.first else {
            throw NSError(domain: "Item not found", code: 404)
        }
        
        itemToUpdate.quantity += itemToUpdate.supplySize
        itemToUpdate.isOrdered = false
        try modelContext.save()
        
        return ItemDTO(id: itemToUpdate.id, 
                      name: itemToUpdate.name, 
                      date: itemToUpdate.date, 
                      quantity: itemToUpdate.quantity, 
                      duration: itemToUpdate.duration,
                      notifyDays: itemToUpdate.notifyDays,
                      isOrdered: itemToUpdate.isOrdered,
                      lastUsed: itemToUpdate.lastUsed,
                      supplySize: itemToUpdate.supplySize,
                      durationAdjustmentFactor: itemToUpdate.durationAdjustmentFactor,
                      minimumUpdatePercentage: itemToUpdate.minimumUpdatePercentage)
    }
    
    func useItem(id: UUID, forceUse: Bool = false) async throws -> (item: ItemDTO, requiresConfirmation: Bool) {
        let predicate = #Predicate<Item> { item in
            item.id == id
        }
        
        let descriptor = FetchDescriptor<Item>(predicate: predicate)
        let items = try modelContext.fetch(descriptor)
        
        guard let itemToUpdate = items.first else {
            throw NSError(domain: "Item not found", code: 404)
        }
        
        let currentDate = Date()
        let daysSinceLastUsed = Calendar.current.dateComponents([.day], from: itemToUpdate.lastUsed, to: currentDate).day ?? 0
        
        // For testing: Also calculate hours for more precise measurement
        let hoursSinceLastUsed = Calendar.current.dateComponents([.hour], from: itemToUpdate.lastUsed, to: currentDate).hour ?? 0
        
        print("📊 UseItem Debug:")
        print("   - Item: \(itemToUpdate.name)")
        print("   - Last used: \(itemToUpdate.lastUsed)")
        print("   - Current date: \(currentDate)")
        print("   - Days since last used: \(daysSinceLastUsed)")
        print("   - Hours since last used: \(hoursSinceLastUsed)")
        print("   - Current duration: \(itemToUpdate.duration)")
        print("   - Force use: \(forceUse)")
        
        // Calculate the minimum allowed duration using the configurable percentage
        let minimumDuration = itemToUpdate.duration * itemToUpdate.minimumUpdatePercentage
        let requiresConfirmation = Double(daysSinceLastUsed) < minimumDuration && !forceUse
        
        if requiresConfirmation {
            // Return current item without changes, but indicate confirmation is needed
            return (ItemDTO(
                id: itemToUpdate.id,
                name: itemToUpdate.name,
                date: itemToUpdate.date,
                quantity: itemToUpdate.quantity,
                duration: itemToUpdate.duration,
                notifyDays: itemToUpdate.notifyDays,
                isOrdered: itemToUpdate.isOrdered,
                lastUsed: itemToUpdate.lastUsed,
                supplySize: itemToUpdate.supplySize,
                durationAdjustmentFactor: itemToUpdate.durationAdjustmentFactor,
                minimumUpdatePercentage: itemToUpdate.minimumUpdatePercentage
            ), true)
        }
        
        // Update the item
        itemToUpdate.quantity = max(0, itemToUpdate.quantity - 1)
        itemToUpdate.lastUsed = currentDate
        
        // Dynamically adjust duration using configurable adjustment factor
        // Always update duration if there's any time difference (even less than a day)
        if daysSinceLastUsed > 0 || hoursSinceLastUsed >= 1 {
            let actualDays = daysSinceLastUsed > 0 ? Double(daysSinceLastUsed) : 1.0 // Minimum 1 day for calculation
            
            // Use configurable adjustment factor
            let oldWeight = itemToUpdate.durationAdjustmentFactor
            let newWeight = 1.0 - oldWeight
            
            let newDuration = itemToUpdate.duration * oldWeight + actualDays * newWeight
            let updatedDuration = max(1.0, newDuration)
            
            print("🔄 Duration Update:")
            print("   - Days since last used: \(daysSinceLastUsed)")
            print("   - Hours since last used: \(hoursSinceLastUsed)")
            print("   - Old duration: \(itemToUpdate.duration)")
            print("   - Adjustment factor: \(oldWeight * 100)%/\(newWeight * 100)%")
            print("   - New duration: \(updatedDuration)")
            
            itemToUpdate.duration = updatedDuration
        } else {
            print("⚠️ No duration update: Not enough time passed (days: \(daysSinceLastUsed), hours: \(hoursSinceLastUsed))")
        }
        
        try modelContext.save()
        
        return (ItemDTO(
            id: itemToUpdate.id,
            name: itemToUpdate.name,
            date: itemToUpdate.date,
            quantity: itemToUpdate.quantity,
            duration: itemToUpdate.duration,
            notifyDays: itemToUpdate.notifyDays,
            isOrdered: itemToUpdate.isOrdered,
            lastUsed: itemToUpdate.lastUsed,
            supplySize: itemToUpdate.supplySize,
            durationAdjustmentFactor: itemToUpdate.durationAdjustmentFactor,
            minimumUpdatePercentage: itemToUpdate.minimumUpdatePercentage
        ), false)
    }
}
