import UIKit
import Foundation

extension Photo {
    // Get dimensions after optimization
    var optimizedWidth: Int {
        let targetWidth = Int(UIScreen.screenWidth - 32) // 32 for margin two side
        return targetWidth
    }
    
    var optimizedHeight: Int {
        let targetHeight = Int(CGFloat(optimizedWidth) * aspectRatio)
        return targetHeight
    }
    
    var optimizedSizeText: String {
        return "\(optimizedWidth) × \(optimizedHeight)"
    }
    
    var optimizedImageURL: URL {
        // Check if resizing is needed
        let shouldResize = width > optimizedWidth && height > optimizedHeight
        
        // If resizing is needed
        if shouldResize {
            let url = getOptimizedImageURL(for: CGSize(width: optimizedWidth, height: optimizedHeight))
            return url ?? downloadURL
        } else {
            // Use original URL
            return downloadURL
        }
    }
    
    //  is image is high resolution
    var isHighResolution: Bool {
        return width > optimizedWidth && height > optimizedHeight
    }
    
    func getOptimizedImageURL(for imageSize: CGSize) -> URL? {
        let urlString = Constants.API.Endpoints.imageURL(id: id, width: Int(imageSize.width), height: Int(imageSize.height))
        return URL(string: urlString)
    }
} 
