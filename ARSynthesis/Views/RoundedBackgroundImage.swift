import UIKit

class RoundedBackgroundImage: UIImageView {
    
    override func awakeFromNib() {
        
        self.layer.borderWidth = 3
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.cornerRadius = 10
        
    }

}
