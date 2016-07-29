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
    
    func startSignal(producer: SignalProducer<(Bool, String, WebSocket, ServerCmdType), NSError>){
        
        producer.startWithSignal { (signal, disposable) in
            
            signal.observe(Signal.Observer { event in
                switch event {
                case let .Next( resp ):
                    
                    let isOk = resp.0
                    let name = resp.1
                    let socket = resp.2
                    let type = resp.3
                    
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

    func establishConnection(){
        
        let onConnectionSignal = createOnConnectSignal( "info", socket: self.socket, cmdType: .Info)
        startSignal(onConnectionSignal);
        
        let onTextSignal = createOnTextSignal()
        onTextSignal.startWithSignal { (signal, disposable) in

            signal.observe(Signal.Observer { event in
                switch event {
                case let .Next(resp):
                    let data = resp.0
                    let cmdType = resp.1
                    
                    if (cmdType == .Info){
                        if let listOfCars = data as? Array<CarModel> {

                            //self.commandStart(self.socket, forCar: listOfCars[0].name)
                            let newSocket = WebSocket(url: NSURL(string:kWebServerURL)!)
                            let newConnectionSignal = self.createOnConnectSignal(listOfCars[0].name , socket: newSocket, cmdType: .Start)
                            self.startSignal(newConnectionSignal);
                            self.sockets.append(newSocket)
                            self.producers.append(newConnectionSignal)
                            newSocket.connect()
                            
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
    
    func createOnConnectSignal (name:String, socket:WebSocket, cmdType: ServerCmdType) -> SignalProducer<(Bool, String, WebSocket, ServerCmdType), NSError> {
        return SignalProducer { (observer, disposable) in
            self.socket.onConnect = {
                observer.sendNext((true,name,socket,cmdType))
                observer.sendCompleted()
            }
        }
    }
    
    func createOnTextSignal () -> SignalProducer<(AnyObject,ServerCmdType),NSError>{
        
        return SignalProducer { (observer, disposable) in
            
            // lift the closure
            self.socket.onText = { text in
                let data = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
                var cars = Array<CarModel>()
                
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                    
                    // need to do a better job here to know which command type was executed (without using a saved boolean)
                    if json is [Dictionary<String,AnyObject>] {
                        let jsonData = json as! [Dictionary<String,AnyObject>]
                        for item in jsonData {
                            
                            //TODO: Use guard instead of as!
                            let name = item["name"] as! String
                            let brand = item["brand"] as! String
                            let power = item["power"] as! Int
                            let maxSpeed = item["maxSpeed"] as! Int
                            
                            let car = CarModel(name: name, brand:brand, power: power, maxSpeed: maxSpeed, currentSpeed: nil)
                            cars.append(car)
                        }
                        
                        observer.sendNext((cars,ServerCmdType.Info))
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
//
//extension StarWebSocketManager : WebSocketDelegate {
//    func websocketDidConnect(socket: WebSocket) {
//    }
//
//    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
//        print("websocket did disconnect with error: \(error?.localizedDescription)")
//    }
//
//    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
//        print("websocket did receive data")
//    }
//
//    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
//    }
//}