import SwiftUI
import Charts

struct AnalyzeView: View {
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


    var body: some View {
        VStack {

            if isLoading {
                ProgressView("分析中...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                weeklyChartView()
                    .frame(height: 150)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .onAppear {
            fetchWeeklyHappiness()
        }
    }

    @ViewBuilder
    private func weeklyChartView() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Rectangle()
                    .fill(Color.teal)
                    .frame(width: 15, height: 15)
                    .cornerRadius(3)
                Text("開心")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 8)
            .padding(.leading, 8)
            
            Chart(allWeekDates, id: \.self) { date in
                if let happiness = weeklyHappinessData.first(where: { $0.date == date })?.happiness {
                    BarMark(
                        x: .value("日期", formatToDisplayDate(date)),
                        y: .value("快樂指數", happiness)
                    )
                    .foregroundStyle(Color.teal)
                } else {
                    BarMark(
                        x: .value("日期", formatToDisplayDate(date)),
                        y: .value("快樂指數", 0)
                    )
                    .foregroundStyle(Color.gray.opacity(0.3))
                }
            }

        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
        )
    }

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

    private func formatToDisplayDate(_ dateString: String) -> String {
        guard let date = dateFormatter.date(from: dateString) else { return dateString }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }
}
