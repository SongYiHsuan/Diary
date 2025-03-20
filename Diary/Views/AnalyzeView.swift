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
    @State private var isDetailPresented = false  // 控制是否顯示 DiaryDetailView
    @State private var isShowingFullResponse = false // 控制近況回顧彈出視窗
    @State private var lastAnalysisDate: String = ""


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
                    .onTapGesture { // 點擊進入 DiaryDetailView
                        if let diary = selectedDiary {
                            selectedDiary = diary
                            isDetailPresented = true
                        }
                    }
                AIResponseView(sectionHeight: sectionHeight)
                    .frame(height: sectionHeight,alignment: .center)
                    .padding(.horizontal, horizontalPadding)

                HStack(spacing: 12) {
                    topWordsBox()
                        .frame(width: (UIScreen.main.bounds.width - (horizontalPadding * 2 + 12)) * 0.35) // ✅ 減去 padding + spacing

                    emotionBox(sectionHeight: sectionHeight)
                        .frame(width: (UIScreen.main.bounds.width - (horizontalPadding * 2 + 12)) * 0.65) // ✅ 減去 padding + spacing
                }
                .frame(maxWidth: .infinity) // 讓 HStack 內部元件保持置中
                .padding(.horizontal, horizontalPadding) // 確保與整體 UI 對齊
                Spacer()

                weeklyChartView()
                    .frame(height: sectionHeight,alignment: .center) //  讓開心指數緊貼底部
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, safeBottom) //  避免被 TabBar 擋住
                Spacer()

            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .onAppear {
            print("📊 [DEBUG] AnalyzeView onAppear 被觸發")
            fetchAIAnalysis(force: false)
            //fetchAIAnalysis(force: true)

            let storedHappiness = UserDefaults.standard.array(forKey: "happinessData") ?? []
            let storedEmotion = UserDefaults.standard.array(forKey: "emotionData") ?? []
            let storedTopWords = UserDefaults.standard.array(forKey: "topWordsData") ?? []
            let storedDiary = UserDefaults.standard.string(forKey: "selectedDiary") ?? "❌ 無"

            print("""
            📊 [DEBUG] 讀取 UserDefaults:
            - AI 回饋: \(UserDefaults.standard.string(forKey: "aiAnalysisResult") ?? "❌ 無")
            - 快樂數據: \(storedHappiness)
            - 情緒數據: \(storedEmotion)
            - 最高頻詞: \(storedTopWords)
            - 重要日記: \(storedDiary)
            """)

//            fetchEmotionProportion()
//            fetchWeeklyHappiness()
//            fetchTopWords()
//            selectImportantDiary()
        }

        .fullScreenCover(isPresented: $isDetailPresented) { // 跳轉到日記詳情
            if let diary = selectedDiary {
                DiaryDetailView(entry: diary)
            }
        }
    }
    
    //定期執行AI manager
    private func fetchAIAnalysis(force: Bool) {
        let today = currentDateString()
        let lastAnalysisDate = UserDefaults.standard.string(forKey: "lastAnalysisDate") ?? ""

        if lastAnalysisDate == today, !force {
            print("✅ [DEBUG] 今天的 AI 分析已載入，無需重新執行")
            return
        }

        print("📖 [DEBUG] 取得日記數據，共 \(diaryViewModel.diaryEntries.count) 篇")

        guard !diaryViewModel.diaryEntries.isEmpty else {
            print("❌ [DEBUG] 日記數據為空，AI 分析未執行")
            return
        }

        // 直接呼叫各個函數來執行分析
        fetchEmotionProportion()
        fetchWeeklyHappiness()
        fetchTopWords()
        selectImportantDiary()

        // 更新當天分析的標記，避免重複執行
        UserDefaults.standard.set(today, forKey: "lastAnalysisDate")
        print("✅ [DEBUG] AI 分析執行完成")
    }

    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
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

            // 讓白色底部區塊與圖片保持居中
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
            .frame(width: UIScreen.main.bounds.width * 0.6, height: sectionHeight * 0.8, alignment: .leading) // ✅ 讓白色區塊更對齊
            .offset(x: 0, y: -16) // ✅ 這樣不會影響總體對齊
        }
        .frame(height: sectionHeight)
    }

    //AI 近況回饋
    @ViewBuilder
    private func AIResponseView(sectionHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("近況回饋")
                .font(.subheadline)
                .foregroundColor(.black)
                .padding(.leading, 8)

            Text("\u{00A0}\u{00A0}\(aiFeedback)") // ✅ 第一行空兩格
                .font(.subheadline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(4)
                .onTapGesture {
                    isShowingFullResponse = true // 👉 開啟彈窗
                }
        }
        .padding(12)
        .frame(height: sectionHeight * 0.85)
        .background(cardBackground)
        .layoutPriority(1)
        .fullScreenCover(isPresented: $isShowingFullResponse) { // 📌 讓視窗半透明
            FullResponseView(aiFeedback: aiFeedback)
                .background(Color.clear) // ✅ 這樣讓背景不會變成灰色
        }
    }


    //近況回顧 小框框
    struct FullResponseView: View {
        let aiFeedback: String
        @Environment(\.dismiss) var dismiss // 讓使用者可以關閉視窗

        var body: some View {
            ZStack {
                // ✅ 讓背景變得更透明、更霧面
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() } // 👉 點擊背景關閉視窗

                VStack(spacing: 12) {
                    Text("完整回饋")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.top, 10)

                    ScrollView {
                        Text(aiFeedback)
                            .font(.body)
                            .foregroundColor(.black)
                            .padding()
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.3) // 限制滾動區域

                    Button("關閉") {
                        dismiss() // 👉 讓使用者關閉彈窗
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }
                .frame(width: UIScreen.main.bounds.width * 0.8, // 限制寬度 80% 螢幕
                       height: UIScreen.main.bounds.height * 0.5) // 限制高度 50% 螢幕
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding()
            }
        }
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



