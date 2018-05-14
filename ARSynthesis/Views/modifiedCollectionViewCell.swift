import UIKit
import ARKit

class ModifiedCollectionViewCell: UICollectionViewCell {
    var nodeContained: SCNNode = SCNNode()
    @IBOutlet var settingsCellImage: UIButton!
    @IBOutlet var settingsCellLabel: UILabel!
    override func awakeFromNib() {
    }
}

