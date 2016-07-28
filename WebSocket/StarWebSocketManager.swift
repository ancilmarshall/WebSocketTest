//
//  StarWebSocketManager.swift
//  WebSocket
//
//  Created by Ancil Marshall on 27/07/16.
//  Copyright © 2016 Ancil Marshall. All rights reserved.
//

import Foundation
import Starscream
import ReactiveCocoa

class StarWebSocketManager {
    
    static let sharedInstance = StarWebSocketManager()
    var socket = WebSocket(url: NSURL(string: "http://62.210.217.219/openSocket")!)
    
    var speed : MutableProperty<String> = MutableProperty("0")

    func establishConnection(){
        socket.delegate = self
        socket.connect()
    }
    
    func closeConnection(){
        socket.disconnect()
    }
    
    func sendMessage(msg: String){
        socket.writeString(msg) { 
            print("Message sent")
        }
    }
    
    func sendCommand(cmd: Dictionary<String,String>){
        
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(cmd, options: .PrettyPrinted)
            socket.writeData(jsonData) {
                print("Command sent")
            }
        } catch let error as NSError {
            print("Failed to send command: \(error.localizedDescription)")
        }

    }
    
}


extension StarWebSocketManager : WebSocketDelegate {

    func websocketDidConnect(socket: WebSocket) {
        print("websocket is connected")
        
        //        let parameters = ["Type":"infos","UserToken":"42"]
        //        sendCommand(parameters)
        
        let parameters = ["Type":"start","UserToken":"42","CarName":"Z4"]
        sendCommand(parameters)
    }

    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("websocket did disconnect with error: \(error?.localizedDescription)")
    }

    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("websocket did receive data")
    }

    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        //print("websocket did receive message: \(text)")
        
        
        let data = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        
        // response to the info command
//        do {
//            let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! [Dictionary<String,AnyObject>]
//            for item in json {
//                if let name = item["name"] as? String {
//                    print(name)
//                }
//            }
//        } catch let error as NSError {
//            print("Failed to load: \(error.localizedDescription)")
//        }
        
        // response just for a single car
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! Dictionary<String,AnyObject>
            if let currentSpeed = json["Speed"] as? NSNumber {
                //print(currentSpeed)
                speed  = MutableProperty(String(format: "%.2f", currentSpeed.doubleValue))
            }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
        
        
    }
    
    
    

}