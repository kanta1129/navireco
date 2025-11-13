import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    print("Firebase initialized via AppDelegate!") // 確認用ログ
    return true
  }
}

@main
struct navirecoApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var appState = AppState()
    
    //BackgroundLocationManager をここでインスタンス化
    @StateObject var backgroundLocationManager = BackgroundLocationManager()
    
    var body: some Scene {
        WindowGroup {
            
            if appState.isAuthenticated {
                TabView {
                    ContentView()
                        .tabItem { Label("マップ", systemImage: "map.fill") }
                    TimelineView()
                        .tabItem { Label("タイムライン", systemImage: "clock.fill") }
                    CalendarView()
                        .tabItem { Label("カレンダー", systemImage: "calendar") }
                    SettingsView()
                        .tabItem { Label("設定", systemImage: "gearshape.fill") }
                }
                //ログイン済みのView全体に LocationManager を渡す
                .environmentObject(backgroundLocationManager)
                .onAppear {
                    // アプリが起動/ログインしたら、常時許可をリクエスト
                    backgroundLocationManager.requestAlwaysAuthorization()
                    // 監視を開始（許可があれば自動で開始されるロジックもManager内にある）
                    backgroundLocationManager.startMonitoring()
                }
                
            } else {
                StartView()
                    .environmentObject(appState)
            }
        }
    }
}
