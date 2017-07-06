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
    
    var channel:String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        chatTable = tableView as? ChatTableViewAndDelegateDataSource
        
        NotificationCenter.default.addObserver(self, selector: #selector(onSendMessage),
                                               name: ChatTableViewCell.sendButtonNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onConnect),
                                               name: ConnectTableViewCell.connectNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func onSendMessage(notification: AnyObject?) {
        guard let cell = notification?.object as? NewMessageTableFooterViewCell, let message = cell.textField?.text, let channel = channel
            else {
            return
        }
        
        pubSub.sendMessage(message, channel: channel)
        
        chatTable?.reloadData()
    }
    
    func onConnect(notification: AnyObject?) {
        guard let cell = notification?.object as? ConnectTableViewCell,
            let address = cell.textField?.text,
            let nickname = cell.textField2?.text,
            let channel = cell.textField3?.text
            else {
                return
        }
        
        self.channel = channel
        
        pubSub.connectWith(address, channelSubscriptions: [channel], receiveHandler:
            {
                (args) in
                
                let msg = ChatTableViewAndDelegateDataSource.Message(text: args.0.msg, data: nil, sender: "")
                
                self.chatTable?.messages.append(msg)
                
                DispatchQueue.main.async(execute: {
                    self.chatTable?.connected = true
                    self.chatTable?.reloadData()
                })
        })
    }
}

