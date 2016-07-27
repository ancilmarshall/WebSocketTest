//
//  WebSocketManager.swift
//  WebSocket
//
//  Created by Ancil Marshall on 27/07/16.
//  Copyright © 2016 Ancil Marshall. All rights reserved.
//

import Foundation
import SocketIOClientSwift

class SocketIOManager : NSObject {
    
    static let sharedInstance = SocketIOManager()
    var socket: SocketIOClient = SocketIOClient(socketURL: NSURL(string: "http://192.168.63.38:3000")!)
    
    override init() {
        super.init()
    }
    
    func establishConnection(){
        listenToUserList()
        socket.connect()
    }
    
    func closeConnection(){
        socket.disconnect()
    }
    
    func listenToUserList(){
        socket.on("userList") { (dataArray, ack) -> Void in
            print("Event received")
            self.socket.emit("response","hello!")
        }
    }
    
    func sendMessage(msg: String){
        socket.emit("connectUser",msg)
    }
}


