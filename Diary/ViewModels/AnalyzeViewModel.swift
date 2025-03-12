import SwiftUI

// MARK: - 快樂指數資料型
struct DailyHappiness: Identifiable {
    let id = UUID()
    let date: String
    let happiness: Double
}

public func GetAIFeedBack() -> String {
    var result: String = "正在分析中..."
    // 創建 DiaryViewModel 的實例
    let diaryViewModel = DiaryViewModel()
    
    // 使用實例訪問 diaryEntries
    let data = diaryViewModel.diaryEntries
    
    // 處理數據
    let semaphore = DispatchSemaphore(value: 0) // 創建信號量以等待異步調用
    AIManager.shared.analyzeFeedback(entries: data) { feedbackResult in
        switch feedbackResult {
        case .success(let feedback):
            result = feedback
        case .failure(let error):
            // 處理錯誤情況，返回錯誤信息
            result = "分析失敗: \(error.localizedDescription)"
        }
        semaphore.signal() // 發送信號表示異步調用已完成
    }
    
    semaphore.wait() // 等待異步調用完成
    return result // 返回結果
}
