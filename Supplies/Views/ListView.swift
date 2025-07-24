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
    @State private var itemToDelete: ItemDTO?
    @State private var showDeleteConfirmation = false
    @State private var itemToEdit: ItemDTO?
    @State private var itemToUse: ItemDTO?
    @State private var showUseConfirmation = false
    
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
        NavigationStack {
            ListContent(
                items: sortedItems,
                selectedItem: $selectedItem,
                onOrderStatusChanged: updateOrderStatus,
                onStockUp: stockUp,
                onEdit: editItem,
                onDelete: deleteItem,
                onUse: useItem
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
                AddItemSheet { name, date, quantity, duration, notifyDays, lastUsed, supplySize, durationAdjustmentFactor, minimumUpdatePercentage in
                    try await addNewItem(name: name, date: date, quantity: quantity, duration: duration, notifyDays: notifyDays, lastUsed: lastUsed, supplySize: supplySize, durationAdjustmentFactor: durationAdjustmentFactor, minimumUpdatePercentage: minimumUpdatePercentage)
                }
            }
            .sheet(item: $itemToEdit) { item in
                NavigationStack {
                    if let currentItem = itemsDTO.first(where: { $0.id == item.id }) {
                        DetailView(item: currentItem) { id, name, date, quantity, duration, notifyDays, lastUsed, supplySize, durationAdjustmentFactor, minimumUpdatePercentage in
                            try await updateItem(id: id, name: name, date: date, quantity: quantity, duration: duration, notifyDays: notifyDays, lastUsed: lastUsed, supplySize: supplySize, durationAdjustmentFactor: durationAdjustmentFactor, minimumUpdatePercentage: minimumUpdatePercentage)
                        }
                    } else {
                        DetailView(item: item) { id, name, date, quantity, duration, notifyDays, lastUsed, supplySize, durationAdjustmentFactor, minimumUpdatePercentage in
                            try await updateItem(id: id, name: name, date: date, quantity: quantity, duration: duration, notifyDays: notifyDays, lastUsed: lastUsed, supplySize: supplySize, durationAdjustmentFactor: durationAdjustmentFactor, minimumUpdatePercentage: minimumUpdatePercentage)
                        }
                    }
                }
            }
            .alert("Delete Item", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    Task {
                        await confirmDelete()
                    }
                }
            } message: {
                if let item = itemToDelete {
                    Text("Are you sure you want to delete '\(item.name)'? This action cannot be undone.")
                }
            }
            .alert("Confirm Usage", isPresented: $showUseConfirmation) {
                Button("Cancel", role: .cancel) {
                    itemToUse = nil
                }
                Button("Use anyway", role: .destructive) {
                    Task {
                        await confirmUse()
                    }
                }
            } message: {
                if let item = itemToUse {
                    Text("You're using '\(item.name)' much earlier than expected. Are you sure you used this product?")
                }
            }
            .task {
                await getItems()
            }
            .refreshable {
                await getItems()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(error?.localizedDescription ?? "Unknown error occurred")
            }
        }
    }
    
    private func addNewItem(name: String, date: Date, quantity: Int, duration: Double, notifyDays: Int?, lastUsed: Date, supplySize: Int, durationAdjustmentFactor: Double, minimumUpdatePercentage: Double) async throws {
        let newItem = try await viewModel.addItem(name: name, date: date, quantity: quantity, duration: duration, notifyDays: notifyDays, lastUsed: lastUsed, supplySize: supplySize, durationAdjustmentFactor: durationAdjustmentFactor, minimumUpdatePercentage: minimumUpdatePercentage)
        itemsDTO.append(newItem)
        await NotificationManager.shared.scheduleNotifications(for: newItem)
    }
    
    private func updateItem(id: UUID, name: String, date: Date, quantity: Int, duration: Double, notifyDays: Int?, lastUsed: Date, supplySize: Int, durationAdjustmentFactor: Double, minimumUpdatePercentage: Double) async throws {
        let updatedItem = try await viewModel.updateItem(
            id: id,
            name: name,
            date: date,
            quantity: quantity,
            duration: duration,
            notifyDays: notifyDays,
            lastUsed: lastUsed,
            supplySize: supplySize,
            durationAdjustmentFactor: durationAdjustmentFactor,
            minimumUpdatePercentage: minimumUpdatePercentage
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
    
    private func stockUp(_ item: ItemDTO) async {
        do {
            let updatedItem = try await viewModel.stockUp(id: item.id)
            if let index = itemsDTO.firstIndex(where: { $0.id == item.id }) {
                itemsDTO[index] = updatedItem
                await NotificationManager.shared.scheduleNotifications(for: updatedItem)
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }
    
    private func deleteItem(_ item: ItemDTO) {
        itemToDelete = item
        showDeleteConfirmation = true
    }
    
    private func editItem(_ item: ItemDTO) {
        itemToEdit = item
    }
    
    private func confirmDelete() async {
        guard let item = itemToDelete else { return }
        
        do {
            try await viewModel.removeItem(id: item.id)
            itemsDTO.removeAll { $0.id == item.id }
            await NotificationManager.shared.removeNotifications(for: item.id)
        } catch {
            self.error = error
            self.showError = true
        }
        
        itemToDelete = nil
    }
    
    private func useItem(_ item: ItemDTO) async {
        do {
            let result = try await viewModel.useItem(id: item.id)
            
            if result.requiresConfirmation {
                itemToUse = item
                showUseConfirmation = true
            } else {
                if let index = itemsDTO.firstIndex(where: { $0.id == item.id }) {
                    itemsDTO[index] = result.item
                    await NotificationManager.shared.scheduleNotifications(for: result.item)
                    
                    // If edit sheet is open for this item, refresh it
                    if let editingItem = itemToEdit, editingItem.id == item.id {
                        itemToEdit = nil
                        // Small delay to allow sheet to close, then reopen with updated data
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            itemToEdit = result.item
                        }
                    }
                }
            }
        } catch {
            self.error = error
            self.showError = true
        }
    }
    
    private func confirmUse() async {
        guard let item = itemToUse else { return }
        
        do {
            let result = try await viewModel.useItem(id: item.id, forceUse: true)
            if let index = itemsDTO.firstIndex(where: { $0.id == item.id }) {
                itemsDTO[index] = result.item
                await NotificationManager.shared.scheduleNotifications(for: result.item)
                
                // If edit sheet is open for this item, refresh it
                if let editingItem = itemToEdit, editingItem.id == item.id {
                    itemToEdit = nil
                    // Small delay to allow sheet to close, then reopen with updated data
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        itemToEdit = result.item
                    }
                }
            }
        } catch {
            self.error = error
            self.showError = true
        }
        
        itemToUse = nil
    }
}

// Helper view for list items
struct ItemRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showUseButton = false
    @State private var timer: Timer?
    let item: ItemDTO
    let onOrderStatusChanged: (Bool) async -> Void
    let onStockUp: (ItemDTO) async -> Void
    let onEdit: (ItemDTO) -> Void
    let onDelete: (ItemDTO) -> Void
    let onUse: (ItemDTO) async -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
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
            }.padding(.vertical, 3)
            
            Spacer()
            
            // Animated Use Button
            ZStack {
                // Invisible larger tap area
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
            }
            .opacity(showUseButton ? 1.0 : 0.0)
            .scaleEffect(showUseButton ? 1.0 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showUseButton)
            .onTapGesture {
                guard showUseButton else { return }
                
                // Cancel timer since button is being used
                timer?.invalidate()
                timer = nil
                
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    showUseButton = false
                }
                Task {
                    await onUse(item)
                }
            }
            .padding(.trailing, 8)
            
            StatusIndicator(item: item)
                .opacity(colorScheme == .dark ? 0.9 : 1.0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showUseButton.toggle()
            }
            
            // Cancel existing timer
            timer?.invalidate()
            
            // Start new timer if button is now visible
            if showUseButton {
                timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showUseButton = false
                        }
                        timer = nil
                    }
                }
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            timer?.invalidate()
            timer = nil
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                Task {
                    await onStockUp(item)
                }
            } label: {
                Label("Stock Up +\(item.supplySize)", systemImage: "plus.circle.fill")
            }
            .tint(.green)
            
            Button {
                onEdit(item)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
            
            Button(role: .destructive) {
                onDelete(item)
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
    let onStockUp: (ItemDTO) async -> Void
    let onEdit: (ItemDTO) -> Void
    let onDelete: (ItemDTO) -> Void
    let onUse: (ItemDTO) async -> Void
    
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
                ItemRow(item: item, onOrderStatusChanged: { newValue in
                    Task {
                        await onOrderStatusChanged(item, newValue)
                    }
                }, onStockUp: { item in
                    Task {
                        await onStockUp(item)
                    }
                }, onEdit: { item in
                    onEdit(item)
                }, onDelete: { item in
                    onDelete(item)
                }, onUse: { item in
                    Task {
                        await onUse(item)
                    }
                })
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
