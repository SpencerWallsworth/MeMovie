//
//  Movie.swift
//  MeMovie
//
//  Created by iOS on 5/7/17.
//  Copyright © 2017 Spencer Wallsworth. All rights reserved.
//

import Foundation
struct Movie{
    var id:String
    var title:String
    var score:String?
    var picture:String?
    var overview:String?
    var releaseDate:String
    var originalLanguage:String
    var genres: String?
    init(id:String, title:String, score:String?, picture:String?, overview:String?, releaseDate:String, originalLanguage:String, genres: String?) {
        self.id = id
        self.title = title
        self.score = score
        self.picture = picture
        self.overview = overview
        self.releaseDate = releaseDate
        self.originalLanguage = originalLanguage
        self.genres = genres
    }
}
