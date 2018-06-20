//
//  LocationSecurity.swift
//  SafeTravel
//

import Foundation
import SwiftyJSON

class LocationSecurity {
    
    var nearestCityID:Int?
    var currentWeather:CurrentWeather?
    var forecastingWeather:ForecastingWeather?
    var currentUVIndex:UVIndex?
    var forecastUVIndex:[UVIndex]?
    var lastUpdateTime:Date?
    var crimeData:JSON?

}
