import BackgroundTasks
import Foundation

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    var diaryViewModel: DiaryViewModel?



    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.dailyAnalysis", using: nil) { task in
            self.runDailyAnalysis(task: task as! BGAppRefreshTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.diaryReminder", using: nil) { task in
            self.handleDiaryCheck(task: task as! BGAppRefreshTask)
        }
    }

    
    
    //每日晚上十點執行通知
    func scheduleBackgroundDiaryCheck() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.diaryReminder")
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) // 每 24 小時檢查一次

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("無法排程背景任務: \(error.localizedDescription)")
        }
    }

    private func handleDiaryCheck(task: BGAppRefreshTask) {
        scheduleBackgroundDiaryCheck() // 重新排程明天的檢查

        let hasEntry = DiaryViewModel().hasEntryForToday()
        if !hasEntry {
            NotificationManager.shared.sendImmediateReminder() // 透過背景發送通知
        }

        task.setTaskCompleted(success: true)
    }
    
    ///每日半夜12點執行AI運算
    func configure(with diaryViewModel: DiaryViewModel) {
        self.diaryViewModel = diaryViewModel
        print("✅ [背景任務] diaryViewModel 已傳入，日記數量: \(diaryViewModel.diaryEntries.count)")
    }

    func scheduleDailyAnalysis() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.dailyAnalysis")
        request.earliestBeginDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) // 設定為每天凌晨12點
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("背景 AI 分析已排程，每天 00:00 執行")
        } catch {
            print("無法排程背景 AI 分析: \(error.localizedDescription)")
        }
    }

    func runDailyAnalysis(task: BGAppRefreshTask) {
        print("⏳ [背景任務] 開始執行 AI 分析")

        let today = currentDateString()
        let lastAnalysisDate = UserDefaults.standard.string(forKey: "lastAnalysisDate") ?? ""

        print("📅 [背景任務] 上次 AI 分析時間: \(lastAnalysisDate) ，今天: \(today)")

        if lastAnalysisDate == today {
            print("✅ [背景任務] 今天的 AI 分析已載入，跳過執行")
            
            // 🔥 **列出當前儲存的 AI 數據**
            let storedAnalysis = UserDefaults.standard.string(forKey: "aiAnalysisResult") ?? "❌ 無"
            let storedHappiness = UserDefaults.standard.array(forKey: "happinessData") ?? []
            let storedEmotion = UserDefaults.standard.array(forKey: "emotionData") ?? []
            let storedTopWords = UserDefaults.standard.array(forKey: "topWordsData") ?? []
            let storedDiary = UserDefaults.standard.string(forKey: "selectedDiary") ?? "❌ 無"

            print("""
            📊 [DEBUG] 目前儲存的 AI 分析結果:
            - AI 回饋: \(storedAnalysis)
            - 快樂數據: \(storedHappiness)
            - 情緒數據: \(storedEmotion)
            - 最高頻詞: \(storedTopWords)
            - 重要日記: \(storedDiary)
            """)

            task.setTaskCompleted(success: true)
            return
        }

        // 確保有日記數據
        guard let entries = diaryViewModel?.diaryEntries, !entries.isEmpty else {
            print("❌ [錯誤] diaryEntries 為空，AI 分析未執行")
            task.setTaskCompleted(success: false)
            return
        }

        print("📖 [背景任務] 取得日記數據，共 \(entries.count) 篇日記")

        AIManager.shared.analyzeData(entries: entries) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (aiResponse, happinessData, emotionData, topWords, selectedDiary)):
                    print("✅ [成功] AI 分析完成，回饋內容：\(aiResponse)")

                    UserDefaults.standard.set(aiResponse, forKey: "aiAnalysisResult")
                    UserDefaults.standard.set(happinessData, forKey: "happinessData")
                    UserDefaults.standard.set(emotionData, forKey: "emotionData")
                    UserDefaults.standard.set(topWords, forKey: "topWordsData")
                    UserDefaults.standard.set(selectedDiary?.text, forKey: "selectedDiary")
                    UserDefaults.standard.set(today, forKey: "lastAnalysisDate")  // 記錄執行日期

                    print("✅ [儲存] AI 分析結果已存入 UserDefaults")
                    
                case .failure(let error):
                    print("❌ [失敗] AI 分析錯誤: \(error.localizedDescription)")
                }
                task.setTaskCompleted(success: true)
            }
        }
    }
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }
}
