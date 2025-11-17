// BackgroundLocationManager.swift

import Foundation
import CoreLocation
import MapKit
import FirebaseAuth
import FirebaseFirestore
import Combine
import BackgroundTasks

// (変更点: シングルトン化のため `static let shared` を追加)
class BackgroundLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    static let shared = BackgroundLocationManager() // ★シングルトンインスタンス
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let taskIdentifier = "com.kanta.PaLog.locationRefresh"
    // ★ BGTaskの完了ハンドラを保持する
    private var taskCompletionHandler: ((Bool) -> Void)?
    
    // (変更点: initから不要な設定を削除)
    override init() {
        super.init()
        locationManager.delegate = self
        // 精度は要求時に設定
    }
    func startMonitoring() {
        print("設定: タスクのスケジュールを要求します。")
        // UserDefaultsに "ON" であることを保存 (SettingsViewの@AppStorageが自動でやってくれる)
        // 実際のスケジュール処理を呼び出す
        scheduleLocationRefresh()
    }
    func stopMonitoring() {
        print("設定: タスクのスケジュールをキャンセルします。")
        // UserDefaultsに "OFF" であることを保存 (SettingsViewの@AppStorageが自動でやってくれる)
        
        // ★ スケジュールをキャンセル
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        print("タスクID \(taskIdentifier) のスケジュールをキャンセルしました。")
    }
    func scheduleLocationRefresh() {
        // --- UserDefaultsから設定を読み込む ---
        let defaults = UserDefaults.standard
        // (SettingsViewの@AppStorage("isTrackingEnabled")とキーを合わせる)
        let isTrackingEnabled = defaults.bool(forKey: "isTrackingEnabled")
        
        // 1. トグルがOFFなら、スケジュールせずに終了
        guard isTrackingEnabled else {
            print("トラッキングがOFFのため、タスクをスケジュールしません。")
            // 念のためキャンセルも実行
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
            return
        }
        
        // 2. 頻度を読み込む
        // (SettingsViewの@AppStorage("recordFrequency")とキーを合わせる)
        let frequencyString = defaults.string(forKey: "recordFrequency") ?? "1時間ごと"
        let frequency = (frequencyString == "30分ごと") ? 30 : 60 // 30か60
        
        // --- タスクリクエスト作成 ---
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        
        // --- 「次のキリのいい時間」を計算 ---
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ja_JP")
        let now = Date()
        
        var nextExecutionDate: Date
        
        if frequency == 30 {
            // 30分ごと (0分, 30分)
            let nextHour = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime)!
            let nextHalfHour = calendar.nextDate(after: now, matching: DateComponents(minute: 30, second: 0), matchingPolicy: .nextTime)!
            nextExecutionDate = min(nextHour, nextHalfHour)
        } else {
            // 60分ごと (0分)
            nextExecutionDate = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0), matchingPolicy: .nextTime)!
        }
        
        request.earliestBeginDate = nextExecutionDate
        print("次のタスク開始希望時刻: \(nextExecutionDate) (頻度: \(frequency)分)")

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("タスクのスケジュールに失敗しました: \(error)")
        }
    }
    func requestAlwaysAuthorization() {
            // すでに許可されているか確認
            let status = locationManager.authorizationStatus
            
            if status == .notDetermined {
                // まだ許可/不許可が選択されていない
                print("位置情報の許可をリクエストします (Always)")
                locationManager.requestAlwaysAuthorization() // 「常時」をリクエスト
                
            } else if status == .authorizedWhenInUse {
                // 「使用中のみ」許可されている場合
                print("「使用中のみ」許可されています。「常時」へのアップグレードをリクエストします。")
                locationManager.requestAlwaysAuthorization() // 「常時」にアップグレードを促す
                
            } else if status == .authorizedAlways {
                // すでに「常時」許可されている
                print("すでに 'Always' 許可されています。")
                
            } else if status == .denied || status == .restricted {
                // ユーザーが明示的に拒否、または機能制限されている
                print("位置情報が拒否または制限されています。")
                // (必要であれば、設定アプリを開くよう促すアラートなどを表示)
            }
        }
        
    // 許可状態が変更されたときに呼ばれる (デリゲートメソッド)
    // ※これは以前のコードにもありましたが、念のため確認
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedAlways {
            print("'Always'許可が得られました。")
        } else {
            print("'Always'許可がありません (現在のステータス: \(status.rawValue))")
        }
    }
    
    // (削除: startMonitoring, stopMonitoring は不要)
    
    // ★ステップ2のタスクハンドラから呼ばれる関数
    func fetchAndSaveCurrentLocation(completion: @escaping (Bool) -> Void) {
        print("単発の位置情報取得を要求します。")
        self.taskCompletionHandler = completion
        
        let status = locationManager.authorizationStatus
        guard status == .authorizedAlways else {
            print("エラー: 'Always'許可がありません。")
            completion(false) // タスク失敗
            return
        }
        
        // 精度を設定
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        // ★ 単発の位置情報をリクエスト
        locationManager.requestLocation()
    }
    
    // ★ リクエストがキャンセルされた場合（タイムアウトなど）
    func cancelLocationRequest() {
        locationManager.stopUpdatingLocation() // requestLocationの中断
        taskCompletionHandler?(false)
        taskCompletionHandler = nil
    }

    // --- CLLocationManagerDelegate ---
    
    // (変更点: didUpdateLocations は単発取得の結果として扱う)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            taskCompletionHandler?(false) // 失敗
            taskCompletionHandler = nil
            return
        }
        
        print("新しい位置情報を取得しました (単発): \(location.coordinate)")
        
        // 取得した位置情報を非同期で処理
        Task {
            // (この関数はステップ3のコードから流用)
            let success = await fetchAndSaveLocationInfo(for: location)
            
            // ★ OSにタスク完了を通知
            taskCompletionHandler?(success)
            taskCompletionHandler = nil
        }
    }
    
    // (変更点: didFailWithError もタスクの失敗として扱う)
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置情報の取得に失敗しました: \(error.localizedDescription)")
        
        // ★ OSにタスク失敗を通知
        taskCompletionHandler?(false)
        taskCompletionHandler = nil
    }
    
    // ... locationManagerDidChangeAuthorization() はそのまま (start/stop呼び出しは削除) ...
    
    // --- データ処理とFirebase保存 ---
    
    // (変更点: 戻り値で成功/失敗を返すようにする)
    private func fetchAndSaveLocationInfo(for location: CLLocation) async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("エラー: ログインしていません。")
            return false
        }
        
        var placeName: String = "不明な場所"
        var categoryName: String = "カテゴリなし"
        
        // (1. 住所取得) ...
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            placeName = placemarks.first?.name ?? "不明な住所"
        } catch {
            print("CLGeocoderエラー: \(error.localizedDescription)")
        }
        
        // (2. カテゴリ取得) ...
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 100, longitudinalMeters: 100)
        let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        
        do {
            let response = try await MKLocalSearch(request: request).start()
            if let firstItem = response.mapItems.first {
                placeName = firstItem.name ?? placeName
                categoryName = firstItem.pointOfInterestCategory?.rawValue ?? categoryName
            } else {
                categoryName = "移動中"
            }
        } catch {
            print("MKLocalSearchエラー: \(error.localizedDescription)")
            // (カテゴリ取得失敗しても住所名で続行)
        }
        
        // (3. Firebase保存) ...
        let db = Firestore.firestore()
        let locationData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "timestamp": Timestamp(date: location.timestamp),
            "placeName": placeName,
            "category": categoryName,
            "accuracy": location.horizontalAccuracy
        ]
        
        do {
            try await db.collection("users").document(userId).collection("locations").addDocument(data: locationData)
            print("Firebaseに位置情報を保存しました: \(placeName) (\(categoryName))")
            return true // ★成功
        } catch {
            print("Firestoreへの保存エラー: \(error.localizedDescription)")
            return false // ★失敗
        }
    }
}
