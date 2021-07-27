//
//  ViewController.swift
//  client
//
//  Created by Husnain Ali on 3/10/20.
//  Copyright © 2020 Husnain Ali. All rights reserved.
//

import UIKit
import SocketIO
import SwiftyJSON

struct Message {
    var sender: String
    var time: String
    var message: String
    var isSender: Bool
}

class ViewController: UIViewController {
    
    // MARK: - IBOutlet
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var onlinruserText: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Constants
    let name: String = "User \(Int.random(in: 1..<500))"
    let manager = SocketManager (socketURL: URL(string: "http://127.0.0.1:8080")!, config: [.log(true), .compress])
    let dateFormate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter
    }()
    
    // MARK: - Variables
    var socketClient: SocketIOClient!
    var messages = [Message]() {
        didSet {
            print("Updated messages on device")
            tableView.reloadData()
        }
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        self.textField.delegate = self
        
        super.viewDidLoad()
        
        // Connect Manager Handling
        socketClient = manager.defaultSocket
        
        // Check if socket connects
        socketClient.on("connected", callback: { data, emitter in
            print("Connected!!")
            self.append("\(self.name) connected")
        })
        
        // Check Online user
        onlinruserText.text = "\(name.capitalized) Online"
        
        // Check if message recieve by other users
        socketClient.on("message", callback: { data, emitter in
            let json = JSON(data)
            print(json)
            self.appendMessage(json)
        })

        // Connecting Socket
        socketClient.connect()
        
        // tableView settings
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: .zero)
    }
    
    // MARK: - IBAction
    @IBAction func btnSendTapped(_ sender: UIButton) {
        if let text = textField.text, text != "" {
            let date = Date()
            socketClient.emit("message", ["message": text, "sender": name, "time": dateFormate.string(from: date)])
            textField.text = ""
            append("\(text)")
        }
    }
    
    // MARK: - Custom Fucntions
    func append(_ message: String) {
        let date = Date()
        let messageData = Message(sender: self.name, time: dateFormate.string(from: date), message: message, isSender: true)
        messages.append(messageData)
    }
    
    func appendMessage(_ data: JSON) {
        if data.count > 0 {
            if let recieve = data.first?.1 {
                if recieve["message"].exists() {
                    let message = recieve["message"].stringValue
                    let sender = recieve["sender"].stringValue
                    let time = recieve["time"].stringValue
                    
                    // Append Data
                    let messageData = Message(sender: sender, time: time, message: message, isSender: false)
                    messages.append(messageData)
                }else {
                    append("\(recieve.stringValue) \(self.name)")
                }
            }
        }
    }
}

// MARK: - Extension
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        if messages[indexPath.row].isSender {
            cell.textLabel?.text = messages[indexPath.row].message
        } else {
            cell.textLabel?.text = messages[indexPath.row].sender + "\n" + messages[indexPath.row].message + "\n" + messages[indexPath.row].time
        }
        cell.textLabel?.textColor = messages[indexPath.row].isSender ? .gray : .black
        cell.textLabel?.textAlignment = messages[indexPath.row].isSender ? .right : .left 
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

