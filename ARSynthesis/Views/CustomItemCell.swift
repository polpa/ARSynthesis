import UIKit

class CustomItemCell: UICollectionViewCell {
 
    @IBOutlet weak var itemLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setCircularCell()
    }
    
    func setCircularCell() {
        self.layer.cornerRadius = 6
    }
}
