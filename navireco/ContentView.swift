//
//  ContentView.swift
//  navireco
//
//  Created by 藤井幹太 on 2025/11/12.
//

import SwiftUI
import MapKit
import CoreLocation

// ViewModel: 位置情報とMapKitのロジックを管理する
class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    // SwiftUIのViewに結果を反映させるための変数
    @Published var isLoading = false
    @Published var placeName: String = "---"
    @Published var categoryName: String = "---"
    @Published var statusMessage: String = "ボタンを押して現在地を検索"
    
    // --- 追加箇所 (ここから) ---
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    // --- 追加箇所 (ここまで) ---
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // 1. 位置情報の許可をリクエストする
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // 2. 現在地をリクエストする（ボタンから呼び出す）
    func findMyCategory() {
        self.isLoading = true
        self.statusMessage = "現在地を取得中..."
        self.placeName = "..."
        self.categoryName = "..."
        
        // --- 追加箇所 (リセット) ---
        // 検索開始時に緯度経度をリセット（0.0に）
        self.latitude = 0.0
        self.longitude = 0.0
        // --- 追加箇所 (ここまで) ---
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .notDetermined:
            statusMessage = "位置情報の許可が必要です"
            requestLocationPermission()
            self.isLoading = false
        case .denied, .restricted:
            statusMessage = "設定アプリから位置情報の許可をしてください"
            self.isLoading = false
        @unknown default:
            fatalError()
        }
    }
    
    // 3. 位置情報の取得に「成功」した時に呼ばれるデリゲートメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            self.isLoading = false
            self.statusMessage = "位置情報の取得に失敗"
            return
        }
        
        // --- 追加箇所 (ここから) ---
        // 取得した緯度・経度を@Published変数にセット
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        // --- 追加箇所 (ここまで) ---
        
        self.statusMessage = "周辺情報を検索中..."
        
        Task {
            await searchForCategory(at: location)
        }
    }
    
    // 4. 位置情報の取得に「失敗」した時に呼ばれるデリゲートメソッド
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.isLoading = false
        self.statusMessage = "エラー: \(error.localizedDescription)"
    }
    
    // 5. 許可ステータスが「変更」された時に呼ばれるデリゲートメソッド
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            findMyCategory()
        }
    }
    
    // 6. MapKitでカテゴリを検索する (デバッグプリント追加版)
    @MainActor
    func searchForCategory(at location: CLLocation) async {
        let request = MKLocalSearch.Request()
        request.resultTypes = .pointOfInterest
        
        // 検索半径を5000mに設定
        request.region = MKCoordinateRegion(center: location.coordinate,
                                            latitudinalMeters: 5000,
                                            longitudinalMeters: 5000)
        
        // ---
        // --- デバッグ用に追加 (ここから) ---
        // ---
        print("--- 検索処理を開始します ---")
        print("検索座標 (緯度・経度): \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("検索半径: 5000m")
        // ---
        // --- デバッグ用 (ここまで) ---
        // ---
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            
            // --- デバッグ用に追加 (ここから) ---
            print("MapKit検索成功。")
            print("見つかった施設数: \(response.mapItems.count) 件")
            // --- デバッグ用 (ここまで) ---
            
            if let firstItem = response.mapItems.first {
                
                // --- デバッグ用に追加 (ここから) ---
                print("一番近い施設名: \(firstItem.name ?? "名前なし")")
                print("カテゴリ: \(firstItem.pointOfInterestCategory?.rawValue ?? "カテゴリなし")")
                // --- デバッグ用 (ここまで) ---
                
                self.placeName = firstItem.name ?? "不明な施設"
                self.categoryName = firstItem.pointOfInterestCategory?.rawValue ?? "カテゴリなし"
            } else {
                
                // --- デバッグ用に追加 (ここから) ---
                print("エラー: 検索は成功しましたが、半径5000m以内に施設が見つかりませんでした。")
                // --- デバッグ用 (ここまで) ---
                
                self.placeName = "周辺に施設なし"
                self.categoryName = "---"
            }
            
            self.statusMessage = "検索完了"
            
        } catch {
            
            // --- デバッグ用に追加 (ここから) ---
            print("！！！MapKit検索が失敗しました！！！")
            print("エラー内容: \(error)")
            print("エラー詳細 (Localized): \(error.localizedDescription)")
            // --- デバッグ用 (ここまで) ---
            
            self.statusMessage = "MapKit検索エラー: \(error.localizedDescription)"
            self.placeName = "---"
            self.categoryName = "---"
        }
        
        self.isLoading = false
    }
}
// SwiftUI View: 画面の見た目を定義
struct ContentView: View {
    
    @StateObject private var viewModel = LocationViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            
            Text("現在地のカテゴリ検索")
                .font(.title)

            // 結果表示エリア
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("施設名:")
                        .font(.headline)
                    Text(viewModel.placeName)
                }
                HStack {
                    Text("カテゴリ:")
                        .font(.headline)
                    Text(viewModel.categoryName)
                }
                
                Divider() // 仕切り線
                
                // --- 追加箇所 (ここから) ---
                HStack {
                    Text("緯度:")
                        .font(.headline)
                    // %g は不要な0を省略して表示するフォーマット指定子
                    Text(String(format: "%g", viewModel.latitude))
                }
                HStack {
                    Text("経度:")
                        .font(.headline)
                    Text(String(format: "%g", viewModel.longitude))
                }
                // --- 追加箇所 (ここまで) ---
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 検索ボタン
            Button(action: {
                viewModel.findMyCategory()
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "location.fill")
                    }
                    Text(viewModel.isLoading ? "検索中..." : "現在地を検索")
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(viewModel.isLoading)
            
            // ステータスメッセージ
            Text(viewModel.statusMessage)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding()
        .onAppear {
            viewModel.requestLocationPermission()
        }
    }
}

#Preview {
    ContentView()
}
