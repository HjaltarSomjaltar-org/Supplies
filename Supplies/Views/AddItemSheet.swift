import SwiftUI

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let onAdd: (String, Date, Int, Int, Int?) async throws -> Void
    
    @State private var name = ""
    @State private var date = Date()
    @State private var quantity = 1
    @State private var duration = 30
    @State private var notifyDays: Int?
    @State private var showCustomNotification = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    DatePicker("Date", selection: $date)
                        .tint(.indigo)
                }
                .listRowBackground(Color(.systemIndigo).opacity(colorScheme == .dark ? 0.15 : 0.1))
                
                Section {
                    Picker("Quantity", selection: $quantity) {
                        ForEach(0...100, id: \.self) { number in
                            Text("\(number)")
                                .foregroundStyle(.indigo)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Duration (days)", selection: $duration) {
                        ForEach(1...365, id: \.self) { number in
                            Text("\(number)")
                                .foregroundStyle(.indigo)
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Supply Details")
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
                                    duration, 
                                    showCustomNotification ? notifyDays : nil
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
