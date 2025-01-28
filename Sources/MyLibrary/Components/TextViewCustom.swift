//
//  TextViewCustom.swift
//  FindGo
//
//  Created by Dai Pham on 12/04/2023.
//

import UIKit
import Combine

public class TextViewCustom: UIView, UITextViewDelegate {

    required init?(coder aDecoder: NSCoder) {   // 2 - storyboard initializer
        super.init(coder: aDecoder)
        fromNib(isModule: true)   // 5.
    }
    public init() {   // 3 - programmatic initializer
        super.init(frame: CGRect.zero)  // 4.
        fromNib(isModule: true)  // 6.
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        config()
    }
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var lblPlaceholder: UILabel!
    
    let PLACEHOLDER_TAG = 100
    
    public var value:String = ""
    
    public var onTyping:((String)->Void)?
    
    private var showPlaceholder:Bool = true {
        didSet {
            if self.lblPlaceholder != nil {
                self.lblPlaceholder.isHidden = !showPlaceholder
            }
        }
    }
    
    @IBInspectable public var placeholder:String = "" {
        didSet {
            if lblPlaceholder != nil {
                lblPlaceholder.text = placeholder
            }
        }
    }
    
    @IBInspectable public var placeholderColor:UIColor = UIColor.borderColor1 {
        didSet {
            if lblPlaceholder != nil {
                lblPlaceholder.textColor = placeholderColor
            }
        }
    }
    
    public var font:UIFont? = UIFont.systemFont(ofSize: 17) {
        didSet {
            if textView != nil {
                textView.font = font
            }
        }
    }
    
    public var text:String = "" {
        didSet {
            if textView != nil {
                textView.text = text
                showPlaceholder = textView.text.isEmpty
            }
        }
    }
    
    public var textColor:UIColor? = .black {
        didSet {
            if textView != nil {
                textView.textColor = textColor
            }
        }
    }
    
    public var isEnabled:Bool = true {
        didSet {
            guard textView != nil else {return}
            textView.isEditable = isEnabled
        }
    }
    
    public func config() {
        backgroundColor = .clear
        textView.delegate = self
        
        lblPlaceholder.font = UIFont.systemFont(ofSize: 17)
        lblPlaceholder.text = self.placeholder
        lblPlaceholder.textColor = self.placeholderColor
        
        textView.textColor = textColor
        textView.font = font
        
        showPlaceholder = textView.text.isEmpty
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        showPlaceholder = false
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        showPlaceholder = textView.text.isEmpty
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        value = textView.text
        onTyping?(textView.text)
    }
    
}
