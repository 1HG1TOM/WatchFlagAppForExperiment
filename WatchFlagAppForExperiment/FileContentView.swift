//
//  FileContentview.swift
//  WatchFlagAppForExperiment
//
//  Created by 萩原亜依 on 2024/09/28.
//
import SwiftUI

struct FileContentView: View {
    let fileName: String
    @State private var fileContent: String = "読み込み中..."
    
    var body: some View {
        VStack {
            Text("ファイル内容: \(fileName)")
                .font(.headline)
                .padding()

            ScrollView {
                Text(fileContent)
                    .padding()
                    .multilineTextAlignment(.leading)
            }
        }
        .onAppear(perform: loadFileContent)  // ビューが表示されたときにファイル内容を読み込む
    }
    
    // ファイルの内容を読み込む
    func loadFileContent() {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            let content = try String(contentsOf: filePath, encoding: .utf8)  // UTF-8エンコーディングで読み込む
            fileContent = content
        } catch {
            fileContent = "ファイルの読み込みに失敗しました。"  // エラーメッセージを表示
        }
    }
}
