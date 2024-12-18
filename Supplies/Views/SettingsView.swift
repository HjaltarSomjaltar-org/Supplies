import SwiftUI

struct SettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @AppStorage("notificationDays") private var notificationDays = 14
    @AppStorage("useSystemTheme") private var useSystemTheme = true
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var showNotificationHelp = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Button {
                            showNotificationHelp = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        
                        Picker("Default Notification", selection: $notificationDays) {
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
                    Text("You'll receive notifications when supplies are running low")
                }
                .listRowBackground(Color(.systemIndigo).opacity(0.1))
                
                Section {
                    Toggle(isOn: $useSystemTheme) {
                        Label("Use System Theme", systemImage: "iphone")
                    }
                    .tint(.indigo)
                    
                    if !useSystemTheme {
                        Toggle(isOn: $isDarkMode) {
                            Label("Dark Mode", systemImage: "moon.fill")
                        }
                        .tint(.indigo)
                    }
                } header: {
                    Text("Appearance")
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
            .navigationTitle("Settings")
            .sheet(isPresented: $showNotificationHelp, content: {
                NotificationHelpSheet()
                    .presentationDetents([.medium])
            })
        }
    }
}

struct NotificationHelpSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Default Setting", systemImage: "clock.badge")
                            .font(.headline)
                            .foregroundStyle(.indigo)
                        Text("The default notification setting applies to all items. You can change this value at any time.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Custom Per Item", systemImage: "bell.badge")
                            .font(.headline)
                            .foregroundStyle(.indigo)
                        Text("When adding or editing an item, you can set a custom notification time that overrides the default setting.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notification Timing", systemImage: "timer")
                            .font(.headline)
                            .foregroundStyle(.indigo)
                        Text("You'll get notified before an item runs out based on:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            BulletPoint("Quantity and duration of each item")
                            BulletPoint("Your notification preference (default or custom)")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("About Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.indigo)
                }
            }
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("•")
                .foregroundStyle(.indigo)
            Text(text)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
} 
