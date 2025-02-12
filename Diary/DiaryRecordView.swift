import SwiftUI

struct DiaryRecordView: View {
    @EnvironmentObject var diaryViewModel: DiaryViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(diaryViewModel.diaryEntries, id: \.id) { entry in
                    NavigationLink(destination: DiaryDetailView(entry: entry)) { //  點擊進入詳細頁面
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
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            diaryViewModel.deleteEntry(entry) //  刪除單筆日記
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                        .tint(Theme.accentColor)
                    }
                    .listRowBackground(Theme.backgroundColor) // 每行背景一致
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundColor)
            .navigationTitle("Your Memory")
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
