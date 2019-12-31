//
//  InfoViewController.swift
//  PassportApp
//
//  Created by Luis Souza on 2019-11-27.
//  Copyright © 2019 Luis Henrique Souza. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    // MARK: Variables / Const
    @IBOutlet weak var txtViewInfo: UITextView!
    
    // Holds the object from previous tablewiew
    var jsonObj: [String: Any]?
    var jsonObjects: [String: [[String:Any]]]?
    var jsonArray: [[String:Any]]?
    var isEmpty: Bool = false

    let PATH = "https://lenczes.edumedia.ca/mad9137/final_api/passport/"
    let READ = "read/?id="

    // MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Check if record id != 0 (DB NOT empty)
        if jsonObj?["id"] as? Int != 0 {
            let _id = jsonObj?["id"] as? Int
            requestConn(url: PATH + READ + "\(_id ?? 0 )")
        } else {
            isEmpty = true
            txtViewInfo.text = "Empty Database!\nPlease return and tap on + button to add a new location."
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !isEmpty{
            let _title = jsonObj!["title"] as? String
            let _latitude = jsonObj!["latitude"] as? Double
            let _longitude = jsonObj!["longitude"] as? Double
            let _description = jsonObj!["description"] as? String
            let _dtArrival = jsonObj!["arrival"] as? String
            let _dtDeparture = jsonObj!["departure"] as? String

            self.txtViewInfo.text = "Title: \(_title!)\n\nDescription: \(_description!)\n\nLatitude: \(_latitude!)\n\nLongitude: \(_longitude!)\n\nArrival: \(_dtArrival!)\n\nDeparture: \(_dtDeparture!)"
        }
    }

    // MARK: Private Methods
    // Request Connection and Session
    func requestConn(url: String) -> Void {
        let requestUrl: URL = URL(string: url)!

        // Create the request object and pass in your url
        var myRequest: URLRequest = URLRequest(url: requestUrl)
        myRequest.addValue("mora0199", forHTTPHeaderField: "my-authentication")

        // Create the URLSession object that will make the request
        let mySession: URLSession = URLSession.shared

        // Make the specific task from the session by passing in your request, and the function that will be use to handle the request
        let myTask = mySession.dataTask(with: myRequest, completionHandler: requestTask)
        
        // Tell the task to run
        myTask.resume()
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
        }else{
            // Else take the data received from the server and process it
            print("JSON DATA RECEIVED: " + responseString)
            
            // Take the response string and turn it back into raw data
            if let myData: Data = responseString.data(using: String.Encoding.utf8) {
                do {
                    // Try to convert response data into a JSON dictionary to be saved into the optional dictionary
                    jsonObj = try JSONSerialization.jsonObject(with: myData, options: []) as? [String:Any]
                    print(jsonObj! as Any)

                } catch let parsingError {
                    print("Error: ", parsingError)
                }
            }
        }
    }
}
