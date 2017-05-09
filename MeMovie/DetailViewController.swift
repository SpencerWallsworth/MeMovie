//
//  DetailViewController.swift
//  MeMovie
//
//  Created by iOS on 5/8/17.
//  Copyright © 2017 Spencer Wallsworth. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    var movie:Movie?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewText: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var language: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overviewText.isEditable = false
        titleLabel.text = movie?.title
        overviewText.text = movie?.overview
        date.text = movie?.releaseDate
        language.text = movie?.originalLanguage
        
        if let pic = movie?.picture {
            let url = URL(string: "http://image.tmdb.org/t/p/w185/" + pic)
           
            MovieNetwork.shared.getData(url: url!, completion: { data in
                DispatchQueue.main.async{
                    self.imageView.image = UIImage(data: data)
                }
            })
           
        }else{
            imageView.image = #imageLiteral(resourceName: "brokenImage")
        }
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
