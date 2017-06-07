//
//  ChatViews.swift
//  redisChat
//
//  Created by Justin Brady on 6/5/17.
//
//

import Foundation
import UIKit

class ChatTableViewAndDelegateDataSource: UITableView, UITableViewDelegate, UITableViewDataSource
{
    struct Message {
        var text: String = ""
        var data: Data?
        var sender: String = ""
    }
    
    var messages = Array<Message>()
    
    public override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }
    
    func configure() {
        self.delegate = self
        self.dataSource = self
        
        separatorStyle = .singleLine
        separatorInset.left = -20
        
        messages = [Message(text: "<new message>", data: nil, sender: "")]
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = dequeueReusableCell(withIdentifier: ChatTableViewCell.ReuseIdentifier, for: indexPath) as? ChatTableViewCell
            else {
                return UITableViewCell()
        }
        
        cell.configure(message: messages[indexPath.row].text)
        
        return cell
    }
}

@IBDesignable class ChatTableViewCell: UITableViewCell {
    static let ReuseIdentifier = "ChatTableViewCellReuseID"
    static let sendButtonNotification = Notification.Name("ChatTableViewCellNotification")
    
    @IBOutlet var textView: UITextView?
    @IBOutlet var sender: UILabel?
    @IBOutlet var avatar: UIImageView?
    @IBOutlet var sendButton: UIButton?
    
    func configure(message msg: String)
    {
        textView?.text = msg
        sendButton?.isHidden = !msg.equals(caseInsensitive: "<new message>")
    }
    
    @IBAction func onButton() {
        textView?.endEditing(true)
        let notification = Notification(name: ChatTableViewCell.sendButtonNotification, object: self,
                                             userInfo: ["text": textView?.text as Any])
        NotificationCenter.default.post(notification)
    }
}
