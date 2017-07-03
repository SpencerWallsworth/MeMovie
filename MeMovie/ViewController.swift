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
import Speech
import CoreMotion

class ViewController: UIViewController, UISearchBarDelegate, UITextFieldDelegate,UITabBarDelegate,AVAudioRecorderDelegate, AVAudioPlayerDelegate{
    var movies = Variable<[Movie]>([])
    var gryo = Variable<CMGyroData?>(nil)
    let disposeBag = DisposeBag()
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var tabBar: UITabBar!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var page = 1
    var prevSearchString = ""
    var isRecording = false
    override func viewDidLoad() {
        super.viewDidLoad()        
        tabBar.items?.first?.image?.withRenderingMode(.alwaysTemplate)
        updateAudioRecordDisplay()
        self.searchBar.delegate = self
        self.tabBar.delegate = self
        let nib = UINib(nibName: "MovieTableViewCell", bundle: nil)
        self.searchBar.returnKeyType  = .search
        self.tableView.register(nib, forCellReuseIdentifier: "movieCell")
        self.tableView.rowHeight = 60
        //searchButton similar to submit
        self.searchBar.rx.searchButtonClicked.bind(onNext:{
            self.page = 1
            self.loadButton.isHidden = false
            self.searchBar.resignFirstResponder()
            self.searchByText(text: self.searchBar.text!)
            self.prevSearchString = self.searchBar.text!
        }).disposed(by: disposeBag)
        
        
        //searchbar
        searchBar.rx.textDidEndEditing.bind(onNext:{
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
            let movieCell = cell as! MovieTableViewCell
            movieCell.movieTextLabel?.text = data.title
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 1
            movieCell.movieDetailTextLabel?.text = formatter.number(from: data.score!)?.description
            movieCell.update()
        }.disposed(by: disposeBag)
        
        //Animate cells coming onto screen
        tableView.rx.willDisplayCell.bind { (cell: UITableViewCell, indexPath: IndexPath) in
            cell.alpha = 0
            let transform = CATransform3DTranslate(CATransform3DIdentity, -250.0, 50, 0.0)
            cell.layer.transform = transform
            UIView.animate(withDuration: 0.3, animations: {
                cell.alpha = 1.0
                cell.layer.transform = CATransform3DIdentity
            })
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
        let stringURL = "https://api.themoviedb.org/3/search/movie?query=\(MovieNetwork.shared.format(parameter: text))&api_key=9b1cfd760d88a01128ee7c753057bacf&page=\(self.page)"
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
        let stringURL = "https://api.themoviedb.org/3/search/movie?query=\(MovieNetwork.shared.format(parameter: prevSearchString))&api_key=9b1cfd760d88a01128ee7c753057bacf&page=\(self.page)"
        
        print(stringURL)
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

    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if !isRecording{
            recognizeSpeech()
        }else{
            cancelRecording()
        }
        isRecording = !isRecording
        updateAudioRecordDisplay()
        print("User wants to use speech recognition!")
    }
    func cancelRecording() {
        audioEngine.stop()
        if let node = audioEngine.inputNode {
            node.removeTap(onBus: 0)
        }
        recognitionTask?.cancel()
    }
    //Dismiss keyboard if triggered
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.searchBar.resignFirstResponder()
    }
    func updateAudioRecordDisplay(){
        if !isRecording{
            tabBar.tintColor = UIColor.green
            //stop recording and play sound
            activityIndicator.stopAnimating()

        }else{
            tabBar.tintColor = UIColor.red
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        }
    }

    func recognizeSpeech(){
        SFSpeechRecognizer.requestAuthorization { status in
            guard  status == SFSpeechRecognizerAuthorizationStatus.authorized else{
                print("Error occured in trying to recognize speech")
                return
            }
        // Setup audio engine and speech recognizer
        guard let node = self.audioEngine.inputNode else { return }
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        
        // Prepare and start recording
        self.audioEngine.prepare()
        do {
            try self.audioEngine.start()
            } catch {
            return print(error)
        }
        
        // Analyze the speech
        self.recognitionTask = self.speechRecognizer?.recognitionTask(with: self.request, resultHandler: { result, error in
            if let result = result {
               self.searchBar.text = result.bestTranscription.formattedString
            } else if let error = error {
                print(error)
            }
        })
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == UIEventSubtype.motionShake{
            searchBar.text = ""
            movies.value = []
        }
    }
    
}

