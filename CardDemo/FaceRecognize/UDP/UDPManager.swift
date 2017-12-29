//
//  UDPManager.swift
//  VideoDemo
//
//  Created by rayootech on 2017/7/20.
//  Copyright © 2017年 demon. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class UDPManager: NSObject, GCDAsyncUdpSocketDelegate {

    private let port: UInt16 = 7667
    private let host = "10.90.7.10"
    private var udp: GCDAsyncUdpSocket?
    private let delegateQueue = DispatchQueue.global()
    override init() {
        super.init()
        
        udp = GCDAsyncUdpSocket(delegate: self, delegateQueue: delegateQueue)
    }
    
    deinit {
        udp?.close()
    }
    
    // MARK: - GCDAsyncUdpSocketDelegate
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
       
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {

    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
    
    }
    
    // MARK: - public methods
    
    func send(data: Data) {
        udp?.send(data, toHost: host, port: port, withTimeout: -1, tag: 0)
    }
    
}
