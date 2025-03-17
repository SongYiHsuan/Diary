import SwiftUI
import Firebase

@main
struct DiaryApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(DiaryViewModel())
        }
    }
}
