//
//  JobTableViewCell.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 5/28/21.
//

import UIKit

class JobTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var JobLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
