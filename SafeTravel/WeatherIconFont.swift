//
//  WeatherIconFont.swift
//  SafeTravel
//

import Foundation



struct WeatherIconFontConstant {
    static let iconFontName: String = "Weather Icons"
    
    enum UVIndexColor:String{
        case Green = "Low"
        case Yellow = "Moderate"
        case Orange = "High"
        case Red = "Very High"
        case Violet = "Extreme"
        
        func isAlertable()->Bool{
            switch self {
            case .Green,.Yellow,.Orange:
                return false
            case .Red,.Violet:
                return true
            }
        }
    }
    
    enum WeatherIconType: String{
        case thunderstorm = "\u{f01e}"
        case lightning = "\u{f016}"
        case sprinkle = "\u{f01c}"
        case rain = "\u{f019}"
        case rain_mix = "\u{f017}"
        case showers = "\u{f01a}"
        case storm_showers = "\u{f01d}"
        case snow = "\u{f01b}"
        case sleet = "\u{f0b5}"
        case smoke = "\u{f062}"
        case day_haze = "\u{f0b6}"
        case dust = "\u{f063}"
        case fog = "\u{f014}"
        case cloudy = "\u{f013}"
        case cloudy_gust = "\u{f011}"
        case tornado = "\u{f056}"
        case day_sunny = "\u{f00d}"
        case hurricane = "\u{f073}"
        case snowflake_cold = "\u{f076}"
        case hot = "\u{f072}"
        case windy = "\u{f021}"
        case hail = "\u{f015}"
        case strong_wind = "\u{f050}"
        case not_available = "0"
        
        func isAlertable()->Bool{
            switch self {
            case .thunderstorm,.lightning,.storm_showers,.snow,.dust,.fog,.tornado,.hurricane,.snowflake_cold,.hot,.strong_wind:
                return true
            default:
                return false
            }
        }
    }
    static func getUVColorByIndex(uvi:Float)->UVIndexColor{
        switch uvi {
        case let x where x>=0.00&&x<2.99:
            return UVIndexColor.Green
        case let x where x>=3.00&&x<5.99:
            return UVIndexColor.Yellow
        case let x where x>=6.00&&x<7.99:
            return UVIndexColor.Orange
        case let x where x>=8.00&&x<10.99:
            return UVIndexColor.Red
        case let x where x>=11.00:
            return UVIndexColor.Violet
        default:
            return UVIndexColor.Green
        }
    }
    
    static func getWeatherIcon(owmCode:Int)->WeatherIconType{
        switch owmCode {
        case 200...202,230...232:
            return WeatherIconType.thunderstorm
        case 210...212,221:
            return WeatherIconType.lightning
        case 300,301,321,500:
            return WeatherIconType.sprinkle
        case 302,311,312,314,501...504:
            return WeatherIconType.rain
        case 310,511,611,612,615,616,620:
            return WeatherIconType.rain_mix
        case 313,520...522,701:
            return WeatherIconType.showers
        case 531,901:
            return WeatherIconType.storm_showers
        case 600,601,621,622:
            return WeatherIconType.snow
        case 602:
            return WeatherIconType.sleet
        case 711:
            return WeatherIconType.smoke
        case 721:
            return WeatherIconType.day_haze
        case 731,761,762:
            return WeatherIconType.dust
        case 741:
            return WeatherIconType.fog
        case 771,801...803:
            return WeatherIconType.cloudy_gust
        case 804:
            return WeatherIconType.cloudy
        case 781,900:
            return WeatherIconType.tornado
        case 800:
            return WeatherIconType.day_sunny
        case 902:
            return WeatherIconType.hurricane
        case 903:
            return WeatherIconType.snowflake_cold
        case 904:
            return WeatherIconType.hot
        case 905:
            return WeatherIconType.windy
        case 906:
            return WeatherIconType.hail
        case 957:
            return WeatherIconType.strong_wind
        default:
            return WeatherIconType.not_available
        }
    }
    
}
