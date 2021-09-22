//
//  JobListTableViewCell.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 6/10/21.
//

import UIKit

class JobListTableViewCell: UITableViewCell {
    @IBOutlet weak var jobName: UILabel!
    @IBOutlet weak var jobDescr: UILabel!
    @IBOutlet weak var jobDistance: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
