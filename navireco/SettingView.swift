//
//  SettingView.swift
//  navireco
//
//  Created by 藤井幹太 on 2025/11/13.
//

import SwiftUI

struct SettingsView: View {
    @State private var recordFrequency: String = "1時間ごと" // 記録頻度
    @State private var myPlaces: [String] = ["自宅", "大学", "バイト先"] // 登録場所の仮データ

    var body: some View {
        NavigationView {
            Form { // 設定画面でよく使われるリスト形式のレイアウト
                // MARK: - 記録設定
                Section(header: Text("記録設定")) {
                    Picker("記録頻度", selection: $recordFrequency) {
                        Text("30分ごと").tag("30分ごと")
                        Text("1時間ごと").tag("1時間ごと")
                    }
                    .pickerStyle(.navigationLink) // 別画面で選択
                }

                // MARK: - 自分の場所
                Section(header: Text("自分の場所")) {
                    ForEach(myPlaces, id: \.self) { place in
                        HStack {
                            Text(place)
                            Spacer()
                            Image(systemName: "chevron.right") // 詳細への誘導
                                .foregroundColor(.secondary)
                        }
                    }
                    // 「新しい場所を追加」ボタン
                    Button(action: {
                        // 新しい場所の登録画面へ遷移
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("新しい場所を追加")
                        }
                    }
                }
                
                // MARK: - その他
                Section(header: Text("その他")) {
                    Text("プライバシーポリシー")
                    Text("アプリについて")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
