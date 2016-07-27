//
//  StarWebSocketManager.swift
//  WebSocket
//
//  Created by Ancil Marshall on 27/07/16.
//  Copyright © 2016 Ancil Marshall. All rights reserved.
//

import Foundation
import Starscream


class StarWebSocketManager {
    
    static let sharedInstance = StarWebSocketManager()
    var socket = WebSocket(url: NSURL(string: "http://192.168.63.38:3000")!)
    //var socket = WebSocket(url: NSURL(string: "http://62.210.217.219/openSocket")!)

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
}


extension StarWebSocketManager : WebSocketDelegate {

    func websocketDidConnect(socket: WebSocket) {
        print("websocket is connected")
    }

    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("websocket did disconnect")
    }

    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("websocket did receive data")
    }

    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("websockete did receive message")
    }

}