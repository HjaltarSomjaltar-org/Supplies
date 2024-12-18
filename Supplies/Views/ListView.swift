import SwiftUI
import SwiftData

struct ListView: View {
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case emptyDate = "Empty Date"
    }
    
    @Environment(\.colorScheme) private var colorScheme
    @Binding var itemsDTO: [ItemDTO]
    @State private var selectedItem: ItemDTO?
    @State private var showAddSheet = false
    @State private var error: Error?
    @State private var showError = false
    @State private var sortOption = SortOption.emptyDate
    
    let viewModel: ItemsViewModel
    
    var sortedItems: [ItemDTO] {
        switch sortOption {
        case .name:
            return itemsDTO.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .emptyDate:
            return itemsDTO.sorted { $0.estimatedEmptyDate < $1.estimatedEmptyDate }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            ListContent(
                items: sortedItems,
                selectedItem: $selectedItem,
                onOrderStatusChanged: updateOrderStatus,
                onDelete: deleteItem
            )
            .navigationTitle("Supplies")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        HStack {
                            Text("Add item")
                            Image(systemName: "plus")
                        }
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                Text(option.rawValue)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddItemSheet { name, date, quantity, duration, notifyDays in
                    try await addNewItem(
                        name: name,
                        date: date,
                        quantity: quantity,
                        duration: duration,
                        notifyDays: notifyDays
                    )
                }
            }
            .task {
                await getItems()
            }
            .refreshable {
                await getItems()
            }
        } detail: {
            NavigationStack {
                DetailContent(
                    selectedItem: selectedItem,
                    onUpdate: updateItem
                )
            }
        }
    }
    
    private func addNewItem(name: String, date: Date, quantity: Int, duration: Int, notifyDays: Int?) async throws {
        let newItem = try await viewModel.addItem(name: name, date: date, quantity: quantity, duration: duration, notifyDays: notifyDays)
        itemsDTO.append(newItem)
        await NotificationManager.shared.scheduleNotifications(for: newItem)
    }
    
    private func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Int, notifyDays: Int?) async throws {
        let updatedItem = try await viewModel.updateItem(
            id: id,
            name: name,
            date: date,
            quantity: quantity,
            duration: duration,
            notifyDays: notifyDays
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
    
    private func deleteItem(_ item: ItemDTO) async {
        do {
            try await viewModel.removeItem(id: item.id)
            itemsDTO.removeAll { $0.id == item.id }
        } catch {
            self.error = error
            self.showError = true
        }
    }
}

// Helper view for list items
struct ItemRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let item: ItemDTO
    let onOrderStatusChanged: (Bool) async -> Void
    let onDelete: (ItemDTO) async -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "number")
                        Text("\(item.quantity)")
                    }
                    .foregroundStyle(colorScheme == .dark ? .white : .indigo)
                    .font(.subheadline)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("\(item.daysUntilEmpty) days left")
                    }
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.8) : .secondary)
                    
                    if item.isOrdered {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Ordered")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
            
            StatusIndicator(item: item)
                .opacity(colorScheme == .dark ? 0.9 : 1.0)
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    await onDelete(item)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if item.isOrdered {
                Button {
                    Task {
                        await onOrderStatusChanged(false)
                    }
                } label: {
                    Label("Mark as Unordered", systemImage: "cart.badge.minus")
                }
                .tint(.red)
            } else {
                Button {
                    Task {
                        await onOrderStatusChanged(true)
                    }
                } label: {
                    Label("Mark as Ordered", systemImage: "cart.fill")
                }
                .tint(.blue)
            }
        }
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
                    Color(.systemIndigo).opacity(colorScheme == .dark ? 0.08 : 0.1),
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
                    }, onDelete: { item in
                        Task {
                            await onDelete(item)
                        }
                    })
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemIndigo).opacity(colorScheme == .dark ? 0.15 : 0.1))
                        .padding(.vertical, 4)
                )
                .foregroundStyle(colorScheme == .dark ? .white : .primary)
            }
            .scrollContentBackground(.hidden)
        }
    }
}

struct ListToolbar: View {
    @Binding var sortOrder: ListView.SortOption
    @Binding var showingAddSheet: Bool
    
    var body: some View {
        Group {
            Menu {
                Button("Name") {
                    sortOrder = .name
                }
                Button("Empty Date") {
                    sortOrder = .emptyDate
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
            
            Button {
                showingAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
        }
    }
}

struct DetailContent: View {
    let selectedItem: ItemDTO?
    let onUpdate: (UUID, String, Date, Int, Int, Int?) async throws -> Void
    
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
