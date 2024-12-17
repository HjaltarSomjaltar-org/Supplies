import Foundation
import SwiftUICore

struct ItemDTO: Hashable, Equatable, Sendable, Identifiable {
    var id: UUID
    var name: String
    var date: Date
    var quantity: Int
    var duration: Int
    var limit: Int
    var isOrdered: Bool = false
    
    var isUnderLimit: Bool {
        quantity <= limit
    }
    
    var estimatedEmptyDate: Date {
        let daysUntilEmpty = quantity * duration
        return Calendar.current.date(byAdding: .day, value: daysUntilEmpty, to: date) ?? date
    }
    
    var daysUntilEmpty: Int {
        let calendar = Calendar.current
        return calendar.numberOfDaysBetween(from: Date.now, to: estimatedEmptyDate)
    }
    
    var statusColor: Color {
        if daysUntilEmpty <= 7 {
            return .red
        } else if daysUntilEmpty <= 14 {
            return .orange
        } else {
            return .green
        }
    }
    
    var textColor: Color {
        isOrdered ? .secondary : .primary
    }
    
    var secondaryColor: Color {
        isOrdered ? .secondary : .indigo.opacity(0.7)
    }
    
    var cardBackgroundColor: Color {
        if isOrdered {
            return Color(.systemGray6)
        }
        return isUnderLimit ? Color(.systemIndigo).opacity(0.1) : Color(.systemBackground)
    }
}

private extension Calendar {
    func numberOfDaysBetween(from: Date, to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        
        return numberOfDays.day ?? 0
    }
}
