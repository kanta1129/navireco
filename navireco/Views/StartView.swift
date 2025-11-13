import SwiftUI
import FirebaseAuth // Firebase Authenticationを使うためにインポート

struct StartView: View {
    @EnvironmentObject var appState: AppState // AppStateを環境オブジェクトとして受け取る

    @State private var email = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isRegistering = false // サインアップモードかログインモードか

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "location.fill.circle") // アプリのアイコン
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
                .padding(.bottom, 20)

            Text("navirecoへようこそ！")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 10)

            Text("あなたの行動を自動で記録・分析します。")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)

            // MARK: - 入力フォーム
            Group {
                TextField("メールアドレス", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none) // 自動大文字化を無効
                    .disableAutocorrection(true) // 自動修正を無効
                    .padding(.horizontal, 30)
                
                SecureField("パスワード", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 30)
            }
            .padding(.bottom, 10)

            // MARK: - ボタン (サインアップ / ログイン)
            Button(action: {
                if isRegistering {
                    signUp() // サインアップ処理
                } else {
                    signIn() // ログイン処理
                }
            }) {
                Text(isRegistering ? "新規登録" : "ログイン")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .padding(.horizontal, 30)
            }
            .padding(.bottom, 10)

            // MARK: - サインアップ/ログイン切り替え
            Button(action: {
                isRegistering.toggle() // モードを切り替える
                alertMessage = "" // アラートメッセージをクリア
            }) {
                Text(isRegistering ? "すでにアカウントをお持ちですか？ログイン" : "アカウントをお持ちでないですか？新規登録")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .padding(.bottom, 20)

            Spacer()
        }
        .alert("認証エラー", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - 認証処理 (Firebase Authentication)

    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
                print("Sign Up Error: \(error.localizedDescription)")
            } else {
                // サインアップ成功: AppStateのisAuthenticatedが自動的にtrueに更新される
                print("Sign Up Success!")
            }
        }
    }

    private func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                alertMessage = error.localizedDescription
                showingAlert = true
                print("Sign In Error: \(error.localizedDescription)")
            } else {
                // ログイン成功: AppStateのisAuthenticatedが自動的にtrueに更新される
                print("Sign In Success!")
            }
        }
    }
}

#Preview {
    StartView()
        .environmentObject(AppState()) // プレビュー用
}
