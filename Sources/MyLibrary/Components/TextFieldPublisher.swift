//
//  TextField.swift
//  lizAI
//
//  Created by Dai Pham on 29/11/2022.
//

import UIKit
import Combine

@available(iOS 13,*)
public class TextFieldPublisher: BaseObservableView {

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
    
    @IBOutlet weak var vwContent: Corner12View!
    @IBInspectable var shouldSubmit:Bool = false
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var lblError: UILabel!
    @IBOutlet weak var iconArrow: UIImageView!
    
    @Published public var text:String = ""
    @Published public var error:String = ""
    
    @IBInspectable public var borderColor:UIColor = .clear {
        didSet {
            setNeedsLayout()
        }
    }
    @IBInspectable public var borderWidth:CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    @IBInspectable public var haveShadow:Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        vwContent.haveShadow = haveShadow
        vwContent.borderColor = borderColor
        vwContent.borderWidth = borderWidth
    }
    
    public var onSubmit:(()->Void)?
    public var onSelect:(()->Void)? {
        didSet {
            textField.delegate = self
        }
    }
    
    public var showArrow:Bool = false {
        didSet {
            if iconArrow != nil {
                iconArrow.isHidden = !showArrow
            }
        }
    }
    
    public var isUpperCase:Bool = true {
        didSet {
            guard textField != nil else {return}
            if isUpperCase {
                textField.delegate = self
            } else {
                textField.delegate = nil
            }
        }
    }
    
    public var textAlignment: NSTextAlignment = .left {
        didSet {
            if textField != nil {
                textField.textAlignment = textAlignment
            }
        }
    }
    
    public var title:String  = ""{
        didSet {
            if lblTitle != nil {
                lblTitle.text = title
            }
        }
    }
    
    public var placeHolder:String  = "" {
        didSet {
            if textField != nil {
                textField.attributedPlaceholder = NSAttributedString(string: placeHolder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.borderColor1])
            }
        }
    }
    
    public var value:String = "" {
        didSet {
            if textField != nil {
                textField.text = value
                text = value
            }
        }
    }
    
    public var isFocus:Bool {
        set {
            if textField != nil {
                if newValue {
                    textField.becomeFirstResponder()
                } else {
                    textField.resignFirstResponder()
                }
            }
        }
        get {
            return textField.isFirstResponder
        }
    }
    
    public var isSecureTextEntry:Bool = false {
        didSet {
            if textField != nil {
                textField.isSecureTextEntry = isSecureTextEntry
            }
        }
    }
    
    public var keyboarbType:UIKeyboardType = .default {
        didSet {
            if textField != nil {
                textField.keyboardType = keyboarbType
            }
        }
    }
    
    public var isEnabled:Bool  = true {
        didSet {
            if textField != nil {
                textField.isEnabled = isEnabled
            }
        }
    }
    
    public var accessoryView:UIView? = nil {
        didSet {
            if textField != nil {
                textField.inputAccessoryView = accessoryView
                textField.reloadInputViews()
            }
        }
    }
    
    public func config() {
        self.backgroundColor = .clear
        
        lblTitle.textColor = .blue
        lblTitle.text = title
        
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .black
        
        textField.placeholder = placeHolder
        textField.isSecureTextEntry = isSecureTextEntry
        textField.text = value
        if shouldSubmit || onSelect != nil || isUpperCase {
            textField.delegate = self
        }
        
        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification,
                                             object: textField)
            .map({(($0.object as? UITextField)?.text ?? "")})
//            .map({[weak self] string in guard let `self` = self else { return string}
//                if self.isUpperCase { return string.uppercased() }
//                    else {
//                    return string
//                }
//            })
            .sink(receiveValue: {[weak self] new in guard let `self` = self else { return }
//                self.textField.text = new
                self.text = new
            })
            .store(in: &cancellables)
        
        $error
            .receive(on: RunLoop.main)
            .sink {[weak self] new in
                self?.lblError.isHidden = new.count == 0
                self?.lblError.text = new
            }
            .store(in: &cancellables)
        
        vwContent.addTargetCustom(target: self, action: #selector(focus(_:)), keepObject: nil)
    }
    
    @objc func focus(_ sender:Any) {
        textField.becomeFirstResponder()
    }
    
    @objc func showPassword(_ sender:UIButton) {
        sender.isSelected = !sender.isSelected
        textField.isSecureTextEntry = !sender.isSelected
    }
}

@available(iOS 13,*)
extension TextFieldPublisher: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard isUpperCase else {return true}
        let firstLowercaseCharRange = string.rangeOfCharacter(from: NSCharacterSet.lowercaseLetters)
        if let _ = firstLowercaseCharRange {
            if let text = textField.text, text.isEmpty {
                textField.text = string.uppercased()
                self.text = string.uppercased()
            }
            else {
                let beginning = textField.beginningOfDocument
                if let start = textField.position(from: beginning, offset: range.location),
                   let end = textField.position(from: start, offset: range.length),
                   let replaceRange = textField.textRange(from: start, to: end) {
                    textField.replace(replaceRange, withText: string.uppercased())
                }
            }
            return false
        }
        return true
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onSubmit?()
        return shouldSubmit
    }
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if let onSelect  = onSelect{
            onSelect()
            return false
        }
        return true
    }
}
