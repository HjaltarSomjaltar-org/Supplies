//
//  widget.swift
//  widget
//
//  Created by Elias Maurer on 26.07.25.
//

import WidgetKit
import SwiftUI

// Simple widget item structure
struct WidgetItem: Identifiable, Codable {
    let id: String
    let name: String
    let daysUntilEmpty: Int
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), items: getPreviewItems())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        Task {
            let items = try await getTop3Items()
            let entry = SimpleEntry(date: Date(), items: items)
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            var entries: [SimpleEntry] = []
            
            let items = try await getTop3Items()
            let entry = SimpleEntry(date: Date(), items: items)
            entries.append(entry)
            
            let timeline = Timeline(entries: entries, policy: .after(.now.addingTimeInterval(60 * 5)))
            completion(timeline)
        }
    }
    
    @MainActor func getTop3Items() async throws -> [WidgetItem] {
        let userDefaults = UserDefaults(suiteName: "group.supplies.com")
        guard let data = userDefaults?.data(forKey: "widgetTop3Items"),
              let items = try? JSONDecoder().decode([WidgetItem].self, from: data) else {
            // Return sample data if no shared data is available
            return getPreviewItems()
        }
        return items
    }
    
    private func getPreviewItems() -> [WidgetItem] {
        return [
            WidgetItem(id: "1", name: "Toilet Paper", daysUntilEmpty: 2),
            WidgetItem(id: "2", name: "Coffee Beans", daysUntilEmpty: 5),
            WidgetItem(id: "3", name: "Dish Soap", daysUntilEmpty: 8)
        ]
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let items: [WidgetItem]
}

struct widgetEntryView: View {
    @Environment(\.colorScheme) private var colorScheme
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) { // zentriert
            if entry.items.isEmpty {
                Text("No items available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            } else {
                ForEach(entry.items) { item in
                    HStack(alignment: .center) { // zentriert
                        Text(item.name)
                            .font(.caption2)
                            .bold()
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("\(item.daysUntilEmpty)")
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .secondary)
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(item.daysUntilEmpty <= 7 ? .red : item.daysUntilEmpty <= 14 ? .orange : .green)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemIndigo).opacity(colorScheme == .dark ? 0.1 : 0.2))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // zentriert
        .containerBackground(for: .widget) {
            RadialGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(red: 51/255, green: 28/255, blue: 74/255).opacity(0.6) : Color(red: 178/255, green: 101/255, blue: 255/255).opacity(0.5),
                    colorScheme == .dark ? Color(red: 6/255, green: 3/255, blue: 6/255): .white
                ]),
                center: UnitPoint(x: 0.5, y: 1.2),
                startRadius:5,
                endRadius: 170
            )
        }
    }
}

struct widget: Widget {
    let kind: String = "widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            widgetEntryView(entry: entry)
        }
        .configurationDisplayName("Supplies Widget")
        .description("Shows the top 3 supplies with the lowest days remaining.")
    }
}

#Preview(as: .systemLarge) {
    widget()
} timeline: {
    SimpleEntry(date: .now, items: [
        WidgetItem(id: "1", name: "Toilet Paper", daysUntilEmpty: 2),
        WidgetItem(id: "2", name: "Coffee Beans", daysUntilEmpty: 5),
        WidgetItem(id: "3", name: "Dish Soap", daysUntilEmpty: 8)
    ])
    SimpleEntry(date: .now, items: [
        WidgetItem(id: "1", name: "Milk", daysUntilEmpty: 1),
        WidgetItem(id: "2", name: "Bread", daysUntilEmpty: 3),
        WidgetItem(id: "3", name: "Laundry Detergent", daysUntilEmpty: 6)
    ])
}
#Preview(as: .systemSmall) {
    widget()
} timeline: {
    SimpleEntry(date: .now, items: [
        WidgetItem(id: "1", name: "Toilet Paper", daysUntilEmpty: 2),
        WidgetItem(id: "2", name: "Coffee Beans", daysUntilEmpty: 5),
        WidgetItem(id: "3", name: "Dish Soap", daysUntilEmpty: 8)
    ])
    SimpleEntry(date: .now, items: [
        WidgetItem(id: "1", name: "Milk", daysUntilEmpty: 1),
        WidgetItem(id: "2", name: "Bread", daysUntilEmpty: 3),
        WidgetItem(id: "3", name: "Laundry Detergent", daysUntilEmpty: 6)
    ])
}
