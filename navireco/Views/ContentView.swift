import SwiftUI
import MapKit

struct ContentView: View {
    
    // 作成したViewModelを監視
    @StateObject private var viewModel = MapViewModel()
    
    // 地図のカメラ位置
    @State private var mapCameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 33.2411, // 佐賀大学
                longitude: 130.2844
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.01,
                longitudeDelta: 0.01
            )
        )
    )

    var body: some View {
        
        // MapReaderでMapを囲む
        // proxyという「地図の操作役」が使えるようになります
        MapReader { proxy in
            
            // 地図本体
            Map(position: $mapCameraPosition)
                .onTapGesture { tapPosition in // マップがタップされた時の「画面上の位置(CGPoint)」
                    
                    // proxyを使って、画面上の位置(CGPoint) を
                    // 緯度・経度(CLLocationCoordinate2D) に変換
                    if let coordinate = proxy.convert(tapPosition, from: .local) {
                        
                        // 取得した緯度・経度を使ってViewModelの検索を実行
                        Task {
                            await viewModel.searchForCategory(at: coordinate)
                        }
                    }
                }
        }
        .edgesIgnoringSafeArea(.top) // 地図を画面上部まで広げる
        
        // 検索結果を画面下部にオーバーレイ表示
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView() // 検索中はインジケーターを表示
                } else {
                    Text("タップした場所のカテゴリ")
                        .font(.headline)
                    
                    HStack {
                        Text("施設名:")
                        Text(viewModel.placeName)
                    }
                    HStack {
                        Text("カテゴリ:")
                        Text(viewModel.categoryName)
                    }
                    
                    if !viewModel.lastErrorMessage.isEmpty {
                        Text(viewModel.lastErrorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.thinMaterial) // 半透明の背景
            .cornerRadius(10)
            .padding() // 画面の端から少し離す
        }
    }
}

#Preview {
    ContentView()
}
