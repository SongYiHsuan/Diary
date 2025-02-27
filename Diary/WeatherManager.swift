import Foundation
import CoreLocation

@MainActor
class WeatherManager: ObservableObject {
    @Published var conditionSymbol: String = "cloud.sun"
    @Published var temperature: String = "--°C"

    private let apiKey = "40b8f97ac263d79b7f9a30da8baa5e10" // ⚠️ 請替換成你的 API Key

    /// **🔹 取得天氣資訊**
    func fetchWeather(for location: CLLocation) async {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric"
        
        guard let url = URL(string: urlString) else {
            print("❌ 無效的 URL")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let weatherResponse = try? JSONDecoder().decode(OpenWeatherResponse.self, from: data) {
                self.updateWeatherUI(weather: weatherResponse)
                print("✅ OpenWeather 取得成功: \(weatherResponse)")
            } else {
                print("❌ 無法解析天氣數據")
            }
        } catch {
            print("❌ OpenWeather API 取得失敗: \(error.localizedDescription)")
        }
    }

    /// **🔹 更新天氣 UI**
    private func updateWeatherUI(weather: OpenWeatherResponse) {
        self.temperature = "\(Int(weather.main.temp))°C"
        self.conditionSymbol = mapWeatherConditionToSymbol(weather.weather.first?.id ?? 800)
    }

    /// **🔹 天氣 ID 對應 SF Symbol**
    private func mapWeatherConditionToSymbol(_ conditionID: Int) -> String {
        switch conditionID {
        case 200...232: return "cloud.bolt.rain" // 雷雨
        case 300...321: return "cloud.drizzle"   // 毛毛雨
        case 500...531: return "cloud.rain"      // 雨天
        case 600...622: return "snow"            // 雪
        case 701...781: return "cloud.fog"       // 霧
        case 800:       return "sun.max"         // 晴天
        case 801...804: return "cloud"           // 多雲
        default:        return "cloud.sun"
        }
    }
}

/// **🔹 OpenWeather API 回應結構**
struct OpenWeatherResponse: Codable {
    let weather: [Weather]
    let main: Main
}

struct Weather: Codable {
    let id: Int
}

struct Main: Codable {
    let temp: Double
}
