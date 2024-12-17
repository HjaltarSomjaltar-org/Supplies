# Supplies

Supplies is an iOS app for managing household items and consumables. It helps you keep track of your supplies and reminds you when it's time to reorder.

## Features

- 📱 Modern SwiftUI interface
- 📦 Track supplies with quantity and consumption rate
- 🔔 Push notifications for low stock alerts
- 📊 Automatic calculation of estimated empty date
- ✅ Order status tracking
- 🔄 Automatic sorting by name or empty date
- 💾 Persistent storage using SwiftData

## Technical Details

- Swift 6.0+
- iOS 17.0+
- SwiftUI
- SwiftData for persistence
- UserNotifications Framework

## Installation

1. Clone the repository
2. Open `Supplies.xcodeproj` in Xcode
3. Select your target device or simulator
4. Press ⌘R to build and run

## Usage

1. Tap '+' to add a new item
2. Enter name, quantity, duration, and warning limit
3. The app automatically calculates when the item will run out
4. Receive notifications when items drop below warning limit
5. Mark items as ordered to pause notifications

## Architecture

- MVVM architecture
- Dependency injection
- Protocol-oriented programming
- SwiftData for data model
- Async/await API

## License

[MIT License](LICENSE)

## Author

Marvin Polscheit