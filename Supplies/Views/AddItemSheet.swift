import SwiftUI

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, Date, Int, Int, Int) async -> Void
    
    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var quantity: Int = 1
    @State private var duration: Int = 7
    @State private var limit: Int = 5
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                DatePicker("Date", selection: $date)
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
                Stepper("Duration (days): \(duration)", value: $duration, in: 1...365)
                Stepper("Limit: \(limit)", value: $limit, in: 1...100)
            }
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
                            await onAdd(name, date, quantity, duration, limit)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
