import UIKit

extension UIScreen {
    static var screenWidth: CGFloat {
        return UIScreen.main.bounds.width * UIScreen.main.scale
    }
    
    static var screenHeight: CGFloat {
        return UIScreen.main.bounds.height * UIScreen.main.scale
    }
} 
