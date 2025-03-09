import SwiftUI

// MARK: - 快樂指數資料型
struct DailyHappiness: Identifiable {
    let id = UUID()
    let date: String
    let happiness: Double
}

public func GetAIFeedBack() -> String
{
    let result : String = "";
    //取得近期資料
    
    //將日記丟給GPT & 取得API response
    
    //回傳
    return result;
}
