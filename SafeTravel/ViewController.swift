//
//  ViewController.swift
//  SafeTravel


import UIKit
import MapKit
import Alamofire
import SwiftyJSON
import Kakapo

class ViewController: UIViewController,UIPickerViewDelegate,UIPickerViewDataSource,CLLocationManagerDelegate {
    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var cityPicker: UIPickerView!
    @IBOutlet weak var currWeatherLbl:UILabel!
    @IBOutlet weak var alertableWeatherIconLbl:UILabel!
    @IBOutlet weak var alertableWeatherDateLbl:UILabel!
    @IBOutlet weak var currentUVILbl:UILabel!
    @IBOutlet weak var alertableUVDateLbl:UILabel!
    @IBOutlet weak var alertableUVILbl:UILabel!
    
    let REGION_RADIUS_DEFAULT:CLLocationDistance = 1000
    
    let WEATHER_API_KEY = "3ecb658f8e3ddfb2e544f6fa284d385d"
    let WEATHER_SERVICE_DOMAIN = "https://api.openweathermap.org/data/2.5/"
    let CURRENT_WEATHER_REQUEST_KEYWORD = "weather"
    let FORECASTING_REQUEST_KEYWORD = "forecast"
    let UV_INDEX_KEYWORD = "uvi"
    
    let CRIME_SERVICE_DOMAIN = "https://opendata.mybluemix.net/crimes"
    let CRIME_QUERY_RADIUS=500//metres
    
    let IS_DUMMY_MODE = false
    
    //use a self defined memory caching to improve the feedback permformance, reduce unnecessary network trafic
    let iS_CACHING = false
    let CACHE_EXPIRY_INTERVAL_IN_SECONDS:Double = 300
    var locationSecurityCache = [Int:LocationSecurity]()

    var cities:[City] = []
    
    let locationManager:CLLocationManager = CLLocationManager()
    var currentLocationSecurity:LocationSecurity = LocationSecurity()
    
    var locationUpdateLock = 1
    
    var crawler:CrimeNewsCrawler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //trying to load the city list from the json config
        cities = CityListRepository.shareObject()
        
        //init the map view
        initLocation()
        
        //init the city picker view
        initCityPicker()
        
        //init map guesture
        initMapGuesture()
        
        //it doesn't work at this moment to intercept Alamofire request , not sure if it is the async call
//        if(IS_DUMMY_MODE){
//            let configuration = URLSessionConfiguration.default
//            configuration.protocolClasses = [Server.self]
//            let sessionManager = SessionManager(configuration: configuration)
//
//            let router = Router.register("https://api.openweathermap.org/data/2.5")
//            router.get("/weather"){ request in
//                if self.dummy_current_weather_data == nil{
//                    self.dummy_current_weather_data = self.loadLocalJsonFile(fileName: "current_weather")
//                }
//                return self.dummy_current_weather_data.serialized() as Serializable
//            }
//        }
        
        //initiate the trusted news website for crime data collection
        crawler = CrimeNewsCrawler()
        crawler?.crawl(city: "GuangZhou")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func initLocation(){
        initLocationManager()
        locationManager.requestLocation()
    }
    
    fileprivate func initCityPicker(){
        cityPicker.delegate = self
        cityPicker.dataSource = self
        cityPicker.isHidden = true
    }
    
    fileprivate func getLocationOfCity(city:City)->CLLocation{
        return CLLocation(latitude: city.coord.lat, longitude: city.coord.lon)
    }
    
    fileprivate func move2Location(location:CLLocation){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, REGION_RADIUS_DEFAULT, REGION_RADIUS_DEFAULT)
        myMap.setRegion(coordinateRegion, animated: true)
    }
    
    
    fileprivate func retrieveLocationWeatherDatabyNearestCityId(id:Int){
        
        let group = DispatchGroup()
        
        /*retieve current UV index begins*/
        group.enter()
        
        if(IS_DUMMY_MODE){
            print("using dummy current uv index")
            let json = self.loadLocalJsonFile(fileName: "current_uv_index")
            let resultJsonStr = json!.rawString()!
            do{
                let currentUVIndex = try JSONDecoder().decode(UVIndex.self, from: resultJsonStr.data(using: .utf8)!)
                self.currentLocationSecurity.currentUVIndex = currentUVIndex
            }catch let error{
                print(error.localizedDescription)
            }
            group.leave()
        } else{
            
            if(iS_CACHING && !self.isCachedNeedUpdate(cityId: id)){
                self.currentLocationSecurity.currentUVIndex = locationSecurityCache[id]?.currentUVIndex
                group.leave()
            }else{
                
                let lat = cities.filter{$0.id == id}[0].coord.lat
                let lon = cities.filter{$0.id == id}[0].coord.lon
                
                let currentUVIndexQueryUrl = WEATHER_SERVICE_DOMAIN + UV_INDEX_KEYWORD + "?lat=" + String(lat) + "&lon=" + String(lon) + "&APPID=" + WEATHER_API_KEY
                
                Alamofire.request(currentUVIndexQueryUrl).responseJSON { response in
                    
                    if let result = response.result.value {
                        let json = JSON(result)
                        let resultJsonStr = json.rawString()!

                        do{
                            let currentUVIndex = try JSONDecoder().decode(UVIndex.self, from: resultJsonStr.data(using: .utf8)!)
                            self.currentLocationSecurity.currentUVIndex = currentUVIndex
                            
                            if (self.iS_CACHING){
                                if let tmpLocationSecurity = self.locationSecurityCache[id] {
                                    tmpLocationSecurity.currentUVIndex = currentUVIndex
                                    tmpLocationSecurity.lastUpdateTime = Date()
                                }else{
                                    self.locationSecurityCache[id] = LocationSecurity()
                                    self.locationSecurityCache[id]?.nearestCityID = id
                                    self.locationSecurityCache[id]?.currentUVIndex = currentUVIndex
                                    self.locationSecurityCache[id]?.lastUpdateTime = Date()
                                }
                            }
                        }catch let error{
                            print(error.localizedDescription)
                        }
                    }
                    group.leave()
                }
            }
        }
        
        /*retrieve current UV Index ends*/
        
        /*retieve current weather data begins*/
        group.enter()
        
        if(IS_DUMMY_MODE){
            print("using dummy current weather data")
            let json = self.loadLocalJsonFile(fileName: "current_weather")
            let resultJsonStr = json!.rawString()!
            do{
                let currentWeather = try JSONDecoder().decode(CurrentWeather.self, from: resultJsonStr.data(using: .utf8)!)
                self.currentLocationSecurity.currentWeather = currentWeather
            }catch let error{
                print(error.localizedDescription)
            }
            group.leave()
        } else{
            
            if(iS_CACHING && !self.isCachedNeedUpdate(cityId: id)){
                self.currentLocationSecurity.currentWeather = locationSecurityCache[id]?.currentWeather
                group.leave()
            }else{
                
                let currentWeatherQueryUrl = WEATHER_SERVICE_DOMAIN + CURRENT_WEATHER_REQUEST_KEYWORD + "?id=" + String(id) + "&APPID=" + WEATHER_API_KEY
                
                Alamofire.request(currentWeatherQueryUrl).responseJSON { response in
                    
                    if let result = response.result.value {
                        let json = JSON(result)
                        let resultJsonStr = json.rawString()!
                        do{
                            let currentWeather = try JSONDecoder().decode(CurrentWeather.self, from: resultJsonStr.data(using: .utf8)!)
                            self.currentLocationSecurity.currentWeather = currentWeather
                            
                            if (self.iS_CACHING){
                                if let tmpLocationSecurity = self.locationSecurityCache[id] {
                                    tmpLocationSecurity.currentWeather = currentWeather
                                    tmpLocationSecurity.lastUpdateTime = Date()
                                }else{
                                    self.locationSecurityCache[id] = LocationSecurity()
                                    self.locationSecurityCache[id]?.nearestCityID = id
                                    self.locationSecurityCache[id]?.currentWeather = currentWeather
                                    self.locationSecurityCache[id]?.lastUpdateTime = Date()
                                }
                            }
                        }catch let error{
                            print(error.localizedDescription)
                        }
                    }
                    group.leave()
                }
            }
        }
        
        /*retrieve current weather data ends*/

        /*retieve forecast UV index begins*/
        group.enter()
        
        if(IS_DUMMY_MODE){
            print("using dummy forecast uv index")
            let json = self.loadLocalJsonFile(fileName: "forecast_uv_index")
            let resultJsonStr = json!.rawString()!
            do{
                let forecastUVIndex = try JSONDecoder().decode([UVIndex].self, from: resultJsonStr.data(using: .utf8)!)
                self.currentLocationSecurity.forecastUVIndex = forecastUVIndex
            }catch let error{
                print(error.localizedDescription)
            }
            group.leave()
        } else{
            
            if(iS_CACHING && !self.isCachedNeedUpdate(cityId: id)){
                self.currentLocationSecurity.forecastUVIndex = locationSecurityCache[id]?.forecastUVIndex
                group.leave()
            }else{
                
                let lat = cities.filter{$0.id == id}[0].coord.lat
                let lon = cities.filter{$0.id == id}[0].coord.lon
                
                let forecastUVIndexQueryUrl = WEATHER_SERVICE_DOMAIN + UV_INDEX_KEYWORD + "/" + FORECASTING_REQUEST_KEYWORD + "?lat=" + String(lat) + "&lon=" + String(lon) + "&APPID=" + WEATHER_API_KEY
                
                Alamofire.request(forecastUVIndexQueryUrl).responseJSON { response in
                    
                    if let result = response.result.value {
                        let json = JSON(result)
                        let resultJsonStr = json.rawString()!
                        do{
                            let forecastUVIndex = try JSONDecoder().decode([UVIndex].self, from: resultJsonStr.data(using: .utf8)!)
                            self.currentLocationSecurity.forecastUVIndex = forecastUVIndex
                            
                            if (self.iS_CACHING){
                                if let tmpLocationSecurity = self.locationSecurityCache[id] {
                                    tmpLocationSecurity.forecastUVIndex = forecastUVIndex
                                    tmpLocationSecurity.lastUpdateTime = Date()
                                }else{
                                    self.locationSecurityCache[id] = LocationSecurity()
                                    self.locationSecurityCache[id]?.nearestCityID = id
                                    self.locationSecurityCache[id]?.forecastUVIndex = forecastUVIndex
                                    self.locationSecurityCache[id]?.lastUpdateTime = Date()
                                }
                            }
                        }catch let error{
                            print(error.localizedDescription)
                        }
                    }
                    group.leave()
                }
            }
        }
        
        /*retrieve forecast UV Index ends*/
        
        /*retrieve forecasting weather data begins*/

        
            group.enter()
        
            if(IS_DUMMY_MODE){
                print("using dummy forecast weather data")
                let json = self.loadLocalJsonFile(fileName: "forecast_weather")
                let resultJsonStr = json!.rawString()!
                do{
                    let forecastingWeatherinComingDays = try JSONDecoder().decode(ForecastingWeather.self, from: resultJsonStr.data(using: .utf8)!)
                    self.currentLocationSecurity.forecastingWeather = forecastingWeatherinComingDays
                }catch let error{
                    print(error.localizedDescription)
                }
                group.leave()
            }else{
                
                if(iS_CACHING && !self.isCachedNeedUpdate(cityId: id)){
                    self.currentLocationSecurity.forecastingWeather = locationSecurityCache[id]?.forecastingWeather
                    group.leave()
                }else{
                    //this is actually the 5 day / 3 hours forecasting url which also accept cnt parameter to specify the amount of records needed, the
                    //real 16 day daily forecasting isn't in the free plan :(
                    //let dailyForecastingQueryUrl = WEATHER_SERVICE_DOMAIN + FORECASTING_REQUEST_KEYWORD + "?id=" + String(id) + "&cnt=16&APPID=" + WEATHER_API_KEY
                    let forecastingQueryUrl = WEATHER_SERVICE_DOMAIN + FORECASTING_REQUEST_KEYWORD + "?id=" + String(id) + "&APPID=" + WEATHER_API_KEY
                    
                    Alamofire.request(forecastingQueryUrl).responseJSON { response in
                        
                        if let result = response.result.value {
                            let json = JSON(result)
                            let resultJsonStr = json.rawString()!
                            do{
                                let forecastingWeatherinComingDays = try JSONDecoder().decode(ForecastingWeather.self, from: resultJsonStr.data(using: .utf8)!)
                                self.currentLocationSecurity.forecastingWeather = forecastingWeatherinComingDays
                                if (self.iS_CACHING){
                                    if let tmpLocationSecurity = self.locationSecurityCache[id] {
                                        tmpLocationSecurity.forecastingWeather = forecastingWeatherinComingDays
                                        tmpLocationSecurity.lastUpdateTime = Date()
                                    }else{
                                        self.locationSecurityCache[id] = LocationSecurity()
                                        self.locationSecurityCache[id]?.nearestCityID = id
                                        self.locationSecurityCache[id]?.forecastingWeather = forecastingWeatherinComingDays
                                        self.locationSecurityCache[id]?.lastUpdateTime = Date()
                                    }
                                }
                            }catch let error{
                                print(error.localizedDescription)
                            }
                        }
                        group.leave()
                    }
                }
            }


        /*retrieve five day forecasting weather data ends*/
        
        /*retieve crime data begins*/
//        group.enter()
//
//        if(IS_DUMMY_MODE){
//            print("using dummy crime data")
//            let json = self.loadLocalJsonFile(fileName: "crime_data")
//            self.currentLocationSecurity.crimeData = json
//            let now = Int((Date().timeIntervalSince1970*1000.0).rounded())
//            let twoyearsago = now - 2*12*30*24*60*60*1000
//            let filteredCrimes = json?["features"].arrayValue.filter{$0["properties"]["timestamp"].intValue >= twoyearsago}
//            print(filteredCrimes)
//            group.leave()
//        } else{
//            if(iS_CACHING && !self.isCachedNeedUpdate(cityId: id)){
//                self.currentLocationSecurity.crimeData = locationSecurityCache[id]?.crimeData
//                group.leave()
//            }else{
//                let lat = cities.filter{$0.id == id}[0].coord.lat
//                let lon = cities.filter{$0.id == id}[0].coord.lon
//                let crimeDataQueryUrl = CRIME_SERVICE_DOMAIN + "?lat=" + String(lat) + "&lon=" + String(lon) + "&radius=" + String(CRIME_QUERY_RADIUS)
//                Alamofire.request(crimeDataQueryUrl).responseString{respStr in
//                    if respStr.value?.lowercased().range(of: "502 bad gateway") != nil{
//                        self.currentLocationSecurity.crimeData = JSON()
//                    }else{
//                        let allCrimeDataJson = JSON(respStr.data!)
//
//                        //filter crime data that within 16 months
//                        let now = Int((Date().timeIntervalSince1970*1000.0).rounded())
//                        let before = now - 16*30*24*60*60*1000
//                        let filteredCrimesByTime = allCrimeDataJson["features"].arrayValue.filter{$0["properties"]["timestamp"].intValue >= before}
//
//                        //fitler crime data that match some patterns ,e.g violence,burglary,robbery,arson,theft,anti-social
////                        let filteredCrimesByTypes = filteredCrimesByTime.filter{$0["properties"]["type"].stringValue.lowercased(). != nil}
//                        do{
//                            let regex = try NSRegularExpression(pattern: "burglary|violence|robbery|arson|theft|anti-social", options: NSRegularExpression.Options.caseInsensitive)
//
//                            let filteredCrimesByTypes = filteredCrimesByTime.filter{
//                                let str2Search = $0["properties"]["type"].stringValue
//                                let range = NSRange(location:0,length:str2Search.utf8.count)
//                                let matches = regex.matches(in: str2Search, options: [], range:range)
//                                if matches.count>0{
//                                    return true
//                                }else{
//                                    return false
//                                }
//                            }
//
//                            self.currentLocationSecurity.crimeData = JSON(filteredCrimesByTypes)
//                            if (self.iS_CACHING){
//                                if let tmpLocationSecurity = self.locationSecurityCache[id] {
//                                    tmpLocationSecurity.crimeData = self.currentLocationSecurity.crimeData
//                                    tmpLocationSecurity.lastUpdateTime = Date()
//                                }else{
//                                    self.locationSecurityCache[id] = LocationSecurity()
//                                    self.locationSecurityCache[id]?.nearestCityID = id
//                                    self.locationSecurityCache[id]?.crimeData = self.currentLocationSecurity.crimeData
//                                    self.locationSecurityCache[id]?.lastUpdateTime = Date()
//                                }
//                            }
//                        }catch let error{
//                            print(error.localizedDescription)
//                        }
//                    }
//                    group.leave()
//                }
//            }
//        }
//
        /*retrieve crime data ends*/
        
        //weather data update should happen in this to make sure call sequence is expected
        group.notify(queue: DispatchQueue.main){
            print("retrieve weather data completed")
            
            //retrieve current weather id
            let currWeatherId = self.currentLocationSecurity.currentWeather?.weather[0].id
            //retrieve weather icon
            let currWeatherIcon = WeatherIconFontConstant.getWeatherIcon(owmCode: currWeatherId!)

            //self.addCoverView()
            
            self.updateCurrWeatherIcon(icon: currWeatherIcon)
            
            self.searchAndDisplayNearestExtremeWeather(forecastWeatherData: self.currentLocationSecurity.forecastingWeather!)
            
            self.updateCurrentUVI(uvi: (self.currentLocationSecurity.currentUVIndex?.value)!)
            
            self.searchAndDisplayNearestUVDanger(forecastUVI: self.currentLocationSecurity.forecastUVIndex!)
            
            //self.addCrimeAnnotation()
            
        }
        
    }

    /*map guesture begins*/
    func initMapGuesture(){
        //setup the map view's gesture recognizer for long press(default is 0.5 second) which intend to bring up the world city selector
        let longPressing = UILongPressGestureRecognizer(target:self, action:#selector(responder4LongPressing))
        //using objective-c selector here isn't very nice consider later enhancement
        longPressing.minimumPressDuration = 1
        myMap.addGestureRecognizer(longPressing)
    }
    
    @objc func responder4LongPressing(){
        cityPicker.isHidden = false
    }
    /*map guesture ends*/
    
    /*location manager begins*/
    fileprivate func initLocationManager(){
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            //locationManager.requestAlwaysAuthorization()
        }
        //locationManager.distanceFilter = kCLDistanceFilterNone
        //locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        //locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        
        if(locationUpdateLock > 0){
            //avoid multiple triggering
            locationUpdateLock = 0
            
            //get the latest location data
            let location:CLLocation = locations.last!
            
            move2Location(location: location)
            
            //set the nearest city
            let nearestCity = calculateNearestCity(location: location)
            self.currentLocationSecurity.nearestCityID = nearestCity.id
            
            retrieveLocationWeatherDatabyNearestCityId(id: nearestCity.id)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    /*location manager ends*/
    
    /*crime annotation begins*/
    fileprivate func addCrimeAnnotation(){
        for crime in (self.currentLocationSecurity.crimeData?.arrayValue)!{
//            print(crime["properties"]["type"])
//            print(crime["properties"]["timestamp"])
//            print(crime["geometry"]["coordinates"])
            
            print(crime["_id"].stringValue)
            
            let lat = crime["geometry"]["coordinates"][1]
            let lon = crime["geometry"]["coordinates"][0]
            
            let crimeAnnotation = MKPointAnnotation()
            crimeAnnotation.coordinate = CLLocation(latitude: lat.doubleValue, longitude: lon.doubleValue).coordinate
            print(crimeAnnotation.coordinate)
            myMap.addAnnotation(crimeAnnotation)
        }
    }
    /*crime annatation ends*/
    
    /*weather icon update begins*/
    fileprivate func getUIColorByUVColor(uvColor:WeatherIconFontConstant.UVIndexColor)->UIColor{
        switch uvColor {
        case WeatherIconFontConstant.UVIndexColor.Green:
            return UIColor.green
        case WeatherIconFontConstant.UVIndexColor.Yellow:
            return UIColor.yellow
        case WeatherIconFontConstant.UVIndexColor.Orange:
            return UIColor.orange
        case WeatherIconFontConstant.UVIndexColor.Red:
            return UIColor.red
        case WeatherIconFontConstant.UVIndexColor.Violet:
            return UIColor.purple
        }
    }
    
    fileprivate func searchAndDisplayNearestUVDanger(forecastUVI:[UVIndex]){
        for uvi in forecastUVI{
            let uvColor = WeatherIconFontConstant.getUVColorByIndex(uvi: uvi.value)
            if(uvColor.isAlertable()){
                let date = Date(timeIntervalSince1970: Double(uvi.date))
                let dateFormatterPrint = DateFormatter()
                dateFormatterPrint.dateFormat = "dd-MMM"
                alertableUVDateLbl.text = dateFormatterPrint.string(from: date)
                alertableUVDateLbl.font = UIFont(name: "Helvetica Neue", size: CGFloat(12))
                
                alertableUVILbl.text = "uvi:" + String(uvi.value)
                alertableUVILbl.font = UIFont(name: "Helvetica Neue", size: CGFloat(12))
                alertableUVILbl.textColor = getUIColorByUVColor(uvColor: uvColor)
            }
        }
    }
    
    fileprivate func updateCurrentUVI(uvi:Float){
        currentUVILbl.text = "uvi:"+String(uvi)
        currentUVILbl.textColor = getUIColorByUVColor(uvColor: WeatherIconFontConstant.getUVColorByIndex(uvi: uvi))
        currentUVILbl.font = UIFont(name: "Helvetica Neue", size: CGFloat(12))
    }
    
    fileprivate func updateCurrWeatherIcon(icon:WeatherIconFontConstant.WeatherIconType){
        currWeatherLbl.text = icon.rawValue
        currWeatherLbl.font = UIFont(name: WeatherIconFontConstant.iconFontName, size: CGFloat(32))
        //currWeatherLbl.textColor = UIColor(hue: 0.5, saturation: 0.5, brightness: 1.0, alpha: 1.0)
        //currWeatherLbl.textColor = UIColor.yellow
        if (icon.isAlertable()){
            currWeatherLbl.textColor = UIColor.red
        } else{
            currWeatherLbl.textColor = UIColor.blue
        }
    }
    fileprivate func searchAndDisplayNearestExtremeWeather(forecastWeatherData:ForecastingWeather){
        for periodWeather in forecastWeatherData.list {
            let weatherId = periodWeather.weather[0].id
            let weatherIconType = WeatherIconFontConstant.getWeatherIcon(owmCode: weatherId)
            if (weatherIconType.isAlertable()){

                let dateFormatterGet = DateFormatter()
                dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss" // "2017-11-22 12:00:00"
                let dateFormatterPrint = DateFormatter()
                dateFormatterPrint.dateFormat = "dd-MMM" //22-Nov
                
                //alertableWeatherDateLbl.text = periodWeather.dt_txt
                alertableWeatherDateLbl.text = dateFormatterPrint.string(from: (dateFormatterGet.date(from: periodWeather.dt_txt))!)
                alertableWeatherDateLbl.font = UIFont(name: "Helvetica Neue", size: CGFloat(12))
                //alertableWeatherDateLbl.textColor = UIColor.red
                
                alertableWeatherIconLbl.text =  weatherIconType.rawValue
                alertableWeatherIconLbl.font = UIFont(name: WeatherIconFontConstant.iconFontName, size: CGFloat(18))
                alertableWeatherIconLbl.textColor = UIColor.red
                
                //add UILabel programmatically to support multiple weather alert
                //let label = UILabel(frame:CGRect(origin: <#T##CGPoint#>, size: <#T##CGSize#>))
                break
            }
        }
        
    }
//    fileprivate func updateForecastingWeatherIcon(forecastWeatherData:ForecastingWeather){
//        let day1WeatherId = forecastWeatherData.list[0].weather[0].id
//        //retrieve weather icon
//        let day1WeatherIcon = WeatherIconFontConstant.getWeatherIcon(owmCode: day1WeatherId)
//
//        forecastDay1Lbl.text = day1WeatherIcon
//        forecastDay1Lbl.font = UIFont(name: WeatherIconFontConstant.iconFontName, size: CGFloat(24))
//
//    }
    /*weather icon update ends*/
    
    /*cover view for security information begins*/
    fileprivate func addCoverView(){
        let screenRect = UIScreen.main.bounds
        let coverView = UIView(frame: screenRect)
        coverView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        self.view.addSubview(coverView)
    }
    /*cover view for security information ends*/
    
    /*picker protocol begins*/
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return cities.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return cities[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        cityPicker.isHidden = true
        
        //clean up the weather icon
        currWeatherLbl.text = ""
        currentUVILbl.text = ""
        alertableWeatherIconLbl.text = ""
        alertableWeatherDateLbl.text = ""
        alertableUVDateLbl.text = ""
        alertableUVILbl.text = ""
        
        
        //update the nearest city to be the city selected
        self.currentLocationSecurity.nearestCityID = cities[row].id
        
        move2Location(location:getLocationOfCity(city: cities[row]))
        
        retrieveLocationWeatherDatabyNearestCityId(id: cities[row].id)
    }
    /*picker protocol ends*/
    
    /*utility begins*/
    
    fileprivate func isCachedNeedUpdate(cityId:Int)->Bool{
        if let tempLocationSecurity = locationSecurityCache[cityId]{
            if (Date() > (tempLocationSecurity.lastUpdateTime?.addingTimeInterval(CACHE_EXPIRY_INTERVAL_IN_SECONDS))!){
                return true
            }else{
                return false
            }
        }else{
            return true
        }

    }
    
    fileprivate func calculateNearestCity(location:CLLocation) ->City{
        var nearestCity:City?
        var minDistance = Double.greatestFiniteMagnitude
        for city in cities {
            let dis = distance(location1: location, location2: CLLocation(latitude: city.coord.lat, longitude: city.coord.lon))
            if dis < minDistance {
                minDistance = dis
                nearestCity = city
            }
        }

        return nearestCity!
    }
    
    fileprivate func distance(location1:CLLocation, location2:CLLocation)->Double{
        return sqrt((location1.coordinate.latitude - location2.coordinate.latitude)*(location1.coordinate.latitude - location2.coordinate.latitude) + (location1.coordinate.longitude-location2.coordinate.longitude)*(location1.coordinate.longitude-location2.coordinate.longitude))
    }
    
    fileprivate func loadLocalJsonFile(fileName:String)->JSON?{
        var json:JSON?
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .background).async {
            do{
                guard let fileUrl = Bundle.main.url(forResource: fileName, withExtension: "json") else {
                    throw SwiftyJSONError.notExist
                }
                let data = try Data(contentsOf: fileUrl)
                json = try JSON(data: data)
                
                group.leave()
                
            }catch let error{
                print(error.localizedDescription)
                group.leave()
            }
        }
        group.wait()
        return json
    }
    
    /*utility ends*/

}

