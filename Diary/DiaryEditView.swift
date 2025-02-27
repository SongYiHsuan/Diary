import SwiftUI
import PhotosUI
///////
//////
///

struct DiaryEditView: View {
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @Binding var selectedTab: Int

    @State private var textBlocks: [String] = [""] // **多個輸入框**
    @State private var selectedImages: [UIImage] = []
    @State private var isShowingImagePicker = false
    @State private var showAlert = false
    @State private var textHeights: [CGFloat] = [50] //  **每個輸入框的高度**
    @State private var isClearingData = false

    
    @Environment(\.presentationMode) var presentationMode

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
                    if !isClearingData {
                        ForEach(Array(textBlocks.enumerated()), id: \.offset) { index, _ in
                            AutoGrowingTextView(text: $textBlocks[index], dynamicHeight: $textHeights[index])
                                .frame(minHeight: textHeights[index], maxHeight: .infinity)
                                .frame(width: UIScreen.main.bounds.width - 40) // **確保不超出螢幕**
                                .padding(8)
                                .background(Theme.backgroundColor)
                                .cornerRadius(10)
                                .onTapGesture {
                                    hideKeyboard()
                                }
                            
                            if index < selectedImages.count {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: selectedImages[index])
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: UIScreen.main.bounds.width - 40) //  **確保圖片不超過螢幕**
                                        .cornerRadius(10)
                                    
                                    // **刪除按鈕**
                                    Button(action: {
                                        if index < selectedImages.count {
                                            selectedImages.remove(at: index)
                                        }
                                        if index < textBlocks.count {
                                            textBlocks.remove(at: index)
                                        }
                                        if index < textHeights.count {
                                            textHeights.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .background(Color.white.clipShape(Circle()))
                                            .offset(x: -10, y: 10)
                                    }
                                    
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20) //  **確保所有內容不貼邊**
            }
            .padding()
            .onTapGesture {
                hideKeyboard()
            }

            HStack {
                Button(action: {
                    isShowingImagePicker = true
                }) {
                    Image(systemName: "camera")
                        .font(.title)
                        .foregroundColor(.black)
                }
                .sheet(isPresented: $isShowingImagePicker) {
                    ImagePicker(images: $selectedImages, textBlocks: $textBlocks, textHeights: $textHeights)
                }

                Spacer()
                Button(action: {
                    if selectedImages.isEmpty {
                        showAlert = true
                    } else {
                        diaryViewModel.saveEntry(date: currentDate, text: textBlocks.joined(separator: "\n"), images: selectedImages)
                        // 先標記正在清空，避免 UI 嘗試讀取
                        isClearingData = true

                        // 先切換 Tab，避免 UI 繼續存取 `textBlocks`
                        selectedTab = 1

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            textBlocks.removeAll()
                            textHeights.removeAll()
                            selectedImages.removeAll()

                            // 確保至少有一個輸入框**
                            textBlocks.append("")
                            textHeights.append(50)

                            // 恢復 UI
                            isClearingData = false
                        }
                    }
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.black)
                        .font(.title)
                }
            }
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text("請新增至少一張照片"), dismissButton: .default(Text("確定")))
        }
        .background(Theme.backgroundColor)
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

// **ImagePicker（支援多張照片 & 文字區塊）**
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Binding var textBlocks: [String]
    @Binding var textHeights: [CGFloat]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // 允許多張照片
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
                            self.parent.textBlocks.append("") // **每新增一張圖片，在下方新增一個輸入框**
                            self.parent.textHeights.append(50)
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
