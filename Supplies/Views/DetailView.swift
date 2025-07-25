import SwiftUI

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let item: ItemDTO
    let onUpdate: (UUID, String, Date, Int, Double, Int?, Date, Int, Double, Double) async throws -> Void
    
    @State private var currentItem: ItemDTO
    @State private var name: String
    @State private var date: Date
    @State private var quantity: Int
    @State private var duration: String
    @State private var notifyDays: Int?
    @State private var lastUsed: Date
    @State private var supplySize: Int
    @State private var durationAdjustmentFactor: Double
    @State private var minimumUpdatePercentage: Double
    @State private var showCustomNotification: Bool
    @State private var error: Error?
    @State private var showError = false
    @State private var dateWasModified = false
    
    // Helper function to parse duration with German and English decimal separators
    private func parseDuration(_ text: String) -> Double {
        // Replace comma with dot for German locale support
        let normalizedText = text.replacingOccurrences(of: ",", with: ".")
        return Double(normalizedText) ?? item.duration
    }
    
    init(item: ItemDTO, onUpdate: @escaping (UUID, String, Date, Int, Double, Int?, Date, Int, Double, Double) async throws -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        _currentItem = State(initialValue: item)
        _name = State(initialValue: item.name)
        _date = State(initialValue: item.date)
        _quantity = State(initialValue: item.quantity)
        _duration = State(initialValue: String(item.duration))
        _notifyDays = State(initialValue: item.notifyDays)
        _lastUsed = State(initialValue: item.lastUsed)
        _supplySize = State(initialValue: item.supplySize)
        _durationAdjustmentFactor = State(initialValue: item.durationAdjustmentFactor)
        _minimumUpdatePercentage = State(initialValue: item.minimumUpdatePercentage)
        _showCustomNotification = State(initialValue: item.notifyDays != nil)
        _dateWasModified = State(initialValue: false)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                DatePicker("Date", selection: $date)
                    .tint(.indigo)
                    .onChange(of: date) { _, _ in
                        dateWasModified = true
                    }
            }
            .listRowBackground(Color(.systemIndigo).opacity(0.1))
            
            Section {
                Picker("Quantity", selection: $quantity) {
                    ForEach(0...100, id: \.self) { number in
                        Text("\(number)")
                            .foregroundStyle(.indigo)
                    }
                }
                .pickerStyle(.menu)
                
                VStack(alignment: .leading) {
                    Text("Duration (days)")
                        .foregroundStyle(.primary)
                    TextField("Duration", text: $duration)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                
                Picker("Supply Size", selection: $supplySize) {
                    ForEach(1...50, id: \.self) { number in
                        Text("\(number)")
                            .foregroundStyle(.indigo)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Supply Details")
            } footer: {
                Text("Supply size determines how many units to add when stocking up")
            }
            .listRowBackground(Color(.systemIndigo).opacity(0.1))
            
            Section {
                Toggle("Custom Notification", isOn: $showCustomNotification)
                    .tint(.indigo)
                
                if showCustomNotification {
                    Picker("Notify before empty", selection: Binding(
                        get: { notifyDays ?? 14 },
                        set: { notifyDays = $0 }
                    )) {
                        ForEach(1...30, id: \.self) { days in
                            Text("\(days) days")
                                .foregroundStyle(.indigo)
                        }
                    }
                    .pickerStyle(.menu)
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text(showCustomNotification ? 
                     "Custom notification when supply runs low" : 
                     "Uses default notification settings")
            }
            .listRowBackground(Color(.systemIndigo).opacity(0.1))
            
            Section {
                DatePicker("Last Used", selection: $lastUsed)
                    .tint(.indigo)
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Duration Adjustment Factor")
                        Spacer()
                        Text("\(durationAdjustmentFactor, specifier: "%.1f")")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $durationAdjustmentFactor, in: 0.1...1.0, step: 0.1)
                        .tint(.indigo)
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Minimum Update Percentage")
                        Spacer()
                        Text("\(Int(minimumUpdatePercentage * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $minimumUpdatePercentage, in: 0.1...1.0, step: 0.1)
                        .tint(.indigo)
                }
            } header: {
                Text("Usage Learning")
            } footer: {
                Text("Duration adjustment factor controls how much past usage affects duration estimates. Minimum percentage sets the threshold for duration updates.")
            }
            .listRowBackground(Color(.systemIndigo).opacity(0.1))
        }
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemIndigo).opacity(colorScheme == .dark ? 0.08 : 0.1),
                    Color(.systemBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("Edit Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    updateAndDismiss()
                }
                .disabled(name.isEmpty)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(error?.localizedDescription ?? "Unknown error occurred")
        }
        .onChange(of: item) { _, newItem in
            // Update the currentItem and state variables when the item changes
            currentItem = newItem
            name = newItem.name
            quantity = newItem.quantity
            duration = String(newItem.duration)
            notifyDays = newItem.notifyDays
            lastUsed = newItem.lastUsed
            supplySize = newItem.supplySize
            durationAdjustmentFactor = newItem.durationAdjustmentFactor
            minimumUpdatePercentage = newItem.minimumUpdatePercentage
            showCustomNotification = newItem.notifyDays != nil
            
            // Only update date if it wasn't manually modified by user
            if !dateWasModified {
                date = newItem.date
            }
        }
    }
    
    private func updateAndDismiss() {
        Task {
            do {
                try await onUpdate(
                    item.id,
                    name,
                    dateWasModified ? date : Date(),
                    quantity,
                    parseDuration(duration),
                    showCustomNotification ? notifyDays : nil,
                    lastUsed,
                    supplySize,
                    durationAdjustmentFactor,
                    minimumUpdatePercentage
                )
                dismiss()
            } catch {
                self.error = error
                self.showError = true
            }
        }
    }
} 
