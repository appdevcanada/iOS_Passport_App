//
//  PassportTableViewController.swift
//  PassportApp
//
//  Created by Luis Souza on 2019-11-27.
//  Copyright © 2019 Luis Henrique Souza. All rights reserved.
//

import UIKit

class PassportTableViewController: UITableViewController {

    // MARK: Variables / Const
    @IBOutlet weak var btnAdd: UIBarButtonItem!
    var jsonObjects: [String: [[String:Any]]]?
    var jsonArray: [[String:Any]]?
    var isReading: Bool = true
    
    let HOST = "https://lenczes.edumedia.ca/"
    let PATH = "https://lenczes.edumedia.ca/mad9137/final_api/passport/"
    let CREATE = "create/?data="
    let READ = "read/"
    let DELETE = "delete/?id="
    
    @IBAction func btnAdd(_ sender: Any?) {
        performSegue(withIdentifier: "AddViewController", sender: self)
    }
    
    // MARK: View Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Update the tableView with the data in the JSON dictionary
        self.tableView!.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        requestConn(url: PATH + READ, isReading: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if isReading {
            requestConn(url: PATH + READ, isReading: true)
        }
    }
    
    // MARK: Private Methods
    // Request Connection and Session
    func requestConn(url: String, isReading: Bool) -> Void {
        
        self.isReading = isReading
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
        } else {
            // Else take the data received from the server and process it
            print("JSON DATA RECEIVED: " + responseString)
            
            // If not return of DELETE
            if isReading {
                // Take the response string and turn it back into raw data
                if let myData: Data = responseString.data(using: String.Encoding.utf8) {
                    do {
                        // Try to convert response data into a JSON dictionary to be saved into the optional dictionary
                        jsonObjects = try JSONSerialization.jsonObject(with: myData, options: []) as? [String: [[String:Any]]]
                        jsonArray = jsonObjects!["locations"]
                    } catch let parsingError {
                        print("Error: ", parsingError.localizedDescription)
                    }
                }
                
                // UI updates need to be made on the main thread
                DispatchQueue.main.async {
                    // Update the tableView with the data in the JSON dictionary
                    self.tableView!.reloadData()
                }
                
            } else {
                requestConn(url: PATH + READ, isReading: true)
            }
        }
    }
    
    // Function to Delete data in the database with ID
    func deleteLocation(id: Int) -> Void {
        requestConn(url: PATH + DELETE + String(id), isReading: false)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if jsonArray?.count == 0 || jsonArray == nil {
            return 0
        } else {
            return jsonArray!.count - (jsonArray!.count - 1)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var cellCount = 0
        
        // Use optional binding to return the count of the jsonObjects array
        if let jsonObj = jsonArray {
            cellCount = jsonObj.count
        }
        
        return cellCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recLocations", for: indexPath)
        if let jsonObj = jsonArray{
            
            // For the current tableCell row get the corresponding location dictionary
            let dictionaryRow = jsonObj[indexPath.row] as [String:Any]
            
            // Get the name and overview for the current planet
            let title = dictionaryRow["title"] as? String
            
            // Add the name and overview to the cell's textLabel
            cell.textLabel?.text = title
        }

        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            if let jsonObj = jsonArray{
                // For the current tableCell row get the corresponding location dictionary
                let dictionaryRow = jsonObj[indexPath.row]
                // Call the Delete function passing the ID (not the row index)
                deleteLocation(id: dictionaryRow["id"] as! Int)
                // UI updates need to be made on the main thread
                DispatchQueue.main.async {
                    // Update the tableView with the data in the JSON dictionary
                    self.tableView!.reloadData()
                }
            }
        }
    }

    // MARK: - Storyboard Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {

        case "showInfo":
            // Get a reference to the next viewController class
            let nextVC = segue.destination as? InfoViewController
            
            // Get a reference to the cell that was clicked
            let thisCell = sender as? UITableViewCell
            
            // Set the locationID value of the next viewController
            let locationID = tableView.indexPath(for: thisCell!)!.row
            
            // Use optional binding to access the JSON dictionary if it exists
            if let jsonObj = jsonArray{
                nextVC?.jsonObj = jsonObj[locationID] as [String:Any]
            }
        case "showAdd":
            isReading = true

        default:
            print("Nothing")
        }
    }
    
}
