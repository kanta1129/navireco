import SwiftUI
import FirebaseCore
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            
        FirebaseApp.configure()
        
        let taskIdentifier = "com.kanta.PaLog.locationRefresh"
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                print("エラー: 予期しないタスク型です。")
                task.setTaskCompleted(success: false)
                return
            }
            print("バックグラウンドタスクが起動しました (登録処理より)")
            self.handleLocationRefresh(task: appRefreshTask)
        }
        return true
    }

    // 2. バックグラウンド移行時（これは残す）
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("バックグラウンドに入りました。次のタスクをスケジュールします。")
        BackgroundLocationManager.shared.scheduleLocationRefresh()
    }

    // 3. スケジュール（これは残す）
    func scheduleLocationRefresh() {
        // ロジックはManagerに移動したので、そちらを呼ぶ
        BackgroundLocationManager.shared.scheduleLocationRefresh()
    }

    // 4. タスク実行（これは残す）
    func handleLocationRefresh(task: BGAppRefreshTask) {
        
        // 次のタスクも忘れずにスケジュールする
        BackgroundLocationManager.shared.scheduleLocationRefresh()
        
        let locationManager = BackgroundLocationManager.shared
        
        task.expirationHandler = {
            print("タスクが時間切れです")
            locationManager.cancelLocationRequest()
            task.setTaskCompleted(success: false)
        }
        
        locationManager.fetchAndSaveCurrentLocation { success in
            print("位置情報取得タスク完了。成功: \(success)")
            task.setTaskCompleted(success: success)
        }
    }
}

@main
struct navirecoApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var appState = AppState()
    
    @StateObject var backgroundLocationManager = BackgroundLocationManager.shared
    
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
                }
                
            } else {
                StartView()
                    .environmentObject(appState)
            }
        }
    }
}
