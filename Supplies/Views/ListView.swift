import SwiftUI
import SwiftData

struct ListView: View {
    @State private var viewModel: ItemsViewModel
    @State private var showingAddSheet = false
    @State private var selectedItem: ItemDTO?
    
    init(viewModel: ItemsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.items) { item in
                    ItemRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedItem = item
                        }
                }
                .onDelete { indexSet in
                    guard let index = indexSet.first else { return }
                    Task {
                        await viewModel.removeItem(id: viewModel.items[index].id)
                    }
                }
            }
            .navigationTitle("Your Supplies")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        HStack {
                            Text("Add supply")
                             Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddItemSheet { name, date, quantity, duration, limit in
                    await viewModel.addItem(name: name, date: date, quantity: quantity, duration: duration, limit: limit)
                }
            }
            .sheet(item: $selectedItem) { item in
                DetailView(item: item) { id, name, date, quantity, duration, limit in
                    await viewModel.updateItem(id: id, name: name, date: date, quantity: quantity, duration: duration, limit: limit)
                }
            }
        }
    }
}

// Helper view for list items
struct ItemRow: View {
    let item: ItemDTO
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                    if item.daysUntilEmpty > 14 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(item.statusColor)
                    }
                }
                Text("Quantity: \(item.quantity)")
                    .font(.subheadline)
                Text("Duration: \(item.duration) days")
                    .font(.subheadline)
                Text("Limit: \(item.limit)")
                    .font(.subheadline)
                Text("Empty on: \(item.estimatedEmptyDate.formatted())")
                    .font(.caption)
                    .foregroundColor(item.statusColor)
            }
        }
        .foregroundColor(item.isUnderLimit ? .red : .primary)
    }
}
