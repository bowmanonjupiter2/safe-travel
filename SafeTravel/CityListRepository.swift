//
//  CityListRepository.swift
//  SafeTravel
//

import Foundation

class CityListRepository {
    
    static var cityList : [City] = []

    class func shareObject()->[City]{
        if (cityList.isEmpty){
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global(qos: .background).async {
                do{
                    guard let fileUrl = Bundle.main.url(forResource: "city.list", withExtension: "json") else {
                        throw CityJsonInitError.FileNotFoundError
                    }
                    let data = try Data(contentsOf: fileUrl)
                    cityList = try JSONDecoder().decode([City].self, from: data)
                    
                    //print(cityList)
                    
                    group.leave()
                    
                }catch let error{
                    print(error.localizedDescription)
                    group.leave()
                }
            }
            group.wait()
            return cityList
            
        }else{
            return cityList
        }
    }
    
}
