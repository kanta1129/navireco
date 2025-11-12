import SwiftUI

@main
struct navirecoApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                // 1. マップ画面
                ContentView()
                    .tabItem {
                        Label("マップ", systemImage: "map.fill")
                    }
                
                // 2. タイムライン画面 (新規追加)
                TimelineView()
                    .tabItem {
                        Label("タイムライン", systemImage: "clock.fill") // 時刻アイコン
                    }
                
                // 3. カレンダー・集計画面 (新規追加)
                CalendarView()
                    .tabItem {
                        Label("カレンダー", systemImage: "calendar") // カレンダーアイコン
                    }
                
                // 4. 設定画面 (新規追加)
                SettingsView()
                    .tabItem {
                        Label("設定", systemImage: "gearshape.fill") // 歯車アイコン
                    }
            }
        }
    }
}
