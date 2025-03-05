import SwiftUI

struct AnalyzeViewModel {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var diaryViewModel: DiaryViewModel

    @State private var isLoading = true
    @State private var weeklyHappinessData: [DailyHappiness] = []

    let allWeekDates: [String] = {
        let calendar = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"

        return (0..<7).map { offset in
            if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
                return formatter.string(from: date)
            }
            return ""
        }.reversed()
    }()

    private func fetchWeeklyHappiness() {
        let pastWeekEntries = diaryViewModel.diaryEntries.filter { entry in
            guard let dateString = entry.date else { return false }
            return allWeekDates.contains(dateString)
        }

        AIManager.shared.analyzeWeeklyHappiness(entries: pastWeekEntries) { result in
            switch result {
            case .success(let dataPoints):

                weeklyHappinessData = allWeekDates.map { date in
                    dataPoints.first(where: { $0.date == date }) ?? DailyHappiness(date: date, happiness: 0)
                }
                isLoading = false

            case .failure(let error):
                weeklyHappinessData = allWeekDates.map { date in
                    DailyHappiness(date: date, happiness: 0)
                }
                print("分析失敗: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
}

// MARK: - 快樂指數資料型
struct DailyHappiness: Identifiable {
    let id = UUID()
    let date: String
    let happiness: Double
}
