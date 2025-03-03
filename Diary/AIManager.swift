import Foundation
import FirebaseFirestore

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

    // MARK: - 從 Firebase 取得 API Key
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
                    print("成功取得 API Key: \(key.prefix(5))...")
                } else {
                    self.apiKeyState = .failed
                    print("❌ 無法解析 API Key")
                }
            }
        }
    }

    // 通用 AI 請求方法（適用於不同類型的查詢）
    func fetchAIResponse(prompt: String, completion: @escaping (Result<String, AIError>) -> Void) {
        DispatchQueue.main.async {
            if self.apiKeyState == .loading {
                completion(.success("正在取得 AI 訊息..."))
                return
            }

            guard self.apiKeyState == .loaded, !self.apiKey.isEmpty else {
                completion(.failure(.apiKeyNotLoaded))
                return
            }

            // 準備 OpenAI API 請求
            let url = URL(string: "https://api.openai.com/v1/chat/completions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let jsonPayload: [String: Any] = [
                "model": "gpt-4",
                "messages": [
                    ["role": "system", "content": "你是一個友善的 AI 助理，專門提供幫助。"],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.7,
                "max_tokens": 100
            ]

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: jsonPayload, options: [])
            } catch {
                completion(.failure(.invalidResponse))
                return
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ OpenAI API 錯誤: \(error.localizedDescription)")
                        completion(.failure(.invalidResponse))
                        return
                    }

                    guard let data = data else {
                        completion(.failure(.invalidResponse))
                        return
                    }

                    do {
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let choices = jsonResponse["choices"] as? [[String: Any]],
                           let message = choices.first?["message"] as? [String: Any],
                           let text = message["content"] as? String {
                            completion(.success(text))
                        } else {
                            completion(.failure(.invalidResponse))
                        }
                    } catch {
                        completion(.failure(.invalidResponse))
                    }
                }
            }
            task.resume()
        }
    }

    // 取得每日 AI 鼓勵訊息(homeview)
    func fetchDailyMessage(completion: @escaping (Result<String, AIError>) -> Void) {
        fetchAIResponse(prompt: "請給我今天的鼓勵話語,30字以內。", completion: completion)
    }

    // 分析日記內容（AnalyzeView）
    func analyzeDiaryContent(_ content: String, completion: @escaping (Result<String, AIError>) -> Void) {
        fetchAIResponse(prompt: "請根據以下日記分析情緒狀態並給出建議: \(content)", completion: completion)
    }
}

// AI Error 定義
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
