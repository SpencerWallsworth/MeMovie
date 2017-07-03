//
//  DetailViewController.swift
//  MeMovie
//
//  Created by iOS on 5/8/17.
//  Copyright © 2017 Spencer Wallsworth. All rights reserved.
//

import UIKit
import SafariServices
class DetailViewController: UIViewController {
    var movie:Movie?
    
    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var overviewText: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var language: UILabel!
    @IBOutlet weak var genres: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let title = (movie?.title), let date =  movie?.releaseDate, let language = movie?.originalLanguage{
            
            self.titleLabel.text = title
            self.date.text = date
            self.language.text = language
            
            if let overview = movie?.overview{
                self.overviewText.text = overview
            }else{
                self.overviewText.text = "N/A"
            }
            self.overviewText.setNeedsDisplay()
            
            self.genres.text = movie?.genres ?? ""
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
        }else{
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    

    @IBAction func searchForMovie(_ sender: UIButton) {
        MovieNetwork.shared.nagivateToItunesURL(title: (movie?.title)!, errorHandler: {message in
            //pop up an alertviewcontroller with the message
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "ERROR", message: message, preferredStyle: .alert)
                    let okayAction = UIAlertAction(title: "Okay", style: .cancel, handler: nil)
            alertController.addAction(okayAction)
                self.present(alertController, animated: true, completion: nil)
            }
        
        })
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
