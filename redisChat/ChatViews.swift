//
//  ChatViews.swift
//  redisChat
//
//  Created by Justin Brady on 6/5/17.
//
//

import Foundation
import UIKit

// -- mark: constants

let ChatTableReuseIdClassDict: Dictionary<String, AnyClass> = [
    "ChatTableViewCellReuseID": ChatTableViewCell.classForCoder(),
    "ConnectTableViewCellReuseID": ConnectTableViewCell.classForCoder(),
    "NewMessageTableFooterViewCellReuseID": NewMessageTableFooterViewCell.classForCoder()
]

// -- mark: table view / table view controller

class ChatTableViewAndDelegateDataSource: UITableView, UITableViewDelegate, UITableViewDataSource
{
    struct Message {
        var text: String = ""
        var data: Data?
        var sender: String = ""
    }
    
    var messages = Array<Message>()
    var connected: Bool = false
    
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
        
        register(UINib.init(nibName: "NewMessageTableFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "NewMessageTableFooterViewCellReuseID")
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !connected {
            return 1
        }
        return messages.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var text = ""
        var reuseID = ""
        var cellReturn: ChatTableViewCell
        
        if !connected {
            reuseID = "ConnectTableViewCellReuseID"
            guard let cell = dequeueReusableCell(withIdentifier: reuseID, for: indexPath) as? ConnectTableViewCell
                else {
                    return UITableViewCell()
            }
            
            cellReturn = cell
        }
        else {
            
            reuseID = "ChatTableViewCellReuseID"
            text = messages[indexPath.row].text
            
            guard let cell = dequeueReusableCell(withIdentifier: reuseID, for: indexPath) as? ChatTableViewCell
                else {
                    return UITableViewCell()
            }
            
            cellReturn = cell
        }
        
        cellReturn.configure(message: text)
        
        return cellReturn
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var text = "empty"
        if indexPath.row < messages.count && !messages[indexPath.row].text.isEmpty {
            text = messages[indexPath.row].text
        }
        return ChatTableViewCell.calcHeight(text)
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return NewMessageTableFooterViewCell.calcHeight("example message")
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = dequeueReusableHeaderFooterView(withIdentifier: "NewMessageTableFooterViewCellReuseID") as? NewMessageTableFooterViewCell
        return footer
    }
}

// -- mark: cell view elements

@IBDesignable class ChatTableTextView: UITextView {
    
}


// -- mark: cells

@IBDesignable class ChatTableViewCell: UITableViewCell {
    static let sendButtonNotification = Notification.Name("ChatTableViewCellNotification")
    
    @IBOutlet var textView: ChatTableTextView?
    @IBOutlet var sender: UILabel?
    @IBOutlet var avatar: UIImageView?
    @IBOutlet var sendButton: UIButton?
    @IBOutlet var textViewHeightContraint: NSLayoutConstraint?
    
    static let vMargin: CGFloat = 11
    
    func configure(message msg: String)
    {
        textView?.text = msg
        sendButton?.isHidden = true
        
        textView?.isEditable = false
        
        textViewHeightContraint?.constant = UITextView().sizeThatFits(CGSizeFromString(msg)).height
    }
    
    class func calcHeight(_ fromText: String) -> CGFloat {
        let lines = CGFloat(fromText.components(separatedBy: "\n").count)
        return UITextView().sizeThatFits(CGSizeFromString(fromText)).height * lines + ChatTableViewCell.vMargin*2
    }
    
    @IBAction func onButton() {
    }
}

@IBDesignable class ConnectTableViewCell: ChatTableViewCell {
    static let connectNotification = Notification.Name("ConnectTableViewCellNotification")
    static let defaultServer = "kDefaultServerAddress"
    
    override func configure(message msg: String)
    {
        textView?.text = UserDefaults.standard.string(forKey: ConnectTableViewCell.defaultServer)
        
        guard let constant = textView?.sizeThatFits(CGSizeFromString("empty")).height else {
            return
        }
        
        textViewHeightContraint?.constant = constant
    }
    
    @IBAction override func onButton() {
        textView?.endEditing(true)
        let notification = Notification(name: ConnectTableViewCell.connectNotification, object: self,
                                        userInfo: ["text": textView?.text as Any])
        NotificationCenter.default.post(notification)
        
        UserDefaults.standard.set(textView?.text, forKey: ConnectTableViewCell.defaultServer)
    }
}

@IBDesignable class NewMessageTableFooterViewCell: UITableViewHeaderFooterView
{
    @IBOutlet weak var textField: UITextField?
    @IBOutlet weak var sendButton: UIButton?
    
    class func calcHeight(_ fromText: String) -> CGFloat {
        return 100
    }
    
    @IBAction func onButton() {
        textField?.endEditing(true)
        let notification = Notification(name: ChatTableViewCell.sendButtonNotification, object: self,
                                        userInfo: ["text": textField?.text as Any])
        NotificationCenter.default.post(notification)
    }
}
