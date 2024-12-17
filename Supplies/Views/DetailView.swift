import SwiftUI

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: ItemDTO
    let onUpdate: (UUID, String, Date, Int, Int, Int) async -> Void
    
    @State private var name: String
    @State private var date: Date
    @State private var quantity: Int
    @State private var duration: Int
    @State private var limit: Int
    
    init(item: ItemDTO, onUpdate: @escaping (UUID, String, Date, Int, Int, Int) async -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        _name = State(initialValue: item.name)
        _date = State(initialValue: item.date)
        _quantity = State(initialValue: item.quantity)
        _duration = State(initialValue: item.duration)
        _limit = State(initialValue: item.limit)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                DatePicker("Date", selection: $date)
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
                Stepper("Duration (days): \(duration)", value: $duration, in: 1...365)
                Stepper("Limit: \(limit)", value: $limit, in: 1...100)
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await onUpdate(item.id, name, date, quantity, duration, limit)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
} 