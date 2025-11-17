// LocationHistoryViewModel.swift

import Foundation
import FirebaseFirestore
import FirebaseAuth

// Firestoreのデータをマッピングする構造体
struct LocationData: Identifiable, Codable, Hashable {
    @DocumentID var id: String? // ドキュメントID
    var latitude: Double
    var longitude: Double
    var timestamp: Timestamp // Firebaseのタイムスタンプ
    var placeName: String
    var category: String
    
    // Viewで使いやすいようにDate型に変換
    var date: Date {
        timestamp.dateValue()
    }
}

@MainActor
class LocationHistoryViewModel: ObservableObject {
    @Published var locationHistory: [LocationData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    func fetchHistory() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "ログインしていません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        db.collection("users").document(userId).collection("locations")
          .order(by: "timestamp", descending: true) // 新しい順にソート
          .limit(to: 50) // 直近50件のみ
          .getDocuments { [weak self] (querySnapshot, error) in
              
              guard let self = self else { return }
              self.isLoading = false
              
              if let error = error {
                  self.errorMessage = "データ取得エラー: \(error.localizedDescription)"
                  return
              }
              
              guard let documents = querySnapshot?.documents else {
                  self.errorMessage = "データが見つかりません"
                  return
              }
              
              // FirestoreのデータをLocationDataに変換
              self.locationHistory = documents.compactMap { document -> LocationData? in
                  try? document.data(as: LocationData.self)
              }
          }
    }
}
