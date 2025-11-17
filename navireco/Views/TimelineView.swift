import SwiftUI

struct TimelineView: View {
    
    @StateObject private var viewModel = LocationHistoryViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.locationHistory.isEmpty {
                    Text("履歴がありません")
                        .padding()
                } else {
                    // ★ 保存したデータをリスト表示
                    List(viewModel.locationHistory) { location in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(location.placeName)
                                    .font(.headline)
                                Text(location.category)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(location.date, style: .time) // 時間を表示
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("行動履歴")
            .onAppear {
                // Viewが表示されたらデータを取得
                viewModel.fetchHistory()
            }
            .toolbar {
                // 手動更新ボタン
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.fetchHistory()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// プレビュー用
struct LocationHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineView()
    }
}
