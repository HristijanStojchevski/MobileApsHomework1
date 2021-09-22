//
//  Job.swift
//  Homework1
//
//  Created by Hrisitjan Stojchevski on 7/17/21.
//

import Foundation
import Firebase

class Job : NSObject, Codable{
    var name: String
    var category: String
    var lat: Double
    var long: Double
    var details: String
    var distance: Double
    var finished: Bool
    var enrolled: Bool?
    var jobRef: DocumentReference?
    
    init(name: String, category: String, lat: Double, long: Double, details: String, distance: Double, finished: Bool) {
        self.name = name
        self.category = category
        self.lat = lat
        self.long = long
        self.details = details
        self.distance = distance
        self.finished = finished
    }
    
    func setEnrolled(enrolled: Bool){
        self.enrolled = enrolled
    }
    
    func setJobRef(jobRef: DocumentReference){
        self.jobRef = jobRef
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case category
        case lat
        case long
        case details
        case distance
        case finished
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        category = try values.decode(String.self, forKey: .category)
        lat = try values.decode(Double.self, forKey: .lat)
        long = try values.decode(Double.self, forKey: .long)
        details = try values.decode(String.self, forKey: .details)
        distance = try values.decode(Double.self, forKey: .distance)
        finished = try values.decode(Bool.self, forKey: .finished)
    }
}
