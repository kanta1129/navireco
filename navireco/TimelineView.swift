import SwiftUI

struct TimelineView: View {
    var body: some View {
        // NavigationViewで囲むことで、上部にタイトルバーを表示し、
        // 将来的に戻るボタンなどのナビゲーション機能を使えるようにします。
        NavigationView {
            VStack {
                // MARK: - 日付セレクター
                HStack {
                    Button(action: {
                        // 前の日へ
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text("2024年11月13日 (木)") // 現在表示している日付
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        // 次の日へ
                    }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                
                Divider() // 区切り線

                // MARK: - 行動ログタイムライン表示エリア
                // ここに0時〜24時のタイムライングラフを表示します
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(0..<24) { hour in
                            HStack {
                                Text(String(format: "%02d:00", hour)) // 時間表示 (例: 09:00)
                                    .font(.caption)
                                    .frame(width: 40, alignment: .trailing)
                                
                                // ここにその時間の行動を示す棒グラフやテキストが入ります
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 20)
                                    .overlay(
                                        Text("行動データなし") // 仮の表示
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    )
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                }
                
                Spacer() // 上にコンテンツを寄せる
            }
            .navigationTitle("行動ログ") // 画面上部のタイトル
            .navigationBarTitleDisplayMode(.inline) // タイトル表示モード
        }
    }
}

#Preview {
    TimelineView()
}
