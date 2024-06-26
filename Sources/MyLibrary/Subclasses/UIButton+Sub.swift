//
//  File.swift
//  
//
//  Created by Dai Pham on 30/01/2024.
//

import UIKit

public class IBInspectableButton:UIButton {
    @IBInspectable public var haveShadow:Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
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
}

public class ButtonHalfHeight: IBInspectableButton {
    public override func layoutSubviews() {
        super.layoutSubviews()
        drawCorner(corner: frame.size.height/2, borderWidth: borderWidth, borderColor: borderColor)
        if haveShadow {
            layer.masksToBounds = false
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.25
            layer.shadowOffset = CGSize(width: 0, height: 2)
            layer.shadowRadius = 2
        } else {
            layer.masksToBounds = true
            layer.shadowColor = UIColor.clear.cgColor
        }
    }
    
    public var object:Any? // need keep object to handle in extension using this button class
}


public class Button10Corner: IBInspectableButton {

    public var object:Any? // need keep object to handle in extension using this button class
    // MARK: -  override
    public override func layoutSubviews() {
        super.layoutSubviews()
        drawCorner(corner: 10, borderWidth: borderWidth, borderColor: borderColor)
    }
}

public class Button5Corner: IBInspectableButton {

    public var object:Any? // need keep object to handle in extension using this button class
    
    // MARK: -  override
    public override func layoutSubviews() {
        super.layoutSubviews()
        drawCorner(corner: 5, borderWidth: borderWidth, borderColor: borderColor)
        if #available(iOS 10.0, *) {
            titleLabel?.adjustsFontForContentSizeCategory = true
        }
    }
}
