//
//  ViewController.swift
//  WebSocket
//
//  Created by Ancil Marshall on 27/07/16.
//  Copyright © 2016 Ancil Marshall. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var socket = StarWebSocketManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        socket.establishConnection()
        
//        let jsonStr = "{\"Type\" : \"infos\", \"UserToken\" : \"42\"}"
//        socket.sendMessage(jsonStr)
        
//        let parameters = ["Type":"infos","UserToken":"42"]
//        socket.sendJSON(parameters)
        
    }

}

