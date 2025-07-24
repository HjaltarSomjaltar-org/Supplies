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
    var duration: Double
    var notifyDays: Int?
    var isOrdered: Bool
    var lastUsed: Date
    var supplySize: Int
    var durationAdjustmentFactor: Double // 0.0 to 1.0, default 0.7 (70%)
    var minimumUpdatePercentage: Double // 0.0 to 1.0, default 0.6 (60%)

    init(id: UUID, name: String, date: Date, quantity: Int, duration: Double, notifyDays: Int? = nil, isOrdered: Bool = false, supplySize: Int = 1, durationAdjustmentFactor: Double = 0.7, minimumUpdatePercentage: Double = 0.6) {
        self.id = id
        self.name = name
        self.date = date
        self.quantity = quantity
        self.duration = duration
        self.notifyDays = notifyDays
        self.isOrdered = isOrdered
        self.lastUsed = date
        self.supplySize = supplySize
        self.durationAdjustmentFactor = durationAdjustmentFactor
        self.minimumUpdatePercentage = minimumUpdatePercentage
    }
}
