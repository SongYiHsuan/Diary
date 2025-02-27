import SwiftUI

struct DiaryRecordView: View {
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @State private var selectedEntry: DiaryEntry? // ✅ 存儲選中的日記
    
    var body: some View {
        NavigationView {
            List {
                ForEach(diaryViewModel.diaryEntries, id: \.id) { entry in
                    HStack {
                        Text(formattedDate(entry.date ?? ""))
                            .bold()
                            .font(.title2)
                            .foregroundColor(Theme.textColor)
                            .frame(width: UIScreen.main.bounds.width * 0.25, alignment: .leading)
                        
                        VStack(alignment: .leading) {
                            Text(entry.text ?? "")
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .foregroundColor(Theme.textColor)
                                .font(.body)
                            
                            if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .contentShape(Rectangle()) // ✅ **讓整個 HStack 可點擊**
                    .onTapGesture {
                        selectedEntry = entry // ✅ **點擊後打開日記詳情**
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            diaryViewModel.deleteEntry(entry) // ✅ **刪除單筆日記**
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                        .tint(Theme.accentColor)
                    }
                    .listRowBackground(Theme.backgroundColor) // ✅ **每行背景一致**
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundColor)
            .navigationTitle("Your Memory")
        }
        .fullScreenCover(item: $selectedEntry) { entry in // ✅ **彈出 DiaryDetailView**
            DiaryDetailView(entry: entry)
        }
    }

    private func formattedDate(_ date: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyyMMdd"

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "M/dd"

        if let dateObj = inputFormatter.date(from: date) {
            return outputFormatter.string(from: dateObj)
        }
        return date
    }
}
