import SwiftUI
import CoreLocation

struct HomeView: View {
    //@StateObject private var weatherManager = WeatherManager()
    @ObservedObject private var locationManager = LocationManager()
    @ObservedObject var diaryViewModel: DiaryViewModel


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
                    
//                    HStack(spacing: 5) {
//                        Image(systemName: weatherManager.conditionSymbol) // 天氣圖示
//                            .foregroundColor(.black)
//                        Text(weatherManager.temperature) // 溫度
//                            .foregroundColor(.black)
//                    }
                }
                .font(.system(size: 30, weight: .bold)) // **讓 VStack 內的文字大小統一**

                Spacer()
                Button(action: {}) {
                    Image(systemName: "gearshape.fill") // 設定按鈕
                        .foregroundColor(.black)
                }
            }
            .padding()
            Spacer()
            if let randomEntry = diaryViewModel.diaryEntries.randomElement() { // 隨機挑選一篇日記
                ZStack(alignment: .bottomTrailing) { // **白色區塊靠右**
                    // **照片背景**
                    if let imageData = randomEntry.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.width * 1.2) //  **調整圖片比例**
                            .clipped()
                            .cornerRadius(12) //  **圓角**
                    } else {
                        // **若無照片則顯示灰色背景**
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.width * 1.2) //  **調整比例**
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
            } else {
                Text("目前還沒有日記")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            Spacer()
            HStack(alignment: .top, spacing: 8) { //  **確保對齊**
                Image("guy")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40) // **手動調整與文字等高**
                    .aspectRatio(contentMode: .fit) // **保持圖片比例**
                
                Text("這幾天你很棒！前天的運動一定讓你很開心～")
                    .font(.headline)
                    .lineLimit(2) //  **確保是兩行**
                    .fixedSize(horizontal: false, vertical: true) //  **確保不會壓縮**
            }

            .padding()
        }
        .onAppear {
            Task {
                while locationManager.currentLocation == nil {
                    print("🟡 等待 GPS 位置更新...")
                    try? await Task.sleep(nanoseconds: 500_000_000) // 等待 0.5 秒
                }
                
//                if let location = locationManager.currentLocation {
//                    print("📍 成功獲取 GPS 位置: \(location.coordinate.latitude), \(location.coordinate.longitude)")
//                    await weatherManager.fetchWeather(for: location)
//                } else {
//                    print("⚠️ GPS 位置尚未獲取")
//                }
            }
        }
        .background(Theme.backgroundColor)
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
