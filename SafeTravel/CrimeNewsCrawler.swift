//
//  CrimeNewsCrawler.swift
//  SafeTravel
//

import Foundation

enum CrimeType{
}

class CrimeNewsCrawler{
    var trustedNewsSitesDic:NSDictionary?
    init() {
        let path = Bundle.main.path(forResource: "trusted_news_sites", ofType: "plist")
        trustedNewsSitesDic = NSDictionary(contentsOfFile: path!)
    }
    func crawl(city:String){
        print("hey")
        for item in trustedNewsSitesDic!{
            print(item)
        }
    }
}
