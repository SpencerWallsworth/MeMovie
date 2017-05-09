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
        
        //searchButton similar to submit
        self.searchBar.rx.searchButtonClicked.bind(onNext:{
            self.page = 1
            self.loadButton.isHidden = false
            self.searchBar.resignFirstResponder()
            self.searchByText(text: self.searchBar.text!)
            self.prevSearchString = self.searchBar.text!
        }).disposed(by: disposeBag)
        
        //button tap
        submit.rx.tap
            .bind(onNext:{
                self.page = 1
                self.loadButton.isHidden = false
                self.searchBar.resignFirstResponder()
                self.searchByText(text: self.searchBar.text!)
                self.prevSearchString = self.searchBar.text!
            }).disposed(by: disposeBag)
        
        //load the next page
        loadButton.rx.tap
            .bind(onNext:{
                self.page = self.page + 1
                self.searchBar.resignFirstResponder()
                self.loadMoreItems()
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
        let url = URL(string: stringURL)
        MovieNetwork.shared.getMovies(url: url!, disposeBag: disposeBag) { moviesData in
            self.movies.value =  moviesData
            self.loadButton.isHidden = false
            self.tableView.reloadData()
        }
    }
    /**
        Parses text replacing adjacent spaces with '+' then makes network call
            -Used to get the next page of already queried service call
     */
    func loadMoreItems(){
        //converting adjacent spaces into single + for the URL
        let searchString = NSMutableString(string: prevSearchString)
        searchString.setString(searchString.trimmingCharacters(in: .whitespaces))
        let regex:NSRegularExpression = try! NSRegularExpression(pattern: "\\s+", options: [])
        regex.replaceMatches(in: searchString, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSMakeRange(0, searchString.length), withTemplate:"+$1")
        let stringURL = "https://api.themoviedb.org/3/search/movie?query=\(searchString.description)&api_key=9b1cfd760d88a01128ee7c753057bacf&page=\(self.page)"
        let url = URL(string: stringURL)
        
        MovieNetwork.shared.getMovies(url: url!, disposeBag: disposeBag) { moviesData in
            if !moviesData.isEmpty{
                self.movies.value = self.movies.value + moviesData
                self.loadButton.isHidden = false
                self.tableView.reloadData()
            }else{
                self.loadButton.isHidden = true
            }
        }
    }
    
    //Dismiss keyboard if triggered
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.searchBar.resignFirstResponder()
    }
}

