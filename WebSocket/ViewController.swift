//
//  ViewController.swift
//  WebSocket
//
//  Created by Ancil Marshall on 27/07/16.
//  Copyright © 2016 Ancil Marshall. All rights reserved.
//

import UIKit
import ReactiveCocoa

class ViewController: UIViewController {
    
    var socketManager = StarWebSocketManager.sharedInstance
    @IBOutlet weak var speedLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bindViewModel()
        socketManager.establishConnection()
    }
    
    func bindViewModel() {
        speedLabel.rac_text <~ socketManager.speed
    }

}

