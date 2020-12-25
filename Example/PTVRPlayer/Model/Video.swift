//
//  Video.swift
//  Runner
//
//  Created by Phạm Xuân Tiến on 11/16/20.
//

import ObjectMapper

struct Video: Equatable {
    var id = 0
    var title = ""
    var duration = ""
    var url = ""
}

extension Video: Then { }

extension Video: Mappable {
    init?(map: Map) {
        self.init()
    }
    
    mutating func mapping(map: Map) {
        id <- map["id"]
        title <- map["title"]
        duration <- map["duration"]
        url <- map["url"]
    }
}

struct ListVideo {
    var items: [Video] = []
    var currentIndex: Int = 0
}

extension ListVideo: Then { }

extension ListVideo: Mappable {
    init?(map: Map) {
        self.init()
    }
    
    mutating func mapping(map: Map) {
        items <- map["video_data"]
        currentIndex <- map["current_index"]
    }
}
