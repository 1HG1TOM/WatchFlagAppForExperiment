//
//  FileManagerView.swift
//  WatchFlagAppForExperiment
//
//  Created by 萩原亜依 on 2024/09/28.
//

import SwiftUI

struct FileManagerView: View {
    @State private var files: [String] = []  // ファイルのリスト
    @State private var selectedFiles: Set<String> = []  // 選択したファイルを保存するSet
    @State private var showAlert = false  // ファイル削除の確認アラート
    @State private var editMode: EditMode = .inactive  // 初期状態は非アクティブ
    @State private var selectedFileForContent: String? = nil  // ファイル内容表示用
    @State private var showFileContent = false  // ファイル内容表示ビューを制御
    
    var body: some View {
        NavigationView {
            VStack {
                if files.isEmpty {
                    Text("Documentsフォルダにファイルがありません")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    List(files, id: \.self, selection: $selectedFiles) { file in
                        HStack {
                            Text(file)
                            Spacer()
                            Button(action: {
                                selectedFileForContent = file
                                showFileContent = true  // ファイル内容表示ビューを開く
                            }) {
                                Text("Open")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()  // EditButtonで編集モードに入る
                        }
                    }
                    .environment(\.editMode, $editMode)  // 初期状態は選択できない
                    
                    // 削除ボタン
                    if !selectedFiles.isEmpty {
                        Button(action: {
                            showAlert = true  // 確認アラートを表示
                        }) {
                            Text("選択したファイルを削除")
                                .foregroundColor(.red)
                        }
                        .padding()
                    }
                }
            }
            .onAppear(perform: loadFiles)  // ビューが表示されたときにファイルを読み込む
            .navigationBarTitle("ファイル管理", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("ファイル削除"),
                      message: Text("\(selectedFiles.joined(separator: ", "))を削除しますか？"),
                      primaryButton: .destructive(Text("削除")) {
                        deleteSelectedFiles()  // 選択したファイルを削除
                      },
                      secondaryButton: .cancel(Text("キャンセル")) {
                        editMode = .active  // アラートをキャンセルした場合でも編集モードを有効に
                      })
            }
            .sheet(isPresented: $showFileContent, onDismiss: {
                // シートが閉じられたときの処理（リセット）
                selectedFileForContent = nil
                showFileContent = false
            }) {
                if let selectedFileForContent = selectedFileForContent {
                    FileContentView(fileName: selectedFileForContent)  // ファイル内容を表示するビューに移動
                }
            }
        }
    }
    
    // Documentsフォルダ内のファイルを読み込む
    func loadFiles() {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            self.files = fileURLs.map { $0.lastPathComponent }
        } catch {
            print("Error loading files: \(error.localizedDescription)")
        }
    }
    
    // 選択したファイルを削除する
    func deleteSelectedFiles() {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        // ファイルの削除を行う
        for fileName in selectedFiles {
            let filePath = documentsDirectory.appendingPathComponent(fileName)
            do {
                try fileManager.removeItem(at: filePath)
            } catch {
                print("Error deleting file: \(error.localizedDescription)")
            }
        }
        
        // 削除後に選択状態をリフレッシュ
        DispatchQueue.main.async {
            selectedFiles.removeAll()  // 選択リストをクリア
            loadFiles()  // ファイルリストを更新
        }
    }
}

