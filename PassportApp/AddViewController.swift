//
//  AddViewController.swift
//  PassportApp
//
//  Created by Luis Souza on 2019-11-27.
//  Copyright © 2019 Luis Henrique Souza. All rights reserved.
//

import UIKit
import CoreLocation
import Foundation

// MARK: Dictionary
struct passport: Codable {
    var title: String
    var latitude: String
    var longitude: String
    var description: String
    var arrival: String
    var departure: String
}

class AddViewController: UIViewController, CLLocationManagerDelegate {

    // MARK: Variables / Const
    @IBOutlet weak var txtTitle: UITextField!
    @IBOutlet weak var btnSave: UIBarButtonItem!
    @IBOutlet weak var txtViewDesc: UITextView!
    @IBOutlet weak var dtArrival: UIDatePicker!
    @IBOutlet weak var dtDeparture: UIDatePicker!
    
    // GPS
    let myLocationManager = CLLocationManager()
    
    // Used in building the url
    var URLqueryItems: [URLQueryItem] = []

    var jsonObjects: [String: [[String:Any]]]?
    var jsonArray: [[String:Any]]?
    var newRecord: String = ""
    var jsonData: Data?
    var jsonEncodedQuery: String?
    var lat = ""
    var long = ""

    let PATH = "https://lenczes.edumedia.ca/mad9137/final_api/passport/"
    let CREATE = "create/?data="

    // MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        btnSave.isEnabled = txtTitle.text != ""
    }
    
    // MARK: Action Methods
    @IBAction func btnSave(_ sender: UIBarButtonItem) {

        getLocationAndSave()
        
        // Call the main window back
        navigationController?.popToRootViewController(animated: true)
    }

    @IBAction func txtTitle(_ sender: Any) {
        btnSave.isEnabled = txtTitle.text != ""
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    // MARK: Private Methods
    func getLocationAndSave() {
        // Set the locationManager delegate
        myLocationManager.delegate = self
        // Request authorization from user to access location
        myLocationManager.requestWhenInUseAuthorization()
        // Request the location from the locationManager
        myLocationManager.requestLocation()
    }

    // called by myLocationManager.requstLocation() on success
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // gps coords
        lat = locations[0].coordinate.latitude.description
        long = locations[0].coordinate.longitude.description

        // date values converted
        var newArrival = dtArrival!.date.description
        var newDeparture = dtDeparture!.date.description
        
        newArrival = String(newArrival.dropLast(9))
        newDeparture = String(newDeparture.dropLast(9))

        // create an instance of my codable struct
        let record = passport(title: txtTitle.text!, latitude: lat, longitude: long, description: txtViewDesc.text, arrival: newArrival, departure: newDeparture)

        newRecord = encoderJson(rec: record)
        
        var encUrl = PATH + CREATE + newRecord
        encUrl = encUrl.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed)!
        requestConn(url: encUrl)
        
    }
    
    // called by myLocationManager.requstLocation() on error
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func encoderJson(rec: passport) -> String {
        let jsonEncoder = JSONEncoder()
        do {
            jsonData = try jsonEncoder.encode(rec)
            jsonEncodedQuery = String(data: jsonData!, encoding: .utf8)
            print("JSON String : " + jsonEncodedQuery!)
            return jsonEncodedQuery!
        }
        catch let parsingError {
            print("Error: ", parsingError.localizedDescription)
            return ""
        }
    }

    // Request Connection and Session
    func requestConn(url: String) -> Void {
        if let requestUrl: URL = URL(string: url) {
            // Create the request object and pass in your url
            var myRequest: URLRequest = URLRequest(url: requestUrl)
            myRequest.addValue("mora0199", forHTTPHeaderField: "my-authentication")

            // Create the URLSession object that will make the request
            let mySession: URLSession = URLSession.shared

            // Make the specific task from the session by passing in your request, and the function that will be use to handle the request
            let myTask = mySession.dataTask(with: myRequest, completionHandler: requestTask)

            // Tell the task to run
            myTask.resume()
        } else {
            print("ERROR Requesting the URL...")
        }
    }
    
    // Handle the request which will need to receive the data send back, the response status, and an error object to handle any errors returned
    func requestTask (_ serverData: Data?, serverResponse: URLResponse?, serverError: Error?) -> Void{
        
        // If the error object has been set then an error occured
        if serverError != nil {
            // Send en empty string as the data, and the error to the callback function
            self.myCallback("", error: serverError?.localizedDescription)
        } else {
            // If no error was returned, then the server response has been received and must Stringified
            let result = String(data: serverData!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
            
            // Send the response string data, and nil for the error tot he callback
            self.myCallback(result, error: nil)
        }
    }

    // Define the callback function to be triggered when the response is received
    func myCallback(_ responseString: String, error: String?) {
        
        // If the server request generated an error then handle it
        if error != nil {
            print("JSON DATA LOADING ERROR: " + error!)
            //TODO Add alert pop-up showing error info
        } else {
            // Else take the data received from the server and process it
            print("JSON DATA RECEIVED: " + responseString)
            
            // If not return of CREATE
            if !responseString.contains("db_") {
                // Take the response string and turn it back into raw data
                if let myData: Data = responseString.data(using: String.Encoding.utf8) {
                    do {
                        // Try to convert response data into a JSON dictionary to be saved into the optional dictionary
                        jsonObjects = try JSONSerialization.jsonObject(with: myData, options: []) as? [String: [[String:Any]]]
                        jsonArray = jsonObjects!["passport"]
                    } catch let parsingError {
                        print("Error: ", parsingError.localizedDescription)
                    }
                }
            }
        }
    }
}
