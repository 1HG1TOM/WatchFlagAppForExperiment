//
//  WatchConnectivityManager.swift
//  WatchFlagAppForExperiment
//
//  Created by 萩原亜依 on 2024/09/28.
//
import WatchConnectivity
import Foundation
import SwiftUI

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    @Published var isReachable = false
    @Published var timestamps: [String] = []
    
    private var setCount: Int = 0  // セット数のカウント（初期値は0）
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // イベント名とタイムスタンプを送信する関数
    func sendTimestampWithEvent(eventName: String, timestamp: TimeInterval) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["event": eventName, "timestamp": timestamp], replyHandler: nil, errorHandler: { error in
                self.sendLogMessage("Error sending message: \(error.localizedDescription)")
            })
            self.sendLogMessage("Sent \(eventName) at \(timestamp)")
        } else {
            self.sendLogMessage("WCSession is not reachable")
        }
    }

    // MARK: - WCSessionDelegate methods
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            self.sendLogMessage("Session activation failed with error: \(error.localizedDescription)")
        } else {
            self.sendLogMessage("Session activated with state: \(activationState.rawValue)")
        }
        print("activationDidCompleteWith state= \(activationState.rawValue)")
        updateReachability()
    }
    
    func updateReachability() {
        DispatchQueue.main.async {
            self.isReachable = WCSession.default.isReachable
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        updateReachability()
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
    
    func saveTimestampsToCSV(fileName: String = "timestamps") -> Bool {
        let fileManager = FileManager.default
        
        // Documentsディレクトリのパスを取得
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        // ファイル名を指定してCSVファイルのパスを生成
        let filePath = documentsDirectory.appendingPathComponent("\(fileName).csv")
        
        // 同名のファイルが存在するか確認
        if fileManager.fileExists(atPath: filePath.path) {
            // 警告を出す (UIで行う必要がある)
            self.sendLogMessage("Warning: A file with the name \(fileName) already exists. Please choose a different name.")
            return false  // ファイル保存をキャンセル
        }
        
        // CSVファイルの内容を生成
        var csvText = "\u{FEFF}Set Count, Event, Timestamp\n"  // UTF-8 with BOM
        for timestamp in timestamps {
            csvText += "\(timestamp)\n"
        }

        self.sendLogMessage("Saving timestamps to CSV...")
        self.sendLogMessage(csvText)

        // ファイルを書き出す
        do {
            try csvText.write(to: filePath, atomically: true, encoding: .utf8)
            self.sendLogMessage("CSV file saved at: \(filePath)")
            
            // セット数を初期化
            DispatchQueue.main.async {
                self.setCount = 0
            }
            return true  // ファイル保存成功
        } catch {
            self.sendLogMessage("Failed to save CSV: \(error.localizedDescription)")
            return false  // ファイル保存失敗
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let event = message["event"] as? String, let timestamp = message["timestamp"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: timestamp)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let formattedDate = dateFormatter.string(from: date)
            
            DispatchQueue.main.async {
                // セット開始が押された場合にセット数をカウント
                if event == "セット開始" {
                    self.setCount += 1
                }
                
                // タイムスタンプとイベントを配列に保存
                let eventRecord = "\(self.setCount), \(event), \(formattedDate)"
                self.timestamps.append(eventRecord)  // @Published配列に追加

                // ログと通知
                self.sendLogMessage("Received \(event) at \(formattedDate)")
                NotificationCenter.default.post(name: Notification.Name("DidReceiveTimestamp"), object: eventRecord)
            }
        } else {
            self.sendLogMessage("No timestamp or event found in message")
        }
    }
    
    // ログメッセージをUIに送信する関数
    private func sendLogMessage(_ message: String) {
        NotificationCenter.default.post(name: Notification.Name("DidReceiveLogMessage"), object: message)
    }
}
