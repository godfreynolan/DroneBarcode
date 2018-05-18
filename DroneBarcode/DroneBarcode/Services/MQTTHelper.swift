//
//  MQTTHelper.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 5/18/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import CocoaMQTT

class MQTTHelper: CocoaMQTTDelegate {
    var mqtt: CocoaMQTT!
    
    init() {
        self.mqtt = CocoaMQTT(clientID: "iPad", host: "10.5.2.16", port: 1883)
//        self.mqtt.username = ""
//        self.mqtt.password = ""
//        self.mqtt.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
//        self.mqtt.keepAlive = 60
//        self.mqtt.allowUntrustCACertificate = true
        self.mqtt.delegate = self
        self.mqtt.connect()
    }
    
    func sendMessage(_ barcodeData: String) {
        self.mqtt.publish("barcode", withString: barcodeData)
    }
    
    func disconnect() {
        self.mqtt.disconnect()
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("Connection Result: \(ack.description)")
        
        if ack == CocoaMQTTConnAck.accept {
            print("Accepted")
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("Message published")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublish")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        print("Received message")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("subscribed")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("unsubscribed")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("didPing")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("didReceivePong")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print("Disconnected")
    }
}
