import Foundation
import Combine
import FirebaseAuth

final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool // ユーザーが認証済みかどうか

    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        // --- ↓↓ 修正箇所 ↓↓ ---
        // まず、@Publishedプロパティの初期値を直接設定し、完全に初期化を完了させる
        // Auth.auth().currentUser != nil で、現在のログイン状態を初期値とする
        _isAuthenticated = Published(initialValue: Auth.auth().currentUser != nil)
        
        // その後で、認証状態の変更リスナーを設定する
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            // selfがnilになる可能性があるので、[weak self] を使って循環参照を防ぎ、
            // 必要ならguard let self = self else { return } で安全に使う
            guard let self = self else { return } // selfがまだ存在するか確認

            DispatchQueue.main.async { // UIの更新はメインスレッドで行う
                self.isAuthenticated = (user != nil) // userがnilでなければ認証済み
                print("Auth state changed. isAuthenticated: \(self.isAuthenticated)")
                if let user = user {
                    print("Logged in user ID: \(user.uid)")
                }
            }
        }
        // --- ↑↑ 修正箇所 ↑↑ ---
    }

    deinit {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
