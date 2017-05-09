//
//  MovieNetwork.swift
//  MeMovie
//
//  Created by iOS on 5/8/17.
//  Copyright © 2017 Spencer Wallsworth. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire
import RxAlamofire

final class MovieNetwork{
    static let shared = MovieNetwork()
    private init() {}

    func getImage(url:URL, completion:@escaping (_ data:Data)->Void){
        Alamofire.request(url).responseData { dataRequest in
            DispatchQueue.main.async{
                completion(dataRequest.data!)
            }
        }
    }
    
    func getMovies( url:URL, disposeBag:DisposeBase, completion:@escaping (_ movies:[Movie])->Void){
        json(.get, url)
            .map{ self.parse(json: $0 as AnyObject?)}
            .observeOn(MainScheduler.instance)
            .subscribe( onNext: {
                completion($0)
            }
            )
            .disposed(by: disposeBag as! DisposeBag)
    }
    
    //Parse the json to an Array<Movie>
    func parse(json:AnyObject?)->[Movie]{
        var titles = Set<String>()//filters out duplicates
        var model: [Movie] = []
        (((json as? Dictionary<String,Any>)?["results"]) as! Array<AnyObject>).forEach({ movie in
            let picture =  (((movie as AnyObject)["poster_path"]) as? String)
            let title = (((movie as AnyObject)["title"]) as? String)
            let score = (((movie as AnyObject)["vote_average"]) as? NSNumber)?.description
            let id = (((movie as AnyObject)["id"]) as? NSNumber)?.description
            let overview = (((movie as AnyObject)["overview"]) as? String)
            let language = (((movie as AnyObject)["original_language"]) as? String)
            let date = (((movie as AnyObject)["release_date"]) as? String)
            
            //ensures no duplicate titles
            if !titles.contains(title!){
                titles.insert(title!)
                model.append(Movie(id: id, title: title, score: score, picture: picture, overview: overview, releaseDate:date, originalLanguage: language))
            }
        })
        return model
    }
}
