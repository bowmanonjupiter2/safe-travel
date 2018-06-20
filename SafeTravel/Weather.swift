//
//  Weather.swift
//  SafeTravel
//

import Foundation


struct clouds:Decodable{
    let all:Int
}

struct weatherData:Decodable{
    let main:String
    let icon:String
    let description:String
    let id:Int
}

struct wind:Decodable{
    //let deg:Float
    let speed:Float
}

public struct UVIndex:Decodable{
    let lat:Double
    let lon:Double
    let date_iso:String
    let date:Int
    let value:Float
}   

public struct ForecastingWeather:Decodable{
    let list:[daily_weather]
    let cod:String
    let cnt:Int
    let message:Float
    let city:city
    
    struct daily_weather:Decodable{
        let main:main
        let clouds:clouds
        let weather:[weatherData]
        let dt_txt:String
        let dt:Int
        let sys:sys
        let wind:wind
        
        struct main:Decodable{
            let grnd_level:Float
            let temp_min:Float
            let temp_max:Float
            let temp:Float
            let sea_level:Float
            let pressure:Float
            let humidity:Int
            let temp_kf:Float
        }
        struct sys:Decodable{
            let pod:String
        }
    }

    struct city:Decodable{
        let name:String
        let id:Int
        let coord:coord
        let country:String
    }
    struct coord:Decodable{
        let lat:Double
        let lon:Double
    }
}
   public struct CurrentWeather: Decodable{
        let main:main
        let name:String
        let id:Int
        let coord:coord
        let weather:[weatherData]
        let clouds:clouds
        let dt:Int
        let base:String
        let sys:sys
        let cod:Int
        let visibility:Int
        let wind:wind
        
        struct main:Decodable{
            let humidity:Float
            let temp_min:Float
            let temp_max:Float
            let temp:Float
            let pressure:Float
        }
        struct coord:Decodable{
            let lon:Double
            let lat:Double
        }
        struct sys:Decodable{
            let sunset:Int
            let sunrise:Int
            let message:Float
            let id:Int
            let type:Int
            let country:String
        }
    }
