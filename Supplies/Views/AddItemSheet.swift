import SwiftUI

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let onAdd: (String, Date, Int, Double, Int?, Date, Int, Double, Double) async throws -> Void
    
    @State private var name = ""
    @State private var date = Date()
    @State private var quantity = 1
    @State private var duration = "30"
    @State private var notifyDays: Int?
    @State private var lastUsed = Date()
    @State private var supplySize = 1
    @State private var durationAdjustmentFactor = 0.7
    @State private var minimumUpdatePercentage = 0.6
    @State private var showCustomNotification = false
    
    // Helper function to parse duration with German and English decimal separators
    private func parseDuration(_ text: String) -> Double {
        // Replace comma with dot for German locale support
        let normalizedText = text.replacingOccurrences(of: ",", with: ".")
        return Double(normalizedText) ?? 30.0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    DatePicker("Date", selection: $date)
                        .tint(.indigo)
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
                    Text("Higher adjustment factor = more conservative changes (keeps more of current duration). Lower factor = more aggressive learning from usage patterns.")
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
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            do {
                                try await onAdd(
                                    name,
                                    date,
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
                                print("Error adding item: \(error)")
                            }
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
