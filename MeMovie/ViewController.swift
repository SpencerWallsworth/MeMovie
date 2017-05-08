//
//  ViewController.swift
//  MeMovie
//
//  Created by iOS on 5/6/17.
//  Copyright © 2017 Spencer Wallsworth. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Alamofire
import RxAlamofire

class ViewController: UIViewController, UISearchBarDelegate, UITextFieldDelegate{
    
    var movies = Variable<[Movie]>([])
    let disposeBag = DisposeBag()
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var submit: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadButton: UIButton!
    var page = 1
    var prevSearchString = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchBar.delegate = self
        self.searchBar.rx.searchButtonClicked.bind(onNext:{
        self.searchBar.resignFirstResponder()
            self.searchByText(text: self.searchBar.text!)
        }).disposed(by: disposeBag)
        
        //button tap
        submit.rx.tap
            .bind(onNext:{
                self.page = 1
                self.loadButton.isHidden = false
                self.searchBar.resignFirstResponder()
                self.searchByText(text: self.searchBar.text!)
            }).disposed(by: disposeBag)
        
        //load the next page
        loadButton.rx.tap
            .bind(onNext:{
                self.validateSearchString()
                self.searchBar.resignFirstResponder()
                self.loadMoreItems(text: self.searchBar.text!)
            }).disposed(by: disposeBag)
        
        //equivalent to cell for row at
        movies.asObservable().asDriver(onErrorJustReturn: []).drive(tableView.rx.items(cellIdentifier: "movieCell")){(_, data, cell) in
            cell.textLabel?.text = data.title
            cell.detailTextLabel?.text = data.score
        }.disposed(by: disposeBag)
        
        //equivalent to did select row at
        tableView.rx.modelSelected(Movie.self).subscribe(onNext: {
            let vc = DetailViewController(nibName: "DetailViewController", bundle: nil)
            vc.movie = $0
            self.navigationController?.pushViewController(vc, animated: true)
        }).disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func validateSearchString(){
        if prevSearchString == searchBar.text{
            page = page + 1
        }else{
            page = 1
            prevSearchString = searchBar.text!
            loadButton.isHidden = false
        }
    }
    /**
     Parses text replacing adjacent spaces with '+' then makes network call
        - Used to to search for new keywords.
     */
    func searchByText(text:String){
        //converting adjacent spaces into single + for the URL
        let searchString = NSMutableString(string: text)
        searchString.setString(searchString.trimmingCharacters(in: .whitespaces))
        let regex:NSRegularExpression = try! NSRegularExpression(pattern: "\\s+", options: [])
        regex.replaceMatches(in: searchString, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSMakeRange(0, searchString.length), withTemplate:"+$1")
        let stringURL = "https://api.themoviedb.org/3/search/movie?query=\(searchString.description)&api_key=9b1cfd760d88a01128ee7c753057bacf&page=\(self.page)"
        //Making network call
        json(.get, stringURL)
            .map{ self.parse(json: $0 as AnyObject?)}
            .observeOn(MainScheduler.instance)
            .subscribe( onNext: {
                    self.movies.value = $0
                    self.tableView.reloadData()
                }
            )
            .disposed(by: disposeBag)
    }
    /**
        Parses text replacing adjacent spaces with '+' then makes network call
            -Used to get the next page of already queried service call
     */
    func loadMoreItems(text:String){
        //converting adjacent spaces into single + for the URL
        let searchString = NSMutableString(string: text)
        searchString.setString(searchString.trimmingCharacters(in: .whitespaces))
        let regex:NSRegularExpression = try! NSRegularExpression(pattern: "\\s+", options: [])
        regex.replaceMatches(in: searchString, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSMakeRange(0, searchString.length), withTemplate:"+$1")
        let stringURL = "https://api.themoviedb.org/3/search/movie?query=\(searchString.description)&api_key=9b1cfd760d88a01128ee7c753057bacf&page=\(self.page)"
        //Making network call
        json(.get, stringURL)
            .map{ self.parse(json: $0 as AnyObject?)}
            .observeOn(MainScheduler.instance)
            .subscribe( onNext: {
                self.movies.value = self.movies.value + $0
                self.tableView.reloadData()
            }
            )
            .disposed(by: disposeBag)
        
    }
    
    //Dismiss keyboard if triggered
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.searchBar.resignFirstResponder()
    }
    
    //Parse the json to an Array<Movie>
    func parse(json:AnyObject?)->[Movie]{
        var titles = Set<String>()//filters out duplicates
        var model: [Movie] = []
        var hasItems = false
        (((json as? Dictionary<String,Any>)?["results"]) as! Array<AnyObject>).forEach({ movie in
            hasItems = true
            let picture =  (((movie as AnyObject)["poster_path"]) as? String)
            let title = (((movie as AnyObject)["title"]) as? String)
            let score = (((movie as AnyObject)["vote_average"]) as? NSNumber)?.description
            let id = (((movie as AnyObject)["id"]) as? NSNumber)?.description
            let overview = (((movie as AnyObject)["overview"]) as? String)
            let language = (((movie as AnyObject)["original_language"]) as? String)
            let date = (((movie as AnyObject)["release_date"]) as? String)

            if !titles.contains(title!){
                titles.insert(title!)
                model.append(Movie(id: id, title: title, score: score, picture: picture, overview: overview, releaseDate:date, originalLanguage: language))
            }
        })
        if !hasItems{
            loadButton.isHidden = true
        }
        return model
    }
}

