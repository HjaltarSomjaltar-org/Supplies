import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("useSystemTheme") private var useSystemTheme = true {
        didSet { objectWillChange.send() }
    }
    @AppStorage("isDarkMode") private var isDarkMode = false {
        didSet { objectWillChange.send() }
    }
    
    var colorScheme: ColorScheme? {
        guard !useSystemTheme else { return nil }
        return isDarkMode ? .dark : .light
    }
    
    private init() {}
} 