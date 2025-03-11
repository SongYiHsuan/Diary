import SwiftUI
import Charts

struct AnalyzeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var diaryViewModel: DiaryViewModel

    @State private var isLoading = true
    @State private var weeklyHappinessData: [DailyHappiness] = []
    @State private var emotionData: [EmotionData] = []
    @State private var topWordsData: [(word: String, count: Int)] = []

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
                AIResponseView().frame(height: 150)
                    .padding(.horizontal)
            }

            Spacer()
             
            HStack {
                topWordsBox()
                    .frame(width: (UIScreen.main.bounds.width - 32) * 0.40, height: 140)

                Spacer().frame(width: (UIScreen.main.bounds.width - 32) * 0.02)

                emotionBox()
                    .frame(width: (UIScreen.main.bounds.width - 32) * 0.58, height: 140)
            }
            .frame(width: UIScreen.main.bounds.width - 32)
            .padding(.horizontal, 16)


             Spacer().frame(height: 18)

             weeklyChartView()
                 .frame(height: 150)
                 .padding(.horizontal, 16)
                 .padding(.top, 18)
         }
        .onAppear {
            fetchEmotionProportion()
            fetchWeeklyHappiness()
            fetchTopWords()
        }
    }
    //常用字詞
    @ViewBuilder
    private func topWordsBox() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("常用字詞")
                .font(.subheadline)
                .bold()

            if topWordsData.isEmpty {
                Text("無數據")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxHeight: .infinity, alignment: .center) // ✅ 讓「無數據」在框內置中
            } else {
                ForEach(topWordsData.prefix(3), id: \.word) { wordData in
                    Text("\(wordData.word): \(wordData.count)次")
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }

            Spacer(minLength: 0) // ✅ 確保內容不會撐高，讓兩個框高度一致
        }
        .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150) // ✅ 與圓餅圖框一致高度
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
        )
    }


    //圓餅圖區塊
    @ViewBuilder
    private func emotionBox() -> some View {
        HStack(spacing: 8) { // ✅ 讓圓餅圖與圖例有間距
            emotionPieChart()
                .frame(width: UIScreen.main.bounds.width * 0.3, height: 150) // ✅ 減小寬度，避免擠壓圖例

            VStack(alignment: .leading, spacing: 6) { // ✅ 讓圖例更清晰
                ForEach(emotionData) { data in
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorForEmotion(data.emotion))
                            .frame(width: 12, height: 12)

                        Text(data.emotion)
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading) // ✅ 確保圖例對齊
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
        )
    }
    //週快樂指數
    @ViewBuilder
    private func weeklyChartView() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Rectangle()
                    .fill(Color.teal)
                    .frame(width: 15)
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
    
    //
    @ViewBuilder
    private func AIResponseView() -> some View {
        VStack(alignment: .leading) {
                Text("近況回饋")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(width: UIScreen.main.bounds.width ,height: UIScreen.main.bounds.height/4/4,alignment: .leading)
            Text(GetAIFeedBack())
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(width: UIScreen.main.bounds.width ,height: UIScreen.main.bounds.height/4*3/4, alignment: .leading)
            }
            .padding(.top, 8)
            .padding(.leading, 8)
        
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

    private func fetchTopWords() {
        let pastMonthEntries = diaryViewModel.diaryEntries.filter { entry in
            guard let dateString = entry.date,
                  let date = dateFormatter.date(from: dateString) else { return false }
            return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
        }

        AIManager.shared.analyzeTopWords(entries: pastMonthEntries) { result in
            switch result {
            case .success(let words):
                self.topWordsData = words
            case .failure(let error):
                print("統計字詞失敗: \(error.localizedDescription)")
                self.topWordsData = []
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

}

