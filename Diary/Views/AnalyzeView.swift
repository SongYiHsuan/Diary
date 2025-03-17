import SwiftUI
import Charts

struct AnalyzeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var diaryViewModel: DiaryViewModel

    @State private var isLoading = true
    @State private var weeklyHappinessData: [DailyHappiness] = []
    @State private var emotionData: [EmotionData] = []
    @State private var topWordsData: [(word: String, count: Int)] = []
    @State private var aiFeedback: String = "正在取得 AI 訊息..."
    @State private var selectedDiary: DiaryEntry?  // 重要回顧日記
    private let verticalSpacing: CGFloat = 12
    private let horizontalPadding: CGFloat = 16


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
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let safeBottom = geometry.safeAreaInsets.bottom  // 確保不會超出底部
            let tabBarHeight: CGFloat = 0  // 根據 `safeBottom` 估算 TabBar
            let topPadding: CGFloat = geometry.safeAreaInsets.top  // 加入頂部安全區域
            let totalPadding: CGFloat = topPadding + tabBarHeight
            let availableHeight = screenHeight - totalPadding - (verticalSpacing * 3)  // 扣掉 TabBar、高度間距
            let sectionHeight = availableHeight / 4  // 讓四個報表均分

            VStack(spacing: verticalSpacing) {
                Spacer()
                importantReviewBox(sectionHeight: sectionHeight)
                    .frame(height: sectionHeight,alignment: .center)
                    .padding(.horizontal, horizontalPadding)
                AIResponseView(sectionHeight: sectionHeight)
                    .frame(height: sectionHeight,alignment: .center)
                    .padding(.horizontal, horizontalPadding)

                HStack(spacing: 12) {
                    topWordsBox()
                        .frame(maxWidth: .infinity) // 讓 Box 平均分配
                        .frame(width: (UIScreen.main.bounds.width - 32) * 0.35)

                    emotionBox(sectionHeight: sectionHeight)
                        .frame(maxWidth: .infinity) // 讓 Box 平均分配
                        .frame(width: (UIScreen.main.bounds.width - 32) * 0.65)
                }
                .frame(maxWidth: .infinity, alignment: .center) //  讓 HStack 置中
                .padding(.horizontal, horizontalPadding)


                weeklyChartView()
                    .frame(height: sectionHeight,alignment: .center) //  讓開心指數緊貼底部
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, safeBottom) //  避免被 TabBar 擋住

                Spacer()

            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .onAppear {
            fetchEmotionProportion()
            fetchWeeklyHappiness()
            fetchTopWords()
            fetchAIResponse()
            selectImportantDiary()
        }
    }
    
    //重要回顧
    @ViewBuilder
    private func importantReviewBox(sectionHeight: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) { 
            if let selectedDiary = selectedDiary, let imageData = selectedDiary.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: sectionHeight)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: sectionHeight)
                    .foregroundColor(.gray)
            }
            
            //半透明白色底部 + 文字
            HStack {
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDiary?.date ?? "無日期")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.black)

                    Text(selectedDiary?.text ?? "沒有符合條件的日記")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(4)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.6, alignment: .leading)
                }
                .padding(8)
                .background(
                    Rectangle()
                        .fill(Color.white)
                        .shadow(radius: 3)
                )
            }
            .frame(width: UIScreen.main.bounds.width * 0.7,height: sectionHeight * 0.8, alignment: .leading)
            .offset(x: 0, y: -16)
        }
        .frame(height: sectionHeight) //
        .cornerRadius(12)
    }

    // **AI 近況回饋**
    @ViewBuilder
    private func AIResponseView(sectionHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("近況回饋")
                .font(.subheadline)
                .foregroundColor(.black)
                .padding(.leading, 8)

            Text(aiFeedback)
                .font(.subheadline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(4)
        }
        .frame(height: sectionHeight * 0.85)
        .background(cardBackground)
        .layoutPriority(1)
    }


    // **常用字詞**
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
                    .frame(maxHeight: .infinity, alignment: .center)
            } else {
                ForEach(topWordsData.prefix(3), id: \.word) { wordData in
                    Text("\(wordData.word): \(wordData.count)次")
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(cardBackground)
    }


    //圓餅圖
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

    // **圓餅圖**
    @ViewBuilder
    private func emotionBox(sectionHeight: CGFloat) -> some View {
        HStack {
            emotionPieChart()
                .frame(width: sectionHeight * 0.8, height: sectionHeight * 0.8)

            VStack(alignment: .leading, spacing: 6) {
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

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(cardBackground)
    }

    // **週快樂指數**
    @ViewBuilder
    private func weeklyChartView() -> some View {
        VStack(alignment: .leading) {
            HStack {
                Rectangle()
                    .fill(Color.teal)
                    .frame(width: 10, height: 10) 
                    .cornerRadius(2)

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
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    // **通用卡片背景**
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white)
            .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
    }
    //選擇「情緒最正面且文字最多」的日記
    private func selectImportantDiary() {
        let pastMonthEntries = diaryViewModel.diaryEntries.filter { entry in
            guard let dateString = entry.date,
                  let date = dateFormatter.date(from: dateString) else { return false }
            return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
        }

        guard !pastMonthEntries.isEmpty else {
            self.selectedDiary = nil
            return
        }

        AIManager.shared.selectMostPositiveDiary(entries: pastMonthEntries) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let diary):
                    self.selectedDiary = diary
                case .failure:
                    self.selectedDiary = nil
                }
            }
        }
    }

    
    //AI回饋函示
    private func fetchAIResponse() {
        AIManager.shared.analyzeAIResponse(entries: diaryViewModel.diaryEntries) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let responseText):
                    self.aiFeedback = responseText
                case .failure(let error):
                    self.aiFeedback = "AI 回應失敗: \(error.localizedDescription)" // 失敗時顯示錯誤
                }
                self.isLoading = false
            }
        }
    }


    //週快樂指數函式
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
    
    private func fetchEmotionProportion() {
        let pastWeekEntries = diaryViewModel.diaryEntries.filter { entry in
            guard let dateString = entry.date,
                  let date = dateFormatter.date(from: dateString) else {
                return false
            }
            return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
        }

        AIManager.shared.analyzeEmotionProportion(entries: pastWeekEntries) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    print("取得情緒比例數據: \(data)")  // 🔥 Debug：確認數據是否有資料
                    self.emotionData = data
                    self.isLoading = false
                case .failure(let error):
                    print("分析失敗: \(error.localizedDescription)")
                    self.emotionData = [] // 確保 UI 不會當掉
                    self.isLoading = false
                }
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



