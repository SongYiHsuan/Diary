import SwiftUI
import CoreLocation
////
//////
struct HomeView: View {
    @StateObject private var weatherManager = WeatherManager()
    @ObservedObject private var locationManager = LocationManager()
    @ObservedObject var diaryViewModel: DiaryViewModel
    
    @State private var selectedEntry: DiaryEntry? //  **存儲選中的日記**
    @AppStorage("selectedEntryID") private var selectedEntryID: String? //  存儲日記 ID（改為 String）
    @AppStorage("lastSelectedDate") private var lastSelectedDate: String? //  存儲上次選擇的日期
    @Binding var selectedTab: Int // 透過綁定來切換 TabView
    @StateObject private var aiManager = AIManager() // AI 管理器

    // 取得當前日期
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d號 EEEE"
        formatter.locale = Locale(identifier: "zh_Hant")
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack {
            // 顯示天氣資訊
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(currentDate) // 顯示日期與星期
                        .foregroundColor(.black)
                        .font(.system(size: 30, weight: .bold)) // **讓 VStack 內的文字大小統一**
                    HStack(spacing: 5) {
                        Image(systemName: weatherManager.conditionSymbol) // 天氣圖示
                            .foregroundColor(.black)
                        Text(weatherManager.temperature) // 溫度
                            .foregroundColor(.black)
                    }
                    .font(.system(size: 20, weight: .bold)) // **讓 VStack 內的文字大小統一**
                }

                Spacer()
                Button(action: {}) {
                    Image(systemName: "gearshape.fill") // 設定按鈕
                        .foregroundColor(.black)
                }
            }
            .padding()
            
            Spacer()
            
            if let randomEntry = randomEntry { //  **一天內只選擇一次**
                ZStack(alignment: .bottomTrailing) { // **白色區塊靠右**
                    // **照片背景**
                    if let imageData = randomEntry.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.width * 1.3) //  **調整圖片比例**
                            .clipped()
                            .cornerRadius(12) //  **圓角**
                    } else {
                        // **若無照片則顯示灰色背景**
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.width * 1.3) //  **調整比例**
                            .cornerRadius(15)
                    }

                    // **白色資訊區塊**
                    VStack(alignment: .leading, spacing: 5) {
                        // **日期**
                        Text(randomEntry.date ?? "無日期")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.black)

                        // **日記內容**
                        Text(randomEntry.text ?? "沒有內容")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading) // **確保換行後也靠左**
                            .lineLimit(2) //  **最多顯示兩行**

                    }
                    .padding(12)
                    .frame(width: UIScreen.main.bounds.width * 0.65, alignment: .leading) // **縮小白色區塊，使其靠右**
                    .background(Color.white)
                    .clipShape(CustomShape()) // **使用自訂形狀，右側無圓角**
                    .shadow(radius: 2)
                    .offset(x: 0, y: -10) // **靠右對齊，貼齊邊緣**
                }
                .frame(width: UIScreen.main.bounds.width * 0.9) //  **稍微大於照片尺寸**
                .cornerRadius(15) //  **調整卡片圓角**
                .shadow(radius: 3)
                .onTapGesture { //  **點擊後進入日記詳情頁**
                    selectedEntry = randomEntry
                }
            } else {
                VStack {
                    Text("目前還沒有日記")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Button(action: {
                        selectedTab = 2 //  切換到「寫日記」Tab
                    }) {
                        Text("寫下第一篇日記吧！")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }

            Spacer()
            
            //  顯示 AI 產生的鼓勵回應（如果沒日記，就顯示歡迎訊息）
            HStack(alignment: .center, spacing: 8) {
                Image("cat")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                Text(aiManager.aiResponse) // 這裡顯示 AI 回應
                    .font(.headline)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
        .onAppear {
            Task {
                //await aiManager.fetchAIResponse(from: diaryViewModel)
                while locationManager.currentLocation == nil {
                    print(" 等待 GPS 位置更新...")
                    try? await Task.sleep(nanoseconds: 500_000_000) // 等待 0.5 秒
                }
                
//                if let location = locationManager.currentLocation {
//                    print("📍 成功獲取 GPS 位置: \(location.coordinate.latitude), \(location.coordinate.longitude)")
//                    await weatherManager.fetchWeather(for: location)
//                } else {
//                    print(" GPS 位置尚未獲取")
//                }
            }
        }
//        .onChange(of: diaryViewModel.diaryEntries) { _ in
//            Task {
//                await aiManager.fetchAIResponse(from: diaryViewModel) //  監聽日記變更，重新獲取 AI 回應
//            }
//        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Theme.backgroundColor, Theme.cardBackground]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .fullScreenCover(item: $selectedEntry) { entry in //  **彈出 DiaryDetailView**
            DiaryDetailView(entry: entry)
        }
    }
    
    var randomEntry: DiaryEntry? {
        let today = currentDateString()

        //  如果今天已經選擇過，直接返回相同的日記
        if let lastDate = lastSelectedDate, lastDate == today,
           let storedID = selectedEntryID, // storedID 是 String
           let entry = diaryViewModel.diaryEntries.first(where: { $0.id?.uuidString == storedID }) {
            return entry
        }

        //  如果今天還沒選擇過，就隨機選一篇並存儲
        if let newEntry = diaryViewModel.diaryEntries.randomElement() {
            selectedEntryID = newEntry.id?.uuidString //  轉為 String 存儲
            lastSelectedDate = today
            return newEntry
        }

        return nil
    }

    //  **獲取今天的日期字串**
    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }
}


struct CustomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)) // 右上角
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // 右下角
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // 左下角
        path.addArc(center: CGPoint(x: rect.minX + 12, y: rect.maxY - 12), radius: 12, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 12))
        path.addArc(center: CGPoint(x: rect.minX + 12, y: rect.minY + 12), radius: 12, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}
