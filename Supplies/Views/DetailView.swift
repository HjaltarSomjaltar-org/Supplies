import SwiftUI

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let item: ItemDTO
    let onUpdate: (UUID, String, Date, Int, Int, Int?) async throws -> Void
    
    @State private var name: String
    @State private var date: Date
    @State private var quantity: Int
    @State private var duration: Int
    @State private var notifyDays: Int?
    @State private var showCustomNotification: Bool
    @State private var error: Error?
    @State private var showError = false
    @State private var dateWasModified = false
    
    init(item: ItemDTO, onUpdate: @escaping (UUID, String, Date, Int, Int, Int?) async throws -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        _name = State(initialValue: item.name)
        _date = State(initialValue: item.date)
        _quantity = State(initialValue: item.quantity)
        _duration = State(initialValue: item.duration)
        _notifyDays = State(initialValue: item.notifyDays)
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
                
                Picker("Duration (days)", selection: $duration) {
                    ForEach(1...365, id: \.self) { number in
                        Text("\(number)")
                            .foregroundStyle(.indigo)
                    }
                }
                .pickerStyle(.menu)
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
    }
    
    private func updateAndDismiss() {
        Task {
            do {
                try await onUpdate(
                    item.id,
                    name,
                    dateWasModified ? date : Date(),
                    quantity,
                    duration,
                    showCustomNotification ? notifyDays : nil
                )
                dismiss()
            } catch {
                self.error = error
                self.showError = true
            }
        }
    }
} 
