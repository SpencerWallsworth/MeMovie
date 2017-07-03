//
//  MovieTableViewCell.swift
//  MeMovie
//
//  Created by iOS on 6/28/17.
//  Copyright © 2017 Spencer Wallsworth. All rights reserved.
//

import UIKit

 class MovieTableViewCell: UITableViewCell {
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var movieTextLabel: UILabel!
    @IBOutlet weak var movieDetailTextLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

  
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
        self.update()
        if selected{
            self.cardView.backgroundColor = UIColor.lightGray
        }else{
            self.cardView.backgroundColor = UIColor.white
        }
    }
    func update(){
        cardView.layer.cornerRadius = 9
        cardView.layer.shadowOffset = CGSize(width: 0, height: 5)
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.3
    }
    
}
