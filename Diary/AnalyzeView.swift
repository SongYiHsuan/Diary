import SwiftUI
import Charts

struct AnalyzeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var diaryViewModel: DiaryViewModel

    @State private var isLoading = true
    @State private var weeklyHappinessData: [DailyHappiness] = []
    @State private var emotionData: [EmotionData] = []


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
            Spacer()
            HStack {
                Spacer()  // 讓整體靠右
                HStack(spacing: 4) {  //
                    emotionPieChart()
                        .frame(width: UIScreen.main.bounds.width * 0.35, height: 150)  // 圓餅縮小一點

                    VStack(alignment: .leading, spacing: 8) {  // 圖例獨立排放
                        ForEach(emotionData) { data in
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(colorForEmotion(data.emotion))
                                    .frame(width: 12, height: 12)

                                Text(data.emotion)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .frame(width: UIScreen.main.bounds.width * 0.55, height: 150)  // 整塊50%寬
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                )
            }
            .frame(height: 150)
            .padding(.horizontal)


            
            weeklyChartView()
                .frame(height: 150)
                .padding(.horizontal)
        }
        .onAppear {
            fetchEmotionProportion()
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
    
    @ViewBuilder
    private func emotionPieChart() -> some View {
        Chart(emotionData) { data in
            SectorMark(
                angle: .value("比例", data.percentage),
                innerRadius: .ratio(0.5),
                outerRadius: .inset(5)
            )
            .foregroundStyle(colorForEmotion(data.emotion))
        }
    }
    private func fetchEmotionProportion() {
        let pastWeekEntries = diaryViewModel.diaryEntries.filter { entry in
            guard let dateString = entry.date,
                  let date = dateFormatter.date(from: dateString) else {
                return false
            }
            return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
        }

        AIManager.shared.analyzeEmotionProportion(entries: pastWeekEntries) { result in
            switch result {
            case .success(let data):
                self.emotionData = data
                self.isLoading = false
            case .failure(let error):
                print("分析失敗: \(error.localizedDescription)")
                self.emotionData = []
                self.isLoading = false
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }
    private func colorForEmotion(_ emotion: String) -> Color {
        switch emotion {
        case "快樂": return .green
        case "生氣": return .red
        case "焦慮": return .orange
        case "悲傷": return .blue
        case "平靜": return .teal
        default: return .gray
        }
    }
}

// MARK: - 快樂指數資料型
struct DailyHappiness: Identifiable {
    let id = UUID()
    let date: String
    let happiness: Double
}

