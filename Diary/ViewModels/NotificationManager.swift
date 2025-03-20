//
//  NotificationManager.swift
//  Diary
//
//  Created by 宋易軒 on 2025/3/19.
//

import UserNotifications
import Foundation

class NotificationManager {
    static let shared = NotificationManager()

    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("通知權限請求失敗: \(error.localizedDescription)")
            } else if granted {
                print("通知權限已授予")
            } else {
                print("使用者拒絕了通知權限")
            }
        }
    }

    func scheduleDailyReminder(hasEntry: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["diaryReminder"]) // 清除舊的提醒

        guard !hasEntry else { return } // 若今天已寫日記，就不發通知

        let content = UNMutableNotificationContent()
        content.title = "今天要記得打日記呦～"
        content.body = "點擊這裡來記錄你的心情！"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 22  // 設定為晚上 10 點提醒

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "diaryReminder", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("無法排程通知: \(error.localizedDescription)")
            } else {
                print("通知已排程，每天 22:00 提醒")
            }
        }
    }

    func sendImmediateReminder() { // 這個方法用於背景檢查時發送立即通知
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "今天要記得打日記呦～"
        content.body = "點擊這裡來記錄你的心情！"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false) // 立即通知
        let request = UNNotificationRequest(identifier: "diaryReminderNow", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("發送即時通知失敗: \(error.localizedDescription)")
            }
        }
    }
}
