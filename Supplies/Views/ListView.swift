import SwiftUI
import SwiftData

struct ListView: View {
    @State private var viewModel: ItemsViewModel
    @Binding var itemsDTO: [ItemDTO]
    @State private var showingAddSheet = false
    @State private var selectedItem: ItemDTO?
    @State private var error: Error?
    @State private var showError = false
    @State private var sortOrder: SortOrder = .name
    
    enum SortOrder {
        case name
        case emptyDate
        
        var title: String {
            switch self {
            case .name: "Sort by Name"
            case .emptyDate: "Sort by Empty Date"
            }
        }
    }
    
    var sortedItems: [ItemDTO] {
        switch sortOrder {
        case .name:
            return itemsDTO.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .emptyDate:
            return itemsDTO.sorted { $0.estimatedEmptyDate < $1.estimatedEmptyDate }
        }
    }
    
    init(viewModel: ItemsViewModel, itemsDTO: Binding<[ItemDTO]>) {
        _viewModel = State(initialValue: viewModel)
        _itemsDTO = itemsDTO
    }
    
    var body: some View {
        NavigationSplitView {
            ListContent(
                items: sortedItems,
                selectedItem: $selectedItem,
                onOrderStatusChanged: updateOrderStatus,
                onDelete: { item in
                    Task {
                        try? await viewModel.removeItem(id: item.id)
                        await getItems()
                    }
                }
            )
            .navigationTitle("Your Supplies")
            .toolbar {
                ListToolbar(
                    sortOrder: $sortOrder,
                    showingAddSheet: $showingAddSheet
                )
            }
            .task {
                await getItems()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddItemSheet { name, date, quantity, duration, limit in
                    try await addNewItem(name: name, date: date, quantity: quantity, duration: duration, limit: limit)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(error?.localizedDescription ?? "Unknown error occurred")
            }
        } detail: {
            DetailContent(
                selectedItem: selectedItem,
                onUpdate: updateItem
            )
        }
    }
    
    private func addNewItem(name: String, date: Date, quantity: Int, duration: Int, limit: Int) async throws {
        let newItem = try await viewModel.addItem(name: name, date: date, quantity: quantity, duration: duration, limit: limit)
        itemsDTO.append(newItem)
        await NotificationManager.shared.scheduleNotifications(for: newItem)
    }
    
    private func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Int, limit: Int) async throws {
        let updatedItem = try await viewModel.updateItem(
            id: id,
            name: name,
            date: date,
            quantity: quantity,
            duration: duration,
            limit: limit
        )
        if let index = itemsDTO.firstIndex(where: { $0.id == id }) {
            itemsDTO[index] = updatedItem
            if !updatedItem.isOrdered {
                await NotificationManager.shared.scheduleNotifications(for: updatedItem)
            }
        }
    }
    
    private func getItems() async {
        do {
            let predicate = #Predicate<Item> { item in
                item.name != ""
            }
            itemsDTO = try await viewModel.fetchItems(with: predicate)
        } catch {
            self.error = error
            self.showError = true
        }
    }
    
    private func updateOrderStatus(_ item: ItemDTO, _ newValue: Bool) async {
        do {
            let updatedItem = try await viewModel.updateOrderStatus(id: item.id, isOrdered: newValue)
            if let index = itemsDTO.firstIndex(where: { $0.id == item.id }) {
                itemsDTO[index] = updatedItem
                
                if updatedItem.isOrdered {
                    // When marked as ordered, remove notifications
                    await NotificationManager.shared.removeNotifications(for: item.id)
                } else {
                    // When order is cancelled, reschedule notifications
                    await NotificationManager.shared.scheduleNotifications(for: updatedItem)
                }
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }
}

// Helper view for list items
struct ItemRow: View {
    let item: ItemDTO
    let onOrderStatusChanged: (Bool) async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                StatusIndicator(item: item)
            }
            
            HStack(spacing: 16) {
                Label("\(item.quantity)", systemImage: "number")
                    .foregroundStyle(.indigo.opacity(0.7))
                Label("\(item.duration) days", systemImage: "clock")
                    .foregroundStyle(.indigo.opacity(0.7))
            }
            .font(.subheadline)
            
            if item.daysUntilEmpty <= 14 {
                HStack {
                    Label("Empty on: \(item.estimatedEmptyDate.formatted(date: .abbreviated, time: .omitted))", 
                          systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(item.statusColor)
                    Spacer()
                    Button {
                        Task {
                            await onOrderStatusChanged(!item.isOrdered)
                        }
                    } label: {
                        HStack {
                            Image(systemName: item.isOrdered ? "checkmark.circle.fill" : "cart.badge.plus")
                            Text(item.isOrdered ? "Ordered" : "Order")
                        }
                        .font(.caption)
                        .frame(width: 85)
                        .foregroundStyle(item.isOrdered ? .green : .indigo)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(item.isOrdered ? Color.green.opacity(0.2) : Color.indigo.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

struct StatusIndicator: View {
    let item: ItemDTO
    
    var body: some View {
        Image(systemName: item.daysUntilEmpty > 14 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            .foregroundStyle(item.statusColor)
            .font(.title3)
    }
}

struct ListContent: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let items: [ItemDTO]
    @Binding var selectedItem: ItemDTO?
    let onOrderStatusChanged: (ItemDTO, Bool) async -> Void
    let onDelete: (ItemDTO) async -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemIndigo).opacity(colorScheme == .dark ? 0.3 : 0.1),
                    Color(.systemIndigo).opacity(colorScheme == .dark ? 0.3 : 0.1),
                    Color(.systemIndigo).opacity(colorScheme == .dark ? 0.3 : 0.1),
                    Color(.systemBackground)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
            List(items, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item, onOrderStatusChanged: { newValue in
                        Task {
                            await onOrderStatusChanged(item, newValue)
                        }
                    })
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.cardBackgroundColor)
                        .padding(.vertical, 4)
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await onDelete(item)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}

struct ListToolbar: View {
    @Binding var sortOrder: ListView.SortOrder
    @Binding var showingAddSheet: Bool
    
    var body: some View {
        Group {
            Menu {
                Button(ListView.SortOrder.name.title) {
                    sortOrder = .name
                }
                Button(ListView.SortOrder.emptyDate.title) {
                    sortOrder = .emptyDate
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
                    .foregroundStyle(.indigo)
            }
            
            Button {
                showingAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.indigo)
            }
        }
    }
}

struct DetailContent: View {
    let selectedItem: ItemDTO?
    let onUpdate: (UUID, String, Date, Int, Int, Int) async throws -> Void
    
    var body: some View {
        if let item = selectedItem {
            DetailView(item: item, onUpdate: onUpdate)
        } else {
            VStack {
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 60))
                    .foregroundStyle(.indigo.opacity(0.3))
                Text("Select an item")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
