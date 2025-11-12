import Foundation
import MapKit

@MainActor
final class MapViewModel: ObservableObject {
    
    @Published var placeName: String = ""
    @Published var categoryName: String = ""
    @Published var lastErrorMessage: String = ""
    @Published var isLoading: Bool = false
    
    func searchForCategory(at coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let geocoder = CLGeocoder()
            
            // まずリバースジオコーディングで住所や施設名を取得
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let nameFromGeocode = placemarks.first?.name ?? "不明"
            
            // 次に、周辺のPOI情報を取得（カテゴリ）
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 100, // 半径100m以内
                longitudinalMeters: 100
            )
            
            let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
            let response = try await MKLocalSearch(request: request).start()
            
            if let nearestItem = response.mapItems.first {
                placeName = nearestItem.name ?? nameFromGeocode
                categoryName = nearestItem.pointOfInterestCategory?.rawValue ?? "カテゴリ情報なし"
            } else {
                // 近くにPOIがない場合は住所情報を使う
                placeName = nameFromGeocode
                categoryName = placemarks.first?.locality ?? "カテゴリ情報なし"
            }
            
            lastErrorMessage = ""
            
        } catch {
            placeName = ""
            categoryName = ""
            lastErrorMessage = "位置情報の取得に失敗しました: \(error.localizedDescription)"
        }
    }
}
