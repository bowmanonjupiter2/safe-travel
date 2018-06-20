//
//  City.swift
//  SafeTravel
//

import Foundation

enum CityJsonInitError: Error{
    case JsonResourceNotFound
    case DataRetrivalError
    case FileNotFoundError
}

struct City : Decodable{
    let id : Int
    let name : String
    let country: String
    let coord: coord
    
    struct coord: Decodable {
        let lon: Double
        let lat: Double
    }
}
