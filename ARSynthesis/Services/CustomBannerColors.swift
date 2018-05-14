import Foundation
import NotificationBannerSwift

class CustomBannerColors: BannerColorsProtocol {
    
    internal func color(for style: BannerStyle) -> UIColor {
        var color = UIColor()
        switch style {
        case .danger:
        color = UIColor.orange
        break
        // Your custom .danger color
        case .info:
        color = UIColor.purple
        break
        case .none:
        break
        case .success:
        break
        case .warning:
        break
        }
        return color
    }
    
}
