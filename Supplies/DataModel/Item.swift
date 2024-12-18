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
    var notifyDays: Int?
    var isOrdered: Bool

    init(id: UUID, name: String, date: Date, quantity: Int, duration: Int, notifyDays: Int? = nil, isOrdered: Bool = false) {
        self.id = id
        self.name = name
        self.date = date
        self.quantity = quantity
        self.duration = duration
        self.notifyDays = notifyDays
        self.isOrdered = isOrdered
    }
}
