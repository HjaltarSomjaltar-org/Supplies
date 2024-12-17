import Foundation
import SwiftData

@Model
final class Item {
    #Index<Item>([\.id, \.name])
    #Unique<Item>([\.id])

    var id: UUID
    var name: String
    var date: Date
    var quantity: Int
    var duration: Int
    var limit: Int

    init(id: UUID, name: String, date: Date, quantity: Int, duration: Int, limit: Int) {
        self.id = id
        self.name = name
        self.date = date
        self.quantity = quantity
        self.duration = duration
        self.limit = limit
    }
}
