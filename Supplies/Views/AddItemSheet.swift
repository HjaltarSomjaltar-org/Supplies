import SwiftUI

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (String, Date, Int, Int, Int) async throws -> Void
    
    @State private var name: String = ""
    @State private var date: Date = .now
    @State private var quantity: Int = 1
    @State private var duration: Int = 7
    @State private var limit: Int = 5
    @State private var error: Error?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .padding(.vertical, 8)
                }
                .listRowBackground(Color(.systemIndigo).opacity(0.1))
                
                Section {
                    DatePicker("Start Date", selection: $date, displayedComponents: .date)
                        .tint(.indigo)
                    
                    HStack {
                        Label("Quantity", systemImage: "number")
                            .foregroundStyle(.primary)
                        Spacer()
                        HStack(spacing: 20) {
                            Button(action: { quantity = max(1, quantity - 1) }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.indigo)
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(quantity)")
                                .frame(minWidth: 40)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { quantity = min(100, quantity + 1) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.indigo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Label("Duration", systemImage: "clock")
                            .foregroundStyle(.primary)
                        Spacer()
                        HStack(spacing: 20) {
                            Button(action: { duration = max(1, duration - 1) }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.indigo)
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(duration) days")
                                .frame(minWidth: 70)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { duration = min(365, duration + 1) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.indigo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Details")
                }
                .listRowBackground(Color(.systemIndigo).opacity(0.1))
                
                Section {
                    HStack {
                        Label("Warning Limit", systemImage: "bell.badge")
                            .foregroundStyle(.primary)
                        Spacer()
                        HStack(spacing: 20) {
                            Button(action: { limit = max(1, limit - 1) }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.indigo)
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(limit)")
                                .frame(minWidth: 40)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { limit = min(100, limit + 1) }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.indigo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("You'll be notified when quantity drops below this limit")
                }
                .listRowBackground(Color(.systemIndigo).opacity(0.1))
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemIndigo).opacity(0.1),
                        Color(.systemBackground)
                    ]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .navigationTitle("Add Supply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            do {
                                try await onAdd(name, date, quantity, duration, limit)
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
}
