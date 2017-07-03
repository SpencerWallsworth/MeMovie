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
    class func getData(url:URL, completion:@escaping (_ data:Data)->Void){
        
        Alamofire.request(url).responseData { dataRequest in
            DispatchQueue.main.async{
                completion(dataRequest.data!)
            }
        }
    }
    
    class func getMovies( url:URL, disposeBag:DisposeBase, completion:@escaping (_ movies:[Movie])->Void){
        json(.get, url)
            .map{ self.parse(json: $0 as AnyObject?)}
            .observeOn(MainScheduler.instance)
            .subscribe( onNext: {
                completion($0)
            }
            )
            .disposed(by: disposeBag as! DisposeBag)
    }
    class func nagivateToItunesURL(title:String, errorHandler:@escaping (_ messsage:String)->()){
        
        Alamofire.request("https://itunes.apple.com/search?term=\(MovieNetwork.format(parameter: title))").responseJSON { response in
            debugPrint(response)
            
            if let json = response.result.value {
                var urlString:String?
                let array = (((json as? NSDictionary)?["results"]) as? NSArray)

                guard array != nil && (array?.count)! != 0 else{
                    errorHandler("Itunes Does Not Have The Movie Title At The Moment")
                    return
                }
                    urlString = ((array?[0]) as? NSDictionary)?["trackViewUrl"] as? String
                let url = URL(string: urlString ?? "")
                if UIApplication.shared.canOpenURL(url!){
                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    return
                }
            }
            errorHandler("Title Of Movie Does Not Exist")
        }
    }
    
    //Parse the json to an Array<Movie>
    class func parse(json:AnyObject?)->[Movie]{
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
                model.append(Movie(id: id!, title: title!, score: score, picture: picture, overview: overview, releaseDate:date!, originalLanguage: language!))
            }
        })
        return model
    }
    
    //converting adjacent spaces into single + for the URL
    class func format(parameter:String)->String{
        let searchString = NSMutableString(string: parameter)
        searchString.setString(searchString.trimmingCharacters(in: .whitespaces))
        let regex:NSRegularExpression = try! NSRegularExpression(pattern: "\\s+", options: [])
        regex.replaceMatches(in: searchString, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSMakeRange(0, searchString.length), withTemplate:"+$1")
        return searchString.description
    }
}
