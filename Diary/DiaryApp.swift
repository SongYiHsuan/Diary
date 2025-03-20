import SwiftUI
import Firebase
import BackgroundTasks

@main
struct DiaryApp: App {
    @StateObject var diaryViewModel = DiaryViewModel()

    init() {
        FirebaseApp.configure()

        // ✅ 立即註冊背景任務，確保 App 啟動時已註冊
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(diaryViewModel)
                .onAppear {
                    // 確保在 onAppear 時傳遞 ViewModel
                    BackgroundTaskManager.shared.configure(with: diaryViewModel)

                    NotificationManager.shared.requestNotificationPermission()
                    
                    let hasEntry = diaryViewModel.hasEntryForToday()
                    NotificationManager.shared.scheduleDailyReminder(hasEntry: hasEntry)
                    
                    // ✅ 在 onAppear 時安排每日 AI 分析，確保背景執行
                    BackgroundTaskManager.shared.scheduleDailyAnalysis()
                }
        }
    }
}

