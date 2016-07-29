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


enum ServerCmdType {
    case Info
    case Start
}

class StarWebSocketManager {
    
    //TODO: remove
    let infoOnly = false
    
    static let sharedInstance = StarWebSocketManager()
    var socket = WebSocket(url: NSURL(string: "http://62.210.217.219/openSocket")!)
    
    var speed : MutableProperty<String> = MutableProperty("0")

    func establishConnection(){
        
        let onConnectionSignal = createOnConnectSignal()
        onConnectionSignal.startWithSignal { (signal, disposable) in
            
            signal.observe(Signal.Observer { event in
                switch event {
                case let .Next( isOk):
                    if (isOk){
                        print("websocket is connected")
                        self.commandInfo(self.socket)
                    } else {
                        print("Connection is NOK")
                    }
                case let .Failed(error):
                    print("Failed: \(error)")
                case .Completed:
                    print("Completed")
                case .Interrupted:
                    print("Interrupted")
                }
                })
        }
        
        let onTextSignal = createOnTextSignal()
        onTextSignal.startWithSignal { (signal, disposable) in

            signal.observe(Signal.Observer { event in
                switch event {
                case let .Next(resp):
                    let cmdType = resp.1
                    let data = resp.0
                    
                    if (cmdType == .Info){
                        if let listOfCars = data as? Array<String> {
                            self.commandStart(self.socket, forCar: listOfCars[0])
                        }
                    } else if (cmdType == .Start){
                        if let carSpeed = data as? NSNumber {
                            self.speed.swap(String(format: "%.2f",carSpeed.doubleValue))
                        }
                    }
                    
                case let .Failed(error):
                    print("Failed: \(error)")
                case .Completed:
                    print("Completed")
                case .Interrupted:
                    print("Interrupted")
                }
                })

        }
        
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
    
    func sendCommand(command: Dictionary<String,String>, toSocket socket: WebSocket){
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(command, options: .PrettyPrinted)
            socket.writeData(jsonData) {
                print("Command sent")
            }
        } catch let error as NSError {
            print("Failed to send command: \(error.localizedDescription)")
        }
    }
    
    func commandInfo(socket: WebSocket)->Void {
        let command = ["Type":"infos","UserToken":"42"]
        sendCommand(command, toSocket: socket)
    }
    
    func commandStart(socket:WebSocket, forCar name: String)->Void {
        let command = ["Type":"start","UserToken":"42","CarName":name]
        sendCommand(command, toSocket: socket)
    }
    
    //MARK: - Websocket Delegate API as SignalProducers
    
    func createOnConnectSignal () -> SignalProducer<Bool, NSError> {
        return SignalProducer { (observer, disposable) in
            self.socket.onConnect = {
                observer.sendNext(true)
                observer.sendCompleted()
            }
        }
    }
    
    func createOnTextSignal () -> SignalProducer<(AnyObject,ServerCmdType),NSError>{
        
        return SignalProducer { (observer, disposable) in
            
            // lift the closure
            self.socket.onText = { text in
                let data = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
                var names = Array<String>()
                
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                    
                    // need to do a better job here to know which command type was executed (without using a saved boolean)
                    if json is [Dictionary<String,AnyObject>] {
                        let jsonData = json as! [Dictionary<String,AnyObject>]
                        for item in jsonData {
                            if let name = item["name"] as? String {
                                names.append(name)
                            }
                        }
                        
                        observer.sendNext((names,ServerCmdType.Info))
                        //observer.sendCompleted()
                        
                    } else if json is Dictionary<String,AnyObject> {
                        let jsonData = json as! Dictionary<String,AnyObject>
                        if let currentSpeed = jsonData["Speed"] as? NSNumber {
                            observer.sendNext((currentSpeed,ServerCmdType.Start))
                            //observer.sendCompleted()
                        }
                    }
                    
                } catch let error as NSError {
                    print("Failed to load: \(error.localizedDescription)")
                }
            }
        }
    }
}

//MARK:- WebSocket Delegate

extension StarWebSocketManager : WebSocketDelegate {
    func websocketDidConnect(socket: WebSocket) {
    }

    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("websocket did disconnect with error: \(error?.localizedDescription)")
    }

    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("websocket did receive data")
    }

    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
    }

}