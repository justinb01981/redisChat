//
//  PubSubClient.swift
//  redisChat
//
//  Created by Justin Brady on 7/28/16.
//
//

import Foundation

public struct PubSubMessage {
    public init(message:String, info:String) {
        self.msg = message
        self.info = info
    }
    
    public var msg:String
    public var info:String
}

public protocol PubSubClientDelegate {
    
}

public typealias PubSubMessageHandler = (PubSubMessage, String) -> (Void)

public protocol PubSubClient {
    
    func connect(_ host:String)
    func disconnect()
    
    func subscribe(_ channel:String, subscribeOnReconnected:Bool, onMessage:@escaping (PubSubClient, String, String) -> Void)
    
    func send(_ channel:String, message:String)
}

open class PubSub
{
    let msgBeginTag = "__PubSubMSGBEGIN__"
    let msgEndTag = "__PubSubMSGEND__"
    let msgMaxLen = 512
    
    var pubSubClient:PubSubClient?
    var subscriptions:Array<String> = []
    var messages:Dictionary<String, Array<PubSubMessage> > = [:]
    var messagesSent:Dictionary<String, Array<PubSubMessage> > = [:]
    open var receiveHandler:PubSubMessageHandler?
    
    public init() {
    }
    
    public init(client:PubSubClient) {
        // call configure
        pubSubClient = client
    }
    
    open func connectWith(_ url:String,
                   channelSubscriptions:Array<String>,
                   receiveHandler:@escaping PubSubMessageHandler = {_ in }) {
        
        self.subscriptions = channelSubscriptions
    
        self.pubSubClient!.connect(url)
        
        self.receiveHandler = receiveHandler
    }
    
    open func disconnect() {
        self.pubSubClient?.disconnect()
    }
    
    var msgPending:Dictionary<String, String> = Dictionary<String, String>()
    
    open func onConnected(_ ortc: PubSubClient) {
        
        for channel in subscriptions {
            let receiveHandler:(PubSubClient, String, String) -> Void = { (ortcClient, channel, msgBlock) in
                
                DebugLogger.log("PubSub.receiveHandler: msg in channel \(channel): \(msgBlock)", with: .debug)
                
                guard let msgIdBegin = msgBlock.range(of: "<id>"),
                let msgIdEnd = msgBlock.range(of: "</id>")
                    else {
                        return
                }
                
                var msgId = "garbage"
                
                msgId = msgBlock.substring(with: msgIdBegin.upperBound ..< msgIdEnd.lowerBound)

                var msgBucket = self.msgPending[msgId]
                
                if msgBucket == nil {
                    self.msgPending[msgId] = String()
                    msgBucket = self.msgPending[msgId]
                }
                
                //msgBucket?.append(msgBlock.substring(with: msgIdEnd!.upperBound..<msgBlock.endIndex))
                msgBucket?.append(msgBlock.substring(with: msgIdEnd.upperBound ..< msgBlock.endIndex))

                if (msgBucket?.contains("</msg>") == true) {
                    msgBucket = msgBucket!.substring(with: msgBucket!.startIndex ..< (msgBucket!.endIndex))
                }
                else {
                    self.msgPending[msgId] = msgBucket
                    return
                }
                
                let msgCompleted = msgBucket!
                
                DebugLogger.log("PubSub.receiveHandler: got msgCompleted of length \(msgCompleted.characters.count)", with: .debug)
                
                self.msgPending[msgId] = nil
                
                //DebugLogger.log(String.localizedStringWithFormat("PubSubMessage.recv(%u):\n_______\n%@\n______", msgCompleted.characters.count, msgCompleted), withLevel: DebugLoggerLevelDebug)
                let msgStruct = PubSubMessage(message: msgCompleted, info:"")
                self.messages[channel]?.append(msgStruct)
                self.receiveHandler?(msgStruct, channel)
            }
            
            ortc.subscribe(channel, subscribeOnReconnected: true, onMessage: receiveHandler)
        }
    }
    
    open func onDisconnected(_ ortc: PubSubClient) {
    }
    
    open func onSubscribed(_ ortc: PubSubClient, channel: String) {
        self.messages[channel] = Array<PubSubMessage>()
        self.messagesSent[channel] = Array<PubSubMessage>()
    }
    
    open func onUnsubscribed(_ ortc: PubSubClient, channel: String) {
    }
    
    open func onException(_ ortc: PubSubClient, error: NSError) {
    }
    
    open func onReconnected(_ ortc: PubSubClient) {
    }
    
    open func onReconnecting(_ ortc: PubSubClient) {
    }
    
    func generateMsgID() -> String {
        return String.localizedStringWithFormat("msg.%u.%u", time(nil), arc4random())
    }
    
    open func sendMessage(_ _msgUTF8:String, channel:String) {
        DispatchQueue.main.async(execute: {
            let msgUTF8 = _msgUTF8 + "</msg>"
            let msgId = self.generateMsgID()
            
            let m = PubSubMessage(message:_msgUTF8, info:"")
            
            var i = 0
            let msgDataLen = msgUTF8.characters.count
            
            var totalSent = 0
            while (i < msgDataLen)
            {
                var blockLen = (msgDataLen - i)
                if (blockLen > self.msgMaxLen) { blockLen = self.msgMaxLen }

                let block = msgUTF8.substring(with: msgUTF8.index(msgUTF8.startIndex, offsetBy: i) ..< msgUTF8.index(msgUTF8.startIndex, offsetBy: i+blockLen))
                let msgBlock = String.localizedStringWithFormat("<id>%@</id>%@",
                    msgId, block)
                
                self.pubSubClient?.send(channel, message: msgBlock)
                i += blockLen
                totalSent += blockLen
            }
            
            self.messagesSent[channel]?.append(m)
            })
    }
}
