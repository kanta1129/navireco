import SwiftUI
import FirebaseAuth // Firebase Authenticationを使うためにインポート

struct SettingsView: View {
    // AppState を環境オブジェクトとして受け取る
    // ログアウト後にisAuthenticatedが変更され、アプリのルートビューが切り替わるため必要
    @EnvironmentObject var appState: AppState
    
    //EnvironmentObjectとしてManagerを受け取る
    @EnvironmentObject var backgroundLocationManager: BackgroundLocationManager

    @State private var recordFrequency: String = "1時間ごと"
    @State private var myPlaces: [String] = ["自宅", "大学", "バイト先"]
    @State private var showingLogoutAlert = false // ログアウト確認アラートの表示状態
    @State private var isLoggingOut = false // ログアウト処理中を示すフラグ
    
    //追跡設定用のトグル状態変数
    @State private var isTrackingEnabled: Bool = true // 仮の初期値
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - 記録設定
                Section(header: Text("記録設定")) {
                    Toggle("バックグラウンドで記録", isOn: $isTrackingEnabled)
                        .onChange(of: isTrackingEnabled) { newValue in
                            if newValue {
                                print("トグルON: 監視を開始します")
                                backgroundLocationManager.startMonitoring()
                            } else {
                                print("トグルOFF: 監視を停止します")
                                backgroundLocationManager.stopMonitoring()
                            }
                        }
                    Picker("記録頻度", selection: $recordFrequency) {
                        Text("30分ごと").tag("30分ごと")
                        Text("1時間ごと").tag("1時間ごと")
                    }
                    .pickerStyle(.navigationLink)
                }

                // MARK: - 自分の場所
                Section(header: Text("自分の場所")) {
                    ForEach(myPlaces, id: \.self) { place in
                        HStack {
                            Text(place)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    Button(action: {
                        // 新しい場所の登録画面へ遷移
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("新しい場所を追加")
                        }
                    }
                }
                
                // MARK: - アカウント
                Section(header: Text("アカウント")) {
                    // ログアウトボタン
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        HStack { // HStackは残します
                            Spacer() // 左側のSpacerを追加
                            Text("ログアウト")
                                .bold() // 少し強調しても良いかもしれません
                            if isLoggingOut {
                                ProgressView()
                                    .padding(.leading, 5) // インジケーターとテキストの間に少しスペース
                            }
                            Spacer() // 右側のSpacerを追加
                        }
                    }
                    .disabled(isLoggingOut)
                    //ログアウト処理中はボタンを無効化
                }
                
                // MARK: - その他
                Section(header: Text("その他")) {
                    Text("プライバシーポリシー")
                    Text("アプリについて")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            
            // ログアウト確認アラート
            .alert("ログアウトしますか？", isPresented: $showingLogoutAlert) {
                Button("ログアウト", role: .destructive) {
                    performLogout() // ユーザーが「ログアウト」を選択したら実行
                }
                Button("キャンセル", role: .cancel) { }
            }
        }
    }

    // MARK: - ログアウト処理
    private func performLogout() {
        isLoggingOut = true // 処理開始
        do {
            try Auth.auth().signOut()
            print("ログアウト成功")
            // AppState.isAuthenticated が自動的に false になるため、
            // ここで明示的に appState.isAuthenticated = false; とする必要はない
        } catch let signOutError as NSError {
            print("ログアウトエラー: %@", signOutError)
            // エラーがあればアラートなどでユーザーに通知することもできる
        }
        isLoggingOut = false // 処理終了
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        // --- ↓↓ ここを修正 ↓↓ ---
        // プレビュー用にダミーのBackgroundLocationManagerを渡す
        // これにより、プレビュー環境でCLLocationManagerが初期化されるのを防ぐ（はず）
        .environmentObject(BackgroundLocationManager())
        // あるいは、BackgroundLocationManagerのinit()をプレビュー向けに調整するか
        // もしくは、init()内のCore Location関連のコードを遅延初期化する
        // 現状は、environmentObjectで渡すだけでも問題解決することが多いです
        // --- ↑↑ ここまで修正 ↑↑ ---
}
