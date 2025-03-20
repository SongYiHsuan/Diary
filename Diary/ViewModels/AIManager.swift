import Foundation
import FirebaseFirestore

// MARK: - 快樂指數資料型
struct DailyHappiness: Identifiable {
    let id = UUID()
    let date: String
    let happiness: Double
}

class AIManager: ObservableObject {
    static let shared = AIManager()

    @Published var apiKey: String = ""
    @Published var aiResponse: String = "正在取得 AI 訊息..."
    
    
    private var apiKeyState: APIKeyState = .loading
    private let db = Firestore.firestore()
    
    enum APIKeyState {
        case loading
        case loaded
        case failed
    }

    private init() {
        fetchAPIKey()
    }

    func analyzeData(entries: [DiaryEntry], completion: @escaping (Result<(String, [DailyHappiness], [EmotionData], [(String, Int)], DiaryEntry?), AIError>) -> Void) {
        print("📊 [AIManager] analyzeData() 被呼叫，日記數量: \(entries.count)")

        let dispatchGroup = DispatchGroup()

        var aiResponseResult: String = ""
        var happinessDataResult: [DailyHappiness] = []
        var emotionDataResult: [EmotionData] = []
        var topWordsResult: [(String, Int)] = []
        var selectedDiaryResult: DiaryEntry?

        dispatchGroup.enter()
        analyzeAIResponse(entries: entries) { result in
            if case .success(let response) = result {
                aiResponseResult = response
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        analyzeWeeklyHappiness(entries: entries) { result in
            if case .success(let data) = result {
                happinessDataResult = data
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        analyzeEmotionProportion(entries: entries) { result in
            if case .success(let data) = result {
                emotionDataResult = data
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        analyzeTopWords(entries: entries) { result in
            if case .success(let data) = result {
                topWordsResult = data
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        selectMostPositiveDiary(entries: entries) { result in
            if case .success(let diary) = result {
                selectedDiaryResult = diary
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            print("📊 [DEBUG] analyzeData() 執行完成")
            print("📊 AI 回饋: \(aiResponseResult)")
            print("📊 快樂數據: \(happinessDataResult)")
            print("📊 情緒數據: \(emotionDataResult)")
            print("📊 最高頻詞: \(topWordsResult)")
            print("📊 重要日記: \(selectedDiaryResult?.text ?? "❌ 無")")

            if aiResponseResult.isEmpty || happinessDataResult.isEmpty || emotionDataResult.isEmpty || topWordsResult.isEmpty {
                print("❌ [DEBUG] AI 分析回傳數據部分為空，可能出錯")
            }

            completion(.success((aiResponseResult, happinessDataResult, emotionDataResult, topWordsResult, selectedDiaryResult)))
        }


    }


    
    // 從 Firebase 取得 API Key
    private func fetchAPIKey() {
        db.collection("openAI").document("api_key").getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("無法載入 API Key: \(error.localizedDescription)")
                    self.apiKeyState = .failed
                    return
                }

                if let data = document?.data(), let key = data["api_key"] as? String {
                    self.apiKey = key
                    self.apiKeyState = .loaded
                    print("成功取得 API Key: \(key)...")
                } else {
                    self.apiKeyState = .failed
                    print("無法解析 API Key")
                }
            }
        }
    }

    // 通用 AI 請求方法（可擴充不同功能）
    func fetchAIResponse(prompt: String, completion: @escaping (Result<String, AIError>) -> Void) {
        if apiKeyState == .loading {
            completion(.success("正在取得 AI 訊息..."))
            return
        }

        guard apiKeyState == .loaded, !apiKey.isEmpty else {
            print("🔥 API Key 尚未加載完成，請求被拒絕")
            completion(.failure(.apiKeyNotLoaded))
            return
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "你是一位日記分析專家，擅長分析使用者的日記並給予鼓勵與建議。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 150
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("JSON 轉換錯誤: \(error.localizedDescription)")
            completion(.failure(.invalidResponse))
            return
        }

        print("發送 API 請求中...")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print(" OpenAI API 請求錯誤: \(error.localizedDescription)")
                    completion(.failure(.invalidResponse))
                    return
                }

                guard let data = data else {
                    print("OpenAI API 回傳空數據")
                    completion(.failure(.invalidResponse))
                    return
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    print(" OpenAI API 回應: \(String(describing: json))") // 🔥 Debug JSON Response

                    if let choices = json?["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        let cleanedResponse = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("AI 回應成功: \(cleanedResponse)")
                        completion(.success(cleanedResponse))
                    } else {
                        print(" 無法解析 AI 回應")
                        completion(.failure(.invalidResponse))
                    }
                } catch {
                    print("🔥 JSON 解析錯誤: \(error.localizedDescription)")
                    completion(.failure(.invalidResponse))
                }
            }
        }
        task.resume()
    }
    // 取得每日 AI 鼓勵 (HomeView)
    func fetchDailyMessage(completion: @escaping (Result<String, AIError>) -> Void) {
        fetchAIResponse(prompt: "請給我今天的鼓勵話語,30字以內。", completion: completion)
    }
    
    //重點回顧日記
    func selectMostPositiveDiary(entries: [DiaryEntry], completion: @escaping (Result<DiaryEntry?, AIError>) -> Void) {
        guard !entries.isEmpty else {
            completion(.success(nil))
            return
        }

        let combinedText = entries.map { "日期: \($0.date ?? "")，內容: \($0.text ?? "")" }.joined(separator: "\n")

        let prompt = """
        以下是使用者過去一個月的日記，請幫我選擇 **情緒最正面且文字最多** 的日記內容：
        - 只需回傳該日記的「日期」，不要額外的說明。
        
        \(combinedText)
        """

        fetchAIResponse(prompt: prompt) { result in
            switch result {
            case .success(let responseText):
                let selectedDate = responseText.trimmingCharacters(in: .whitespacesAndNewlines)

                let selectedDiary = entries.first { $0.date == selectedDate }

                completion(.success(selectedDiary))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    //AI總回饋
    func analyzeAIResponse(entries: [DiaryEntry],completion: @escaping (Result<String, AIError>) -> Void) {
        let combinedText = entries.map { "日期\($0.date ?? "")：\($0.text ?? "")" }.joined(separator: "\n")

        let prompt = """
        你是一位專業的心理諮商師，請根據以下的日記內容，提供一段溫暖且具有建設性的回饋。
        1. 觀察到的情緒模式或行為特徵
        2. 值得肯定的正面行為或思維
        3. 可以改善的建議（如果有的話）
        4. 鼓勵的話
        5. 不用稱謂，直接給建議文字. 第一行前面要空兩格

        請用溫暖親切的語氣，連同標點符號一定要控制在90字以內。

        日記內容：
        \(combinedText)
        """

        fetchAIResponse(prompt: prompt, completion: completion)
    }

    //分析近一週快樂指數 (AnalyzeView-一週快樂指數)
    func analyzeWeeklyHappiness(entries: [DiaryEntry], completion: @escaping (Result<[DailyHappiness], AIError>) -> Void) {
        let combinedText = entries.map { "日期\($0.date ?? "")：\($0.text ?? "")" }.joined(separator: "\n")
        let prompt = """
        下面是使用者近一週的日記內容，請逐日分析「快樂指數」，每一天的快樂指數是0到100的數值。
        回傳格式一定要是：
        日期: yyyyMMdd, 快樂指數: XX
        只要純資料，不要額外解釋
        \(combinedText)
        """
        fetchAIResponse(prompt: prompt) { result in
            switch result {
            case .success(let responseText):
                let dataPoints = responseText
                    .split(separator: "\n")
                    .compactMap { line -> DailyHappiness? in
                        let parts = line.components(separatedBy: "快樂指數:")
                        guard parts.count == 2,
                              let happiness = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
                            return nil
                        }
                        let date = parts[0]
                            .replacingOccurrences(of: "日期:", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: [","])
                        return DailyHappiness(date: date, happiness: happiness)
                    }
                completion(.success(dataPoints))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    //情緒比例圓餅圖
    func analyzeEmotionProportion(entries: [DiaryEntry], completion: @escaping (Result<[EmotionData], AIError>) -> Void) {
        let combinedText = entries.map { "日期\($0.date ?? "")：\($0.text ?? "")" }.joined(separator: "\n")

        let prompt = """
        下面是使用者近一週或近一月的日記內容，請分析所有日記的整體「情緒比例」，回傳格式如下：
        快樂: 30%
        生氣: 25%
        焦慮: 15%
        悲傷: 20%
        平靜: 10%
        只要這個格式，不需要其他說明。
        \(combinedText)
        """

        fetchAIResponse(prompt: prompt) { result in
            switch result {
            case .success(let responseText):
                let data = responseText
                    .split(separator: "\n")
                    .compactMap { line -> EmotionData? in
                        let parts = line.components(separatedBy: ":")
                        guard parts.count == 2 else {
                            return nil
                        }
                        
                        let rawEmotion = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let rawPercentage = parts[1].trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "%", with: "")

                        guard let percentage = Double(rawPercentage) else {
                            return nil
                        }

                        return EmotionData(emotion: rawEmotion, percentage: percentage)
                    }
                completion(.success(data))

            case .failure(let error):
                completion(.failure(error))
            }
        }

    }

    
    func analyzeTopWords(entries: [DiaryEntry], completion: @escaping (Result<[(word: String, count: Int)], AIError>) -> Void) {
        let combinedText = entries.map { $0.text ?? "" }.joined(separator: " ")
        let prompt = """
        以下是使用者近一個月的日記內容，請統計最常出現的前三個單字，回傳格式如下：
        開心 12次
        工作 10次
        朋友 9次
        只要這個格式，不要額外解釋，也不要換行輸出其他內容。
        \(combinedText)
        """

        fetchAIResponse(prompt: prompt) { result in
            switch result {
            case .success(let responseText):
                //print("AI 回傳結果:\n\(responseText)") // 🔥 Debug：查看 AI 回應

                let words = responseText.split(separator: "\n").compactMap { line -> (word: String, count: Int)? in
                    let parts = line.split(separator: " ")
                    
                    // 確保至少有兩個部分 (單字 和 次數)
                    guard parts.count == 2 else {
                        //print("無法解析此行: \(line)")
                        return nil
                    }

                    let word = String(parts[0]).trimmingCharacters(in: .whitespaces)
                    let countString = parts[1].replacingOccurrences(of: "次", with: "")
                    
                    guard let count = Int(countString) else {
                        //print("無法轉換數字: \(countString)")
                        return nil
                    }

                    return (word, count)
                }

                if words.isEmpty {
                    //print("沒有解析出任何字詞") // Debug：如果 `words` 仍然是空的
                }

                completion(.success(words))

            case .failure(let error):
                //print("統計字詞失敗: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

}

//AI Error 定義
enum AIError: Error, LocalizedError {
    case apiKeyNotLoaded
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .apiKeyNotLoaded:
            return "尚未成功載入 API Key，請稍後再試。"
        case .invalidResponse:
            return "AI 回應格式錯誤。"
        }
    }
}

// 定義資料結構
struct EmotionData: Identifiable {
    let id = UUID()
    let emotion: String
    let percentage: Double
}


