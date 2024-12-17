import SwiftUI

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: ItemDTO
    let onUpdate: (UUID, String, Date, Int, Int, Int) async throws -> Void
    
    @State private var name: String
    @State private var date: Date
    @State private var quantity: Int
    @State private var duration: Int
    @State private var limit: Int
    @State private var error: Error?
    @State private var showError = false
    
    init(item: ItemDTO, onUpdate: @escaping (UUID, String, Date, Int, Int, Int) async throws -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        _name = State(initialValue: item.name)
        _date = State(initialValue: item.date)
        _quantity = State(initialValue: item.quantity)
        _duration = State(initialValue: item.duration)
        _limit = State(initialValue: item.limit)
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                DatePicker("Date", selection: $date)
                    .tint(.indigo)
            }
            .listRowBackground(Color(.systemIndigo).opacity(0.1))
            
            Section {
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
                Stepper("Duration (days): \(duration)", value: $duration, in: 1...365)
                Stepper("Limit: \(limit)", value: $limit, in: 1...100)
            }
            .listRowBackground(Color(.systemIndigo).opacity(0.1))
        }
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemIndigo).opacity(0.1)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .navigationTitle("Edit Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        do {
                            try await onUpdate(item.id, name, date, quantity, duration, limit)
                            dismiss()
                        } catch {
                            self.error = error
                            self.showError = true
                        }
                    }
                }
                .disabled(name.isEmpty)
                .foregroundStyle(.indigo)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(error?.localizedDescription ?? "Unknown error occurred")
        }
    }
} 