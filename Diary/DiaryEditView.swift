import SwiftUI
import PhotosUI

struct DiaryEditView: View {
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @Binding var selectedTab: Int

    @State private var text: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var isShowingImagePicker = false
    @State private var showAlert = false
    @State private var isEditing = false

    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack {
            HStack {
                Text(currentDate)
                    .font(.title2)
                    .bold()
                Spacer()
            }
            .padding()

            ScrollView {
                VStack(spacing: 10) {
                    TextEditor(text: $text)
                        .frame(minHeight: 150)
                        .padding()
                        .background(Theme.backgroundColor)
                        .cornerRadius(10)
                        .frame(width: UIScreen.main.bounds.width - 40)

                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: UIScreen.main.bounds.width - 40)
                                .cornerRadius(10)

                            Button(action: {
                                selectedImages.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white.clipShape(Circle()))
                                    .offset(x: -10, y: 10)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding()

            HStack {
                Button {
                    isShowingImagePicker = true
                } label: {
                    Image(systemName: "camera")
                        .font(.title)
                }
                .sheet(isPresented: $isShowingImagePicker) {
                    ImagePicker(images: $selectedImages)
                }

                Spacer()

                Button(action: saveOrUpdateEntry) {
                    Image(systemName: "checkmark")
                        .font(.title)
                }
            }
            .padding()
        }
        .alert("請新增至少一張照片", isPresented: $showAlert) {
            Button("確定") {}
        }
        .background(Theme.backgroundColor)
        .onAppear {
            loadEntryIfNeeded()
        }
    }

    // MARK: - 載入日記 (編輯模式)
    private func loadEntryIfNeeded() {
        if let editingEntry = diaryViewModel.editingEntry {
            isEditing = true
            text = editingEntry.text ?? ""
            if let imageData = editingEntry.imageData, let image = UIImage(data: imageData) {
                selectedImages = [image]
            }
        } else {
            isEditing = false
            text = ""
            selectedImages = []
        }
    }

    // MARK: - 儲存或更新日記
    private func saveOrUpdateEntry() {
        guard !selectedImages.isEmpty else {
            showAlert = true
            return
        }

        if isEditing, let entry = diaryViewModel.editingEntry {
            // 編輯模式：更新
            entry.text = text
            entry.imageData = selectedImages.first?.jpegData(compressionQuality: 0.8)
            diaryViewModel.updateEntry(entry)
        } else {
            // 新增模式
            diaryViewModel.saveEntry(date: currentDate, text: text, images: selectedImages)
        }

        diaryViewModel.editingEntry = nil
        selectedTab = 1 // 回到日記列表
    }
}

// **AutoGrowingTextView**
struct AutoGrowingTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var dynamicHeight: CGFloat
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false // *防止內部滾動**
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.backgroundColor = .clear
        textView.textContainer.lineBreakMode = .byWordWrapping // **確保換行**
        textView.textContainer.widthTracksTextView = false // **讓 TextView 內容不會超過寬度**
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) //  **內邊距**
        textView.layoutManager.usesFontLeading = false // **防止行距導致的計算錯誤**
        textView.translatesAutoresizingMaskIntoConstraints = false //  **確保 Auto Layout 運作**
        textView.delegate = context.coordinator
        
        // *限制 TextView 最大寬度，確保換行**
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            if uiView.markedTextRange == nil { // *防止拼音問題**
                let maxWidth = UIScreen.main.bounds.width - 60
                let newSize = uiView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
                let newHeight = max(newSize.height, 50)

                guard dynamicHeight != newHeight else { return } // 避免越界錯誤**
                
                dynamicHeight = newHeight
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AutoGrowingTextView

        init(_ parent: AutoGrowingTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            if textView.markedTextRange == nil { // *確保拼音輸入不影響顯示**
                parent.text = textView.text
            }
        }
    }
}

// **ImagePicker（
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let uiImage = image as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.images.append(uiImage)
                        }
                    }
                }
            }
        }
    }
}


// **隱藏鍵盤**
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


// **預覽**
struct DiaryEditView_Previews: PreviewProvider {
    static var previews: some View {
        DiaryEditView(selectedTab: .constant(2)).environmentObject(DiaryViewModel())
    }
}
