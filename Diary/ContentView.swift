import SwiftUI

struct ContentView: View {
    @StateObject var diaryViewModel = DiaryViewModel() // 創建共享 ViewModel
    @State private var selectedTab: Int = 0 // 預設在 "首頁" 頁面

    var body: some View {
        TabView(selection: $selectedTab) { // 用 selection 控制頁面跳轉
            HomeView(diaryViewModel: diaryViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首頁")
                }
                .tag(0)

            DiaryRecordView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("日記")
                }
                .tag(1) //  "日記" 頁面標記為 1

            DiaryEditView(selectedTab: $selectedTab) //  傳入選擇的 Tab
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("新增")
                }
                .tag(2) // "新增" 頁面標記為 2

            AnalyzeView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("分析")
                }
                .tag(3)
        }
        .environmentObject(diaryViewModel) // 讓所有視圖都能存取 diaryViewModel
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
