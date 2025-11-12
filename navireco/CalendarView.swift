//
//  CalenderView.swift
//  navireco
//
//  Created by 藤井幹太 on 2025/11/13.
//

import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date() // カレンダーで選択された日付
    @State private var showMonthlyReport = true // 月次レポートと週次レポートの切り替え

    var body: some View {
        NavigationView {
            VStack {
                // MARK: - カレンダービュー
                // DatePickerをカレンダーモードで使用
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical) // iOS 14+ でモダンなカレンダー表示
                .padding()

                Divider() // 区切り線

                // MARK: - 週/月次レポート切り替え
                Picker("レポート表示", selection: $showMonthlyReport) {
                    Text("月次").tag(true)
                    Text("週次").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // MARK: - 集計グラフ表示エリア
                // ここに月次または週次の集計グラフ（円グラフなど）を表示します
                Spacer()
                Text(showMonthlyReport ? "月次レポートのグラフ" : "週次レポートのグラフ")
                    .font(.title3)
                    .padding()
                
                // 仮のグラフ表示
                Rectangle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 150)
                    .overlay(
                        Text("集計グラフエリア")
                            .foregroundColor(.secondary)
                    )
                Spacer()
            }
            .navigationTitle("カレンダー & レポート")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CalendarView()
}
