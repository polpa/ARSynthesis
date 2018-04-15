//
//  itemCell.swift
//  Ikea
//
//  Created by Rayan Slim on 2017-08-18.
//  Copyright © 2017 Rayan Slim. All rights reserved.
//

import UIKit

class CustomItemCell: UICollectionViewCell {
 
    @IBOutlet weak var itemLabel: UILabel!
    
    override var bounds: CGRect{
        didSet{
            self.layoutIfNeeded()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setCircularCell()
    }
    
    func setCircularCell() {
        self.layer.cornerRadius = CGFloat(roundf(Float(self.itemLabel.frame.size.width / 2.0)))
    }
}
