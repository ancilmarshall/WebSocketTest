//
//  CarModel.swift
//  WebSocket
//
//  Created by Ancil Marshall on 29/07/16.
//  Copyright © 2016 Ancil Marshall. All rights reserved.
//

import Foundation

class CarModel {
    
    let name: String
    let brand: String
    let power: Int
    let maxSpeed: Int
    let currentSpeed: Double?
    
    init(name:String, brand: String, power: Int, maxSpeed:Int, currentSpeed:Double?)
    {
        self.name = name
        self.brand = brand
        self.power = power
        self.maxSpeed = maxSpeed
        self.currentSpeed = currentSpeed
    }
    
}