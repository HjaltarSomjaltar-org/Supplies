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
    let emptyDate: Date // Datum, wann das Item leer ist
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
            // Widget wird alle 15 Minuten aktualisiert
            let nextUpdate = Date().addingTimeInterval(15 * 60)
            let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    @MainActor func getTop3Items() async throws -> [WidgetItem] {
        let userDefaults = UserDefaults(suiteName: "group.supplies.com")
        guard let data = userDefaults?.data(forKey: "widgetTop3Items") else {
            print("⚠️ [Widget] Keine Daten unter 'widgetTop3Items' gefunden.")
            return []
        }
        guard let items = try? JSONDecoder().decode([WidgetItem].self, from: data) else {
            print("⚠️ [Widget] Fehler beim Decodieren der WidgetItems.")
            return []
        }
        print("✅ [Widget] Geladene Items: \(items.count)")
        return items
    }
    
    private func getPreviewItems() -> [WidgetItem] {
        return [
            WidgetItem(id: "1", name: "Toilet Paper", emptyDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!),
            WidgetItem(id: "2", name: "Coffee Beans", emptyDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!),
            WidgetItem(id: "3", name: "Dish Soap", emptyDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!)
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
    
    // Hilfsfunktion für verbleibende Tage
    private func daysLeft(until date: Date) -> Int {
        let fromDate = Calendar.current.startOfDay(for: Date())
        let toDate = Calendar.current.startOfDay(for: date)
        let components = Calendar.current.dateComponents([.day], from: fromDate, to: toDate)
        return components.day ?? 0
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            if entry.items.isEmpty {
                Text("No items available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            } else {
                ForEach(entry.items) { item in
                    Link(destination: URL(string: "supplies://edit?id=\(item.id)")!) {
                        HStack(alignment: .center) {
                            Text(item.name)
                                .font(.caption2)
                                .bold()
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("\(daysLeft(until: item.emptyDate))")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .secondary)
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(daysLeft(until: item.emptyDate) <= 7 ? .red : daysLeft(until: item.emptyDate) <= 14 ? .orange : .green)
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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

// Hinweis für die App (nicht im Widget!):
// Nach jeder Änderung an den Items in deiner App:
// import WidgetKit
// WidgetCenter.shared.reloadAllTimelines()

#Preview(as: .systemLarge) {
    widget()
} timeline: {
    SimpleEntry(date: .now, items: [
        WidgetItem(id: "1", name: "Toilet Paper", emptyDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!),
        WidgetItem(id: "2", name: "Coffee Beans", emptyDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!),
        WidgetItem(id: "3", name: "Dish Soap", emptyDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!)
    ])
    SimpleEntry(date: .now, items: [
        WidgetItem(id: "1", name: "Milk", emptyDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!),
        WidgetItem(id: "2", name: "Bread", emptyDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!),
        WidgetItem(id: "3", name: "Laundry Detergent", emptyDate: Calendar.current.date(byAdding: .day, value: 6, to: Date())!)
    ])
}
#Preview(as: .systemSmall) {
    widget()
} timeline: {
    SimpleEntry(date: .now, items: [
        WidgetItem(id: "1", name: "Toilet Paper", emptyDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!),
        WidgetItem(id: "2", name: "Coffee Beans", emptyDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!),
        WidgetItem(id: "3", name: "Dish Soap", emptyDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!)
    ])
    SimpleEntry(date: .now, items: [
        WidgetItem(id: "1", name: "Milk", emptyDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!),
        WidgetItem(id: "2", name: "Bread", emptyDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!),
        WidgetItem(id: "3", name: "Laundry Detergent", emptyDate: Calendar.current.date(byAdding: .day, value: 6, to: Date())!)
    ])
}
