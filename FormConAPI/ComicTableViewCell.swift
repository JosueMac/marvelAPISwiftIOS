//
//  ComicTableViewCell.swift
//  FormConAPI
//
//  Created by Dev1 on 29/11/18.
//  Copyright © 2018 Dev1. All rights reserved.
//

import UIKit

class ComicTableViewCell: UITableViewCell {

   @IBOutlet weak var Titulo: UILabel!
   
   @IBOutlet weak var miDescripcion: UILabel!
   
   @IBOutlet weak var imagen: UIImageView!
   
   
   override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
