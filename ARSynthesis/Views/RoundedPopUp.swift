import UIKit

class RoundedPopUp: UIView {
    
    override func awakeFromNib() {
        
        layer.borderWidth = 3
        layer.masksToBounds = true
        layer.cornerRadius = 10
    }
    
}
