//
//  File.swift
//  
//
//  Created by Dai Pham on 31/01/2024.
//

import UIKit

public extension UIButton {
    
    func outline(title:String, bgColor: UIColor? = UIColor("#006783"), titleColor:UIColor = .white, disabledColor:UIColor = UIColor("#f6f6f7"), insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15), font: UIFont? = nil, borderColor: UIColor? = nil) {
        if #available(iOS 15.0, *) {
            configuration = .plain()
            configurationUpdateHandler = {btn in
                btn.configuration?.title = title
                btn.configuration?.baseForegroundColor = titleColor
                var bg = UIBackgroundConfiguration.clear()
                bg.backgroundColor = btn.isEnabled ? bgColor : disabledColor
                btn.configuration?.background = bg
                btn.configuration?.contentInsets = NSDirectionalEdgeInsets(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right)
                btn.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ income in
                    var temp = income
                    if let font {
                        temp.font = font
                    } else {
                        temp.font = UIFont.systemFont(ofSize: 16, weight: .bold)
                    }
                    temp.foregroundColor = titleColor
                    return temp
                })
            }
        } else {
            titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
            setTitle(title, for: UIControl.State())
            setTitleColor(titleColor, for: UIControl.State())
            backgroundColor = bgColor
            contentEdgeInsets = insets
            setBackgroundImage(bgColor?.imageRepresentation, for: UIControl.State.normal)
            setBackgroundImage(UIColor("#f6f6f7").imageRepresentation, for: UIControl.State.disabled)
        }
        if let borderColor {
            layer.borderWidth = 1
            layer.borderColor = borderColor.cgColor
        }
    }
    
    func setBackground(normal:UIImage?, highlighted:UIImage?, color:UIColor? = nil) {
        if #available(iOS 15.0, *) {
            var configure = UIButton.Configuration.filled()
            configure.baseBackgroundColor = color
            self.configuration = configure
        }
        setBackgroundImage(normal, for: .normal)
        setBackgroundImage(highlighted, for: .highlighted)
        showsTouchWhenHighlighted = true
    }
    
    func setRadioStyle(
        title:String?,
        image:UIImage?,
        selectedImage:UIImage?,
        normalTextColor:UIColor = .black,
        selectedTextColor:UIColor = UIColor("#006783")
    ) {
        setTitle(title, for: UIControl.State())
        self.tintColor = tintColor
        if #available(iOS 15, *) {
            configuration = .plain()
            configurationUpdateHandler = {btn in
                var bg = UIBackgroundConfiguration.clear()
                bg.backgroundColor = .clear
                btn.configuration?.background = bg
                btn.configuration?.title = title
                btn.configuration?.image = btn.isSelected ? selectedImage?.withTintColor(.tintColor, renderingMode: .alwaysTemplate) : image?.withTintColor(.tintColor, renderingMode: .alwaysTemplate)
                btn.configuration?.baseForegroundColor = btn.isSelected ? selectedTextColor : normalTextColor
                btn.configuration?.imagePadding = 5
                btn.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
            }
        } else {
            backgroundColor = .clear
            setTitleColor(normalTextColor, for: .normal)
            setTitleColor(selectedTextColor, for: [.highlighted,.selected])
            setImage(image, for: .normal)
            setImage(selectedImage, for: .selected)
            contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            tintColor = normalTextColor
        }
    }
    
    func setCheckBoxStyle(
        title: String? = nil,
        image:UIImage?,
        selectedImage:UIImage?,
        tintColor:UIColor = .black,
        font: UIFont? = nil,
        titleColor: UIColor = .black
    ) {
        setTitle(title ?? "", for: UIControl.State())
        self.tintColor = tintColor
        if #available(iOS 15, *) {
            configuration = .plain()
            configurationUpdateHandler = {btn in
                var bg = UIBackgroundConfiguration.clear()
                bg.backgroundColor = .clear
                btn.configuration?.background = bg
                btn.configuration?.title = title
                btn.configuration?.image = btn.isSelected ? selectedImage?.withTintColor(.tintColor, renderingMode: .alwaysTemplate) : image?.withTintColor(.tintColor, renderingMode: .alwaysTemplate)
                btn.configuration?.baseForegroundColor = tintColor
                btn.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ income in
                    var temp = income
                    temp.foregroundColor = titleColor
                    if let font {
                        temp.font = font
                    } else {
                        temp.font = UIFont.systemFont(ofSize: 14)
                    }
                    return temp
                })
            }
        } else {
            backgroundColor = .clear
            titleLabel?.font = font ?? .systemFont(ofSize: 14)
            titleLabel?.textColor = titleColor
            setImage(image, for: .normal)
            setImage(selectedImage, for: .selected)
        }
    }
    
    func configButtonBottom(title:String, bgColor: UIColor? = UIColor("#006783"), titleColor:UIColor = .white, disabledColor:UIColor = UIColor("#f6f6f7"), insets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)) {
        if #available(iOS 15.0, *) {
            configuration = .plain()
            configurationUpdateHandler = {btn in
                btn.configuration?.title = title
                btn.configuration?.baseForegroundColor = titleColor
                var bg = UIBackgroundConfiguration.clear()
                bg.backgroundColor = btn.isEnabled ? bgColor : disabledColor
                btn.configuration?.background = bg
                btn.configuration?.contentInsets = NSDirectionalEdgeInsets(top: insets.top, leading: insets.left, bottom: insets.bottom, trailing: insets.right)
                btn.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ income in
                    var temp = income
                    temp.font = UIFont.systemFont(ofSize: 16, weight: .bold)
                    temp.foregroundColor = titleColor
                    return temp
                })
            }
        } else {
            titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
            setTitle(title, for: UIControl.State())
            setTitleColor(titleColor, for: UIControl.State())
            backgroundColor = bgColor
            contentEdgeInsets = insets
            setBackgroundImage(bgColor?.imageRepresentation, for: UIControl.State.normal)
            setBackgroundImage(UIColor("#f6f6f7").imageRepresentation, for: UIControl.State.disabled)
        }
    }
    
    func setDropdownStyle(title:String?, image:UIImage?) {
        setTitle(title, for: UIControl.State())
        tintColor = .black
        if #available(iOS 15, *) {
            configuration = .plain()
            configurationUpdateHandler = {btn in
                var bg = UIBackgroundConfiguration.clear()
                bg.backgroundColor = .clear
                btn.configuration?.background = bg
                btn.configuration?.title = title
                btn.configuration?.image = image?.resizeImageWith(newSize: CGSize(width: 5, height: 5)).tint(with: btn.isEnabled ? .black : .clear)
                btn.configuration?.imagePlacement = .trailing
            }
        } else {
            backgroundColor = .clear
            setImage(image?.resizeImageWith(newSize: CGSize(width: 5, height: 5)), for: .normal)
            setImage(nil, for: .disabled)
            self.semanticContentAttribute = .forceRightToLeft
        }
    }
    
    func setTitleStyle(title:String?, color:UIColor? = .black, font: UIFont? = nil) {
        setTitle(title, for: UIControl.State())
        tintColor = color
        if #available(iOS 15, *) {
            configuration = .plain()
            configurationUpdateHandler = {btn in
                var bg = UIBackgroundConfiguration.clear()
                bg.backgroundColor = .clear
                btn.configuration?.background = bg
                btn.configuration?.title = title
                btn.configuration?.baseForegroundColor = color
                if let font {
                    btn.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer({ income in
                        var temp = income
                        temp.font = font
                        temp.foregroundColor = color
                        return temp
                    })
                }
            }
        } else {
            backgroundColor = .clear
            setTitleColor(color, for: UIControl.State())
            setImage(nil, for: .disabled)
            if let font {
                titleLabel?.font = font
            }
        }
    }
    
    func setTitleColor(normal:UIColor?, highlighted:UIColor?) {
        if #available(iOS 15.0, *) {
            let configure = UIButton.Configuration.filled()
            self.configuration = configure
        }
        setTitleColor(normal, for: .normal)
        setTitleColor(highlighted, for: .highlighted)
        showsTouchWhenHighlighted = true
    }
}

extension UIButton: XIBLocalizable {
    @IBInspectable public var locKey: String? {
        get { return nil }
        set(key) {
            setTitle(key?.localizedString(), for: UIControl.State())
        }
    }
}
