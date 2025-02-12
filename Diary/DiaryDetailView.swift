import SwiftUI

struct DiaryDetailView: View {
    let entry: DiaryEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(formattedDate(entry.date ?? ""))
                    .font(.title)
                    .bold()
                    .foregroundColor(Theme.textColor)

                if let text = entry.text {
                    Text(text)
                        .font(.body)
                        .foregroundColor(Theme.textColor)
                        .padding()
                        .cornerRadius(10)
                }

                if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                }

                Spacer()
            }
            .padding()
        }
        .background(Theme.backgroundColor.ignoresSafeArea()) //  背景色
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
