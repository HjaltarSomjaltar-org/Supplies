import Foundation
import SwiftData

@Observable
final class ItemsViewModel: Sendable {
    private let modelContainer: ModelContainer
    private let dataHandler: DataHandler
    var items: [ItemDTO] = [ItemDTO]()
    var error: Error?
    
    init(modelContainer: ModelContainer, dataHandler: DataHandler) {
       self.modelContainer = modelContainer
       self.dataHandler = dataHandler
        Task {
            await fetchItems()
        }
    }
    
    func fetchItems() async {
        do {
            items = try await dataHandler.getItems()
        } catch {
            self.error = error
        }
    }
    
    func addItem(name: String, date: Date, quantity: Int, duration: Int, limit: Int) async {
        do {
            let newItem = try await dataHandler.addItem(name: name, date: date, quantity: quantity, duration: duration, limit: limit)
            items.append(newItem)
        } catch {
            self.error = error
        }
    }
    
    func removeItem(id: UUID) async {
        do {
            try await dataHandler.removeItem(id: id)
            items.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }
    
    func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Int, limit: Int) async {
        do {
            let updatedItem = try await dataHandler.updateItem(id: id, name: name, date: date, quantity: quantity, duration: duration, limit: limit)
            if let index = items.firstIndex(where: { $0.id == id }) {
                items[index] = updatedItem
            }
        } catch {
            self.error = error
        }
    }
} 
