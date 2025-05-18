import Foundation

enum Constants {
    enum API {
        static let baseURL = "https://picsum.photos"
        static let version = "v2"
        
        enum Endpoints {
            static let list = "\(baseURL)/\(version)/list"
            
            static func imageURL(id: String, width: Int, height: Int) -> String {
                return "\(baseURL)/id/\(id)/\(width)/\(height)"
            }
        }
    }
} 