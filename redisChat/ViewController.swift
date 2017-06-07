//
//  ViewController.swift
//  redisChat
//
//  Created by Justin Brady on 6/5/17.
//
//

import UIKit
import Redis

class ViewController: UITableViewController {
    
    var pubSub: PubSubDemo = PubSubDemo()
    var chatTable: ChatTableViewAndDelegateDataSource?
    
    let channels = ["room1"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        chatTable = tableView as? ChatTableViewAndDelegateDataSource
        
        NotificationCenter.default.addObserver(self, selector: #selector(onSendMessage),
                                               name: ChatTableViewCell.sendButtonNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        pubSub.connectWith(urlDefault, channelSubscriptions: channels, receiveHandler:
            {
                (args) in
                
                let msg = ChatTableViewAndDelegateDataSource.Message(text: args.0.msg, data: nil, sender: "")
                
                self.chatTable?.messages.append(msg)
                
                DispatchQueue.main.async(execute: {
                    self.chatTable?.reloadData()
                })
        })
        
        //pubSub.send(channels[0], message: "Test message")
        pubSub.sendMessage("test message", channel: channels[0])
    }
    
    func onSendMessage(notification: AnyObject?) {
        guard let cell = notification?.object as? ChatTableViewCell, let message = cell.textView?.text
            else {
            return
        }
        
        pubSub.sendMessage(message, channel: channels[0])
    }
}

