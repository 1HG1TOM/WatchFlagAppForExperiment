//
//  WatchConnectivityManager.swift
//  WatchFlagAppForExperiment Watch App
//
//  Created by 萩原亜依 on 2024/09/28.
//

//
//  WatchConnectivityManager.swift
//  WatchFlagAppForExperiment Watch App
//
//  Created by 萩原亜依 on 2024/09/28.
//

import WatchConnectivity
import Foundation

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    @Published var isReachable = false
    private var timestamps: [String] = []  // タイムスタンプを保存する配列
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
        self.isReachable = WCSession.default.isReachable
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif
    
    // ファイル名を指定してCSVファイルを保存する関数
    func saveTimestampsToCSV(fileName: String = "timestamps") {
        let fileManager = FileManager.default
        
        // Documentsディレクトリのパスを取得
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        // ディレクトリが存在しない場合は作成
        do {
            if !fileManager.fileExists(atPath: documentsDirectory.path) {
                try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: nil)
                self.sendLogMessage("Documents directory created.")
            }
        } catch {
            self.sendLogMessage("Failed to create Documents directory: \(error.localizedDescription)")
            return
        }

        // ファイル名を指定してCSVファイルのパスを生成
        let filePath = documentsDirectory.appendingPathComponent("\(fileName).csv")
        
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
            setCount = 0
        } catch {
            self.sendLogMessage("Failed to save CSV: \(error.localizedDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let event = message["event"] as? String, let timestamp = message["timestamp"] as? TimeInterval {
            let date = Date(timeIntervalSince1970: timestamp)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let formattedDate = dateFormatter.string(from: date)
            
            // セット開始が押された場合にセット数をカウント
            if event == "セット開始" {
                setCount += 1
            }
            
            // タイムスタンプとイベントを配列に保存
            let eventRecord = "\(setCount), \(event), \(formattedDate)"
            timestamps.append(eventRecord)
            
            // ログと通知
            self.sendLogMessage("Received \(event) at \(formattedDate)")
            NotificationCenter.default.post(name: Notification.Name("DidReceiveTimestamp"), object: eventRecord)
        } else {
            self.sendLogMessage("No timestamp or event found in message")
        }
    }
    
    // ログメッセージをUIに送信する関数
    private func sendLogMessage(_ message: String) {
        NotificationCenter.default.post(name: Notification.Name("DidReceiveLogMessage"), object: message)
    }
}
