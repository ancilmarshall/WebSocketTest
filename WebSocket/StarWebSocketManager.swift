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

let kWebServerURL = "http://62.210.217.219/openSocket"

class StarWebSocketManager {

    static let sharedInstance = StarWebSocketManager()
    var socket = WebSocket(url: NSURL(string:kWebServerURL)!)
    var sockets = Array<WebSocket>()
    var producers = Array<SignalProducer<(Bool, String, WebSocket, ServerCmdType), NSError>>()
    
    var speed : MutableProperty<String> = MutableProperty("0")
    
    //MARK: - WebSocketManager API
    
    //addSocket
    //removeSocket
    //
    
    func establishConnection(){
        
        let onConnectionSignal = createOnConnectSignal( "info", socket: self.socket, cmdType: .Info)
        startOnConnectSignal(onConnectionSignal);
        
        let onTextSignal = createOnTextSignal("start",self.socket,cmdType:.Info)
        startOnTextSignal(onTextSignal)
        
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
    
    //MARK:- Sinks when signal events are received
    
    func startOnConnectSignal(producer: SignalProducer<(Bool, String, WebSocket, ServerCmdType), NSError>){
        
        producer.startWithSignal { (signal, disposable) in
            
            signal.observe(Signal.Observer { event in
                switch event {
                case let .Next( resp ):
                    
                    let isOk = resp.isOk
                    let name = resp.name
                    let socket = resp.socket
                    let type = resp.type
                    
                    if (isOk){
                        
                        if type == .Info {
                            print("websocket is connected")
                            self.commandInfo(socket)
                        } else if type == .Start {
                            self.commandStart(socket, forCar: name)
                        }
                        
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
    }
    
    
    func startOnTextSignal(producer: SignalProducer<(String, String, WebSocket,ServerCmdType),NSError>){
        
        producer.startWithSignal { (signal, disposable) in
            
            signal.observe(Signal.Observer { event in
                switch event {
                case let .Next(resp):
                    let text = resp.text
                    let name = resp.name
                    let socket = resp.socket
                    let type = resp.type
                    
                    
                    let data = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
                    var json: AnyObject
                    
                    //can I use guard here instead so that I escape right away?
                    do {
                        json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                    } catch let error as NSError {
                        print("Failed to serialize json object : \(error.localizedDescription)")
                    }
                    
                    switch type {
                        
                    case .Info:
                        let jsonData = json as! [Dictionary<String,AnyObject>]
                        
                        var cars = Array<CarModel>()
                        
                        for item in jsonData {
                            //TODO: Use guard instead of as!
                            let name = item["name"] as! String
                            let brand = item["brand"] as! String
                            let power = item["power"] as! Int
                            let maxSpeed = item["maxSpeed"] as! Int
                            
                            let car = CarModel(name: name, brand:brand, power: power, maxSpeed: maxSpeed, currentSpeed: nil)
                            cars.append(car)
                            
                            let newSocket = WebSocket(url: NSURL(string:kWebServerURL)!)
                            let newConnectionSignal = self.createOnConnectSignal(car.name , socket: newSocket, cmdType: .Start)
                            self.startOnConnectSignal(newConnectionSignal);
                            let newTextSignal = self.createOnTextSignal(car.name, socket:newSocket, cmdType: .Start)
                            self.startOnTextSignal(newTextSignal)
                            self.sockets.append(newSocket)
                            self.producers.append(newConnectionSignal)
                            newSocket.connect()
                        }
            
                    case .Start:
                        // change the as! to an if let or guard
                        let jsonData = json as! Dictionary<String,AnyObject>
                        if let carSpeed = jsonData["Speed"] as? NSNumber {
                                //return this self.speed as a return value instead
                                //this is not self.speed, but a car.speed
                                self.speed.swap(String(format: "%.2f",carSpeed.doubleValue))
                            }
                    default:
                        print("Unknown SocketCmdType")
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
        
    }


    
    //MARK: - Websocket Delegate API as SignalProducers
    //TODO: put these in a Protocol
    func createOnConnectSignal (name:String, socket:WebSocket, cmdType: ServerCmdType)
        -> SignalProducer<(isOk: Bool, name: String, socket: WebSocket, type: ServerCmdType), NSError> {
        return SignalProducer { (observer, disposable) in
            socket.onConnect = {
                observer.sendNext((true,name,socket,cmdType))
                observer.sendCompleted()
            }
        }
    }
    
    func createOnTextSignal (name:String, socket:Websocket, cmdType: ServerCmdType)
        -> SignalProducer<(text: String, name: String, socket: WebSocket,type: ServerCmdType),NSError>{
        return SignalProducer { (observer, disposable) in
            socket.onText = { text in
                observer.sendNext((text,name,socket,cmdType))
                //observer.sendCompleted() // not sure when to use this
            }
        }
    }
    
    func createOnDataSignal (name:String, socket:Websocket, cmdType: ServerCmdType)
        -> SignalProducer<(data:NSData, name:String, socket: WebSocket, type: ServerCmdType),NSError>{
        return SignalProducer { (observer, disposable) in
            socket.onData = { data in
                observer.sendNext((data,name,socket,cmdType))
                //observer.sendCompleted() //not sure when to use this
            }
        }
    }
    
    func createOnDisconnectSignal (name:String, socket:Websocket )
        -> SignalProducer<(isOK: Bool, name: String, socket: Websocket), NSError>{
        return SignalProducer { (observer, disposable) in
            socket.onDisconnect = { error in
                observer.sendNext((true,name,socket))
                observer.sendCompleted()
            }
        }
    }
}

