//
//  PubSubDemoClient.swift
//  redisChat
//
//  Created by Justin Brady on 8/4/16.
//
//

import Foundation
import UIKit
import Redis
import Sockets

let urlDefault = "192.168.1.133"

class PubSubDemoClient : PubSubClient {
    
    var redbirdClient:TCPClient?
    var redbirdPipeline:Pipeline<TCPInternetSocket>?
    
    var channelMessages = Dictionary<String, Array<String>>()
    
    var delegate:PubSub?

    var clusterUrl = urlDefault
    
    let read_interval_usec = 100000
    
    var redbirdReaderQueue:DispatchQueue?
    
    init() {
    }
    
    func setDelegate(_ delegate:PubSub) {
        self.delegate = delegate
    }
    
    func connect(_ host:String) {
        
        self.clusterUrl = host
        
        do {
            try redbirdClient = TCPClient.init(hostname: host, port: 6379, password: nil)
        } catch {
            DebugLogger.log("Redbird connection failed", with: .warn)
        }
        
        self.delegate?.onConnected(self)
    }
    
    func disconnect() {
        redbirdClient = nil
    }
    
    func redisCommand(_ command:String, args:Array<String>) {
        // enqueue this command on a pipeline later executed in the reader/writer thread
        do {
            while self.redbirdPipeline != nil {
                // must wait for pipelined commands to finish
                usleep(UInt32(self.read_interval_usec / 2))
            }
            
            self.redbirdPipeline = self.redbirdClient?.makePipeline()
            
            var argsBytes: [Bytes] = []
            for arg in args {
                argsBytes.append(arg.bytes)
            }
            try redbirdPipeline?.enqueue(Command.custom(command.bytes), argsBytes)
        
        } catch {
            DebugLogger.log(String.localizedStringWithFormat("redisCommand: %@ failed", command), with: .warn)
        }
    }
    
    func redisReaderDispatch(_ handler:@escaping (PubSubClient, String, String) -> Void) {
        if (self.redbirdReaderQueue != nil) { return }
        
        let redisReadHandler:(TCPClient, String, String) -> Void = {
            (client, channel, msg) in
            handler(self, channel, msg)
        }
        
        let readBlock = {
            DebugLogger.log(String.localizedStringWithFormat("redisReader: dispatched"), with: .warn)

            while true {
                // execute any pipelined commands
                do {
                    if self.redbirdPipeline != nil {
                        try self.redbirdPipeline?.execute()
                        DebugLogger.log("redisReader: pipeline executed", with: .debug)
                        self.redbirdPipeline = nil
                        continue
                    }
                } catch {
                    DebugLogger.log("redisReader: pipeline execute failed (\(error))", with: .warn)
                    usleep(UInt32(self.read_interval_usec))
                    continue
                }
                
                for chan in self.channelMessages.keys {
                    
                    while true {
                        do {
                            if let resultData = try self.redbirdClient?.command(Command.custom("LLEN".bytes), [chan.bytes])
                            {
                                let len = resultData.int!
                                
                                while self.channelMessages[chan]!.count != len {
                        
                                    let idx = (len - self.channelMessages[chan]!.count)-1
                                    let cmd = Command.custom("LINDEX".bytes)
                                    let argStr = String.localizedStringWithFormat("%d", idx)
                                    if let resp = try self.redbirdClient?.command(cmd,
                                                                                  [chan.bytes, argStr.bytes])?.string
                                    {
                                        self.channelMessages[chan]?.append(resp)
                                        
                                        DispatchQueue.main.async(execute: {
                                            redisReadHandler(self.redbirdClient!, chan, resp)
                                        })
                                    }
                                }
                            }
                            else {
                                // key does not exist
                                DebugLogger.log("redisReader: key doesn't exist", with: .debug)
                            }
                        } catch {
                            DebugLogger.log(String.localizedStringWithFormat("redisReader: read failed \(error) on channel \(chan)"), with: .debug)
                        }
                        break
                    }
                }
                usleep(UInt32(self.read_interval_usec))
            }
        }
        
        self.redbirdReaderQueue = DispatchQueue(label: "redisReaderQueue")
        self.redbirdReaderQueue?.async(execute: { readBlock() })
    }
    
    func subscribe(_ channel:String, subscribeOnReconnected:Bool, onMessage:@escaping (PubSubClient, String, String) -> Void) {
        
        self.delegate?.onSubscribed(self, channel: channel)
        
        channelMessages[channel] = Array<String>()
        
        redisReaderDispatch(onMessage)
    }
    
    func send(_ channel:String, message:String) {
        redisCommand("LPUSH", args:[channel, String.localizedStringWithFormat("%@", message)])
    }
}

class PubSubDemo: PubSub {
    var client:PubSubDemoClient?
    
    override init() {
        client = PubSubDemoClient()
        super.init(client: client!)
        client?.setDelegate(self)
    }
    
    func subscribe(_ channel:String, subscribeOnReconnected:Bool, onMessage:@escaping PubSubMessageHandler) {
        let msgHandler:(PubSubClient, String, String) -> Void = {(client, channel, msg) in
            let pubSubMsg = PubSubMessage(message:msg, info:"")
            onMessage(pubSubMsg, channel)
        }
        client?.subscribe(channel, subscribeOnReconnected: subscribeOnReconnected, onMessage: msgHandler)
    }
    
    func send(_ channel:String, message:String) {
        client?.send(channel, message: message)
    }
}

