import UIKit

class SettingsRoundedButton: UIButton {
    
    override func awakeFromNib() {
        
        self.layer.borderWidth = 3
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 3
        
    }

}
