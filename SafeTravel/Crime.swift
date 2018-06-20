//
//  Crime.swift
//  SafeTravel
//

import Foundation

struct Crime:Decodable{
    let num_rows:Int32
    let type:String
    let features:[feature]

    
    struct feature:Decodable{
        let geometry:[geometry]
        let reportedBy:String
        let _rev:String
        let _id:String
        let type:String
        let properties:[properties]

        struct properties:Decodable{
            let updated:Int32
            let location:String
            let source:String
            let timestamp:Int32
            let type:String
        }
        struct geometry:Decodable{
            let coordinates:[coordinate]
            let type:String
            struct coordinate:Decodable{
                let lon:Double
                let lat:Double
            }
        }
    }
}
