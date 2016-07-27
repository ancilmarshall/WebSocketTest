//
//  ViewController.swift
//  WebSocket
//
//  Created by Ancil Marshall on 27/07/16.
//  Copyright © 2016 Ancil Marshall. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var socket = SocketIOManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        socket.establishConnection()
        socket.sendMessage("Hello")
        
    }

}

