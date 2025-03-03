import SwiftUI
import CoreData

class DiaryViewModel: ObservableObject {
    @Published var diaryEntries: [DiaryEntry] = []
    @Published var editingEntry: DiaryEntry?



    private let context = PersistenceController.shared.context

    init() {
        fetchEntries()
    }

    func fetchEntries() {
        let request: NSFetchRequest<DiaryEntry> = DiaryEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            diaryEntries = try context.fetch(request)
        } catch {
            print("Failed to fetch diary entries: \(error)")
        }
    }

    func saveEntry(date: String, text: String, images: [UIImage]) {
        let newEntry = DiaryEntry(context: context)
        newEntry.id = UUID()
        newEntry.date = date
        newEntry.text = text

        if let image = images.first, let imageData = image.jpegData(compressionQuality: 0.8) {
            newEntry.imageData = imageData
        }

        do {
            try context.save()
            fetchEntries()
        } catch {
            print("Failed to save diary entry: \(error)")
        }
    }
    func deleteEntry(_ entry: DiaryEntry) {
        guard let index = diaryEntries.firstIndex(where: { $0.id == entry.id }) else { return }

        context.delete(diaryEntries[index]) // 刪除 Core Data 裡的資料
        diaryEntries.remove(at: index) // 更新 UI
        saveContext()
    }
    
    func updateEntry(_ entry: DiaryEntry) {
        if let index = diaryEntries.firstIndex(where: { $0.id == entry.id }) {
            diaryEntries[index] = entry
            saveContext()  // Core Data 儲存
            fetchEntries() // 重新載入
        }
    }


    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("❌ 無法儲存變更: \(error)")
        }
    }
}
