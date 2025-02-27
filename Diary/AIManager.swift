import Foundation

class AIManager: ObservableObject {
    @Published var aiResponse: String = "正在分析你的日記..."

    private let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "" // API Key

    /// 觸發 AI 來產生鼓勵回應
    func fetchAIResponse(from diaryViewModel: DiaryViewModel) async {
        print(" 觸發 AI API") // 確保請求有被呼叫
        DispatchQueue.main.async {
            self.aiResponse = "正在分析新的日記..."
        }

        let last7DaysEntries = getLast7DaysEntries(from: diaryViewModel)

        //  如果沒有日記，顯示預設歡迎訊息
        guard !last7DaysEntries.isEmpty else {
            DispatchQueue.main.async {
                self.aiResponse = "妳好，歡迎使用我們的日記！"
            }
            return
        }

        let prompt = """
        你是一位溫暖友善的 AI 夥伴，你的目標是根據用戶過去 7 天的日記內容，給予一段鼓勵、積極、充滿能量的回應，並讓用戶感覺被理解與支持。
        
        這是用戶最近 7 天的日記摘要：
        \(last7DaysEntries.joined(separator: "\n"))

        請給出一段 **溫暖、正向、激勵人心** 的回應，語氣可以輕鬆有親和力，最好是有格言押韻的搭配，讓人比較有共鳴， 30 個字以內。
        """

        do {
            let response = try await sendToOpenAI(prompt: prompt)
            DispatchQueue.main.async {
                self.aiResponse = response
            }
        } catch {
            DispatchQueue.main.async {
                self.aiResponse = "AI 回應失敗，請稍後再試"
            }
        }
    }

    /// 取得過去 7 天的日記
    private func getLast7DaysEntries(from diaryViewModel: DiaryViewModel) -> [String] {
        let calendar = Calendar.current
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        return diaryViewModel.diaryEntries
            .filter { entry in
                if let entryDate = entry.date, let dateObj = parseDate(entryDate) {
                    return dateObj >= sevenDaysAgo
                }
                return false
            }
            .map { $0.text ?? "" }
    }

    /// 解析日期格式
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: dateString)
    }

    /// 發送請求到 OpenAI API，獲取 AI 生成的回應
    private func sendToOpenAI(prompt: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        let parameters: [String: Any] = [
            "model": "gpt-4o",  //  使用最新 GPT-4o
            "messages": [
                ["role": "system", "content": "你是一個友善的 AI 夥伴，請根據用戶最近 7 天的日記內容，給予鼓勵與支持。"],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 50,
            "temperature": 0.7
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: parameters)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(openAIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // 檢查 HTTP 狀態碼
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 API 回應狀態碼: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let errorMessage = "❌ OpenAI API 錯誤，狀態碼: \(httpResponse.statusCode)"
                    print(errorMessage)

                    // 嘗試解析錯誤內容
                    if let errorDetails = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print(" 錯誤內容: \(errorDetails)")
                    }

                    return errorMessage
                }
            }

            let decodedResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
            return decodedResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? "AI 生成失敗"
        } catch {
            print(" OpenAI 請求失敗: \(error.localizedDescription)")
            return "AI 回應失敗，請稍後再試"
        }
    }

    // OpenAI Chat API 回應格式
    struct OpenAIChatResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }
}
