//
//  ViewController.swift
//  WebSocket
//
//  Created by Ancil Marshall on 27/07/16.
//  Copyright © 2016 Ancil Marshall. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    
    var socket = WebSocketManager.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        socket.establishConnection()
        socket.sendMessage("Hello")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

