import Foundation
import CoreLocation
import MapKit
import FirebaseAuth
import FirebaseFirestore
import Combine

// NSObjectを継承し、CLLocationManagerDelegateに準拠
class BackgroundLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    // CoreLocationのマネージャー
    private let locationManager = CLLocationManager()
    
    // MapKit検索ロジック (MapViewModelから流用)
    private let geocoder = CLGeocoder()
    
    // 最後に記録した場所（短時間での重複記録を避けるため）//////////////////////////////////////////////////
    private var lastRecordedLocation: CLLocation?
    
    // 記録頻度（秒単位）。例: 30分 = 1800秒
    private let recordInterval: TimeInterval = 1800 // 30分
    
    override init() {
        super.init()
        locationManager.delegate = self
        
         func startMonitoring() {
             locationManager.allowsBackgroundLocationUpdates = true
             locationManager.pausesLocationUpdatesAutomatically = true
             // ... 既存のコード ...
         }
        
        // --- 精度設定 ---
        // 30分ごとなので、精度はそこまで高くなくてOK (省エネのため)
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // 100m精度
        
        // 500m以上移動したら更新する (省エネのため)
        locationManager.distanceFilter = 500
    }
    
    // 1. ユーザーに「常時許可」をリクエストする
    func requestAlwaysAuthorization() {
        // すでに許可されているか確認
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestAlwaysAuthorization() // 「常時」をリクエスト
        } else if status == .authorizedWhenInUse {
            // 「使用中のみ」許可されている場合も、「常時」にアップグレードを促す
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    // 2. 監視を開始する (設定画面のトグルなどから呼ぶ)
    func startMonitoring() {
        // 「常時」または「使用中」が許可されているか確認
        let status = locationManager.authorizationStatus
        if status == .authorizedAlways {
            print("バックグラウンド監視を開始します (startUpdatingLocation)")
            // 継続的に位置情報を取得する
            // (注: これが最もバッテリーを消費しますが、30分ごとのチェックにはこれが必要です)
            locationManager.startUpdatingLocation()
        } else {
            print("バックグラウンド監視を開始できません。'Always'許可がありません。")
            requestAlwaysAuthorization() // 許可がない場合は再度リクエスト
        }
    }
    
    // 3. 監視を停止する (設定画面のトグルなどから呼ぶ)
    func stopMonitoring() {
        print("バックグラウンド監視を停止します")
        locationManager.stopUpdatingLocation()
    }
    
    // --- CLLocationManagerDelegate ---
    
    // 4. 位置情報が更新されるたびにOSから呼ばれる
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return } // 最新の位置情報を取得
        
        let now = Date()
        
        // 最後の記録から十分な時間が経過したか、または
        // 最後の記録場所から十分な距離が離れたかを確認
        if let lastLocation = lastRecordedLocation,
           now.timeIntervalSince(lastLocation.timestamp) < recordInterval,
           location.distance(from: lastLocation) < manager.distanceFilter {
            
            // print("位置情報は更新されましたが、前回の記録から時間が経過していないためスキップします。")
            return // 条件を満たさなければ記録しない
        }

        print("新しい位置情報を取得しました: \(location.coordinate)")
        self.lastRecordedLocation = location // 最後の記録として更新
        
        // 取得した位置情報を非同期で処理（カテゴリ検索 & Firebase保存）
        Task {
            await fetchAndSaveLocationInfo(for: location)
        }
    }
    
    // 5. 許可状態が変更されたときに呼ばれる
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedAlways {
            print("'Always'許可が得られました。監視を開始します。")
            startMonitoring() // 常時許可が得られたら自動で監視を開始
        } else {
            print("'Always'許可がありません (\(status.rawValue))。監視を停止します。")
            stopMonitoring() // 常時許可でなくなったら停止
        }
    }
    
    // エラーハンドリング
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置情報の取得に失敗しました: \(error.localizedDescription)")
    }
    
    // --- データ処理とFirebase保存 ---
    
    // 6. カテゴリ検索とFirebase保存 (MapViewModelのロジックを流用)
    private func fetchAndSaveLocationInfo(for location: CLLocation) async {
        // --- ログイン中のユーザーIDを取得 ---
        guard let userId = Auth.auth().currentUser?.uid else {
            print("エラー: ログインしていません。位置情報を保存できません。")
            return
        }
        
        // --- 1. CLGeocoderで住所名を取得 (フォールバック用) ---
        var placeName: String = "不明な場所"
        var categoryName: String = "カテゴリなし"
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            placeName = placemarks.first?.name ?? "不明な住所"
        } catch {
            print("CLGeocoderエラー: \(error.localizedDescription)")
        }
        
        // --- 2. MKLocalSearchでカテゴリを取得 ---
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 100, longitudinalMeters: 100)
        let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        
        do {
            let response = try await MKLocalSearch(request: request).start()
            if let firstItem = response.mapItems.first {
                placeName = firstItem.name ?? placeName // 施設名があれば上書き
                categoryName = firstItem.pointOfInterestCategory?.rawValue ?? categoryName // カテゴリ名
            } else {
                // POIが見つからない場合 (例: 道路上)
                categoryName = "移動中" // または住所情報から推測
            }
        } catch {
            print("MKLocalSearchエラー: \(error.localizedDescription)")
            // ネットワークエラーなど
        }
        
        // --- 3. Firebase (Firestore) に保存 ---
        let db = Firestore.firestore()
        let locationData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "timestamp": Timestamp(date: location.timestamp), // Firebaseのタイムスタンプ型
            "placeName": placeName,
            "category": categoryName,
            "accuracy": location.horizontalAccuracy // 位置情報の精度
        ]
        
        do {
            // users/(ユーザーID)/locations というコレクションにデータを追加
            try await db.collection("users").document(userId).collection("locations").addDocument(data: locationData)
            print("Firebaseに位置情報を保存しました: \(placeName) (\(categoryName))")
        } catch {
            print("Firestoreへの保存エラー: \(error.localizedDescription)")
        }
    }
}
