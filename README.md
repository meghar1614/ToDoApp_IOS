# TodoListApp (SwiftUI, UserDefaults)

This zip contains all Swift source files for the To-Do List app.

## How to use in Xcode

1. Open Xcode and create a new project:
   - iOS → App
   - Interface: SwiftUI
   - Language: Swift
   - Product Name: **TodoListApp**

2. After Xcode creates the project:
   - Delete the default `ContentView.swift` and `TodoListApp.swift` that Xcode generated.
   - Drag all the `.swift` files from this folder into the Xcode project navigator
     (make sure "Add to targets" for your app is checked).

3. Build & run on a simulator or device.

Features:
- Add tasks with title + optional description
- Mark as completed / pending
- Edit or delete tasks
- Data persisted locally using UserDefaults
