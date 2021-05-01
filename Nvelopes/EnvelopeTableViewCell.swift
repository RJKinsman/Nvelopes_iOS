//
//  EnvelopeTableViewCell.swift
//  Nvelopes
//
//  Created by Roland Kinsman on 12/31/18.
//  Copyright © 2018 RJKinsman. All rights reserved.
//

import UIKit

class EnvelopeTableViewCell: UITableViewCell {
    
//    MARK: Properties
    @IBOutlet weak var labelEnvelopeName: UILabel!
    @IBOutlet weak var labelEnvelopeAmount: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

}
