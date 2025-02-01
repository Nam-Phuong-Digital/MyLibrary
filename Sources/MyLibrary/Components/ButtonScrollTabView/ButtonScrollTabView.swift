//
//  ButtonScrollTabView.swift
//  GlobeDr
//
//  Created by dai on 2/18/20.
//  Copyright © 2020 GlobeDr. All rights reserved.
//

import UIKit

public protocol ButtonScrollTabViewDelegate:AnyObject {
    func selectTab(identifier:String?,buttonTab:ButtonTab?)
    func shouldSelectTab(identifier:String?,buttonTab:ButtonTab?) -> Bool
}

public extension ButtonScrollTabViewDelegate {
    func selectTab(identifier:String?,buttonTab:ButtonTab?) {}
    func shouldSelectTab(identifier:String?,buttonTab:ButtonTab?) -> Bool {return true}
}

public class ButtonTab: NSObject {
    public let title:String
    public let identifider:String
    public let isSelected:Bool
    
    public init(title:String,
         identifier:String,
         isSelected:Bool) {
        self.title = title
        self.identifider = identifier
        self.isSelected = isSelected
        super.init()
    }
}

public class ButtonScrollTabView: UIView {
    
    required init?(coder aDecoder: NSCoder) {   // 2 - storyboard initializer
        super.init(coder: aDecoder)
        fromNib(isModule: true)   // 5.
    }
    public init() {   // 3 - programmatic initializer
        super.init(frame: CGRect.zero)  // 4.
        fromNib(isModule: true)  // 6.
    }
    
    public var maxHeight:CGFloat = 100 + CGSize.getSizeNavigationBarIncludeStatus.height
    weak public  var delegate:ButtonScrollTabViewDelegate?
    public var buttonTabs:[ButtonTab] = []
    public var contentInset:UIEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    public var isCenterSelected: Bool = true
    @IBOutlet weak var scrollView:UIScrollView!
    @IBOutlet weak var leading: NSLayoutConstraint!
    @IBOutlet weak var stackButton: UIStackView!
    @IBOutlet weak var underLine: UIView!
    
    public var onScrollDidChange:((UIScrollView)-> Void)?
    public var onScrollDidEnd:((UIScrollView)-> Void)?
    
    public func dissmiss() {
        transform = CGAffineTransform.identity.translatedBy(x: 0, y: -maxHeight)
    }
    
    public func scrollToSelectIndex() {
        if selectIndex >= buttonTabs.count {return}
        self.scrollView.setContentOffset(CGPoint(x: self.stackButton.arrangedSubviews[selectIndex].frame.origin.x - self.frame.width/2, y: 0), animated: true)
    }
    
    public func disabledNormalMenu() {
        scrollView.isScrollEnabled = false
        stackButton.arrangedSubviews.enumerated().forEach { (i,view) in
            if let button = view as? UIButton, i != selectIndex {
                CATransaction.begin()
                UIView.transition(with: button, duration: 0.3, options: [.allowUserInteraction], animations: {
                    button.isEnabled = false
                    button.alpha = 0.2
                }) { (bool) in
                }
                CATransaction.commit()
            }
        }
    }
    
    public func enabledNormalMenu() {
        scrollView.isScrollEnabled = true
        stackButton.arrangedSubviews.enumerated().forEach { (i,view) in
            if let button = view as? UIButton, i != selectIndex {
                CATransaction.begin()
                UIView.transition(with: button, duration: 0.3, options: [.allowUserInteraction], animations: {
                    button.isEnabled = true
                    button.alpha = 1
                }) { (bool) in
                }
                CATransaction.commit()
            }
        }
    }
    
    public var objectSelected:ButtonTab? {
        get {
            if buttonTabs.count == 0, selectIndex > buttonTabs.count - 1 {return nil}
            return buttonTabs[selectIndex]
        }
    }
    
    public var selectIndex:Int = 0 {
        didSet {
            stackButton.arrangedSubviews.enumerated().forEach { (i,view) in
                if let button = view as? UIButton {
                    let selected = i == selectIndex
                    CATransaction.begin()
                    UIView.transition(with: button, duration: 0.3, options: [.allowUserInteraction], animations: {
                        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
                        button.setTitleColor(selected ? UIColor.mainColor : #colorLiteral(red: 0.6156862745, green: 0.6196078431, blue: 0.6980392157, alpha: 1), for: UIControl.State())
                    }) {[weak self] (bool) in guard let `self` = self else { return }
                        
                        if selected, self.selectIndex < self.stackButton.arrangedSubviews.count {
                            let f:CGRect = self.stackButton.convert(self.stackButton.arrangedSubviews[self.selectIndex].frame, to: self.scrollView)
                            if self.isCenterSelected {
                                self.scrollView.setContentOffset(CGPoint(x:(f.origin.x - self.scrollView.frame.width/2 + f.width/2), y: 0), animated: true)
                            } else {
                                self.scrollView.scrollRectToVisible(f, animated: true)
                            }
                        }
                    }
                    CATransaction.commit()
                }
            }
            reFrameUnderLine()
        }
    }
    
    public func setSelectIndex(index:Int) {
        selectIndex = index
    }
    
    @objc public  func action(_ sender:UIButton) {
        let newIndex = stackButton.arrangedSubviews.firstIndex(where: {$0.isEqual(sender)}) ?? 0
        if selectIndex == newIndex {return}
        if self.delegate?.shouldSelectTab(identifier: buttonTabs[newIndex].identifider, buttonTab: buttonTabs[newIndex]) == true {
            selectIndex = newIndex
            self.delegate?.selectTab(identifier: buttonTabs[selectIndex].identifider, buttonTab: buttonTabs[selectIndex])
        }
    }
    
    public func setButtons(titles:[ButtonTab]) {
        buttonTabs = titles
        stackButton.arrangedSubviews.forEach{$0.removeFromSuperview()}
        titles.enumerated().forEach({ i,tab in
            let button = UIButton()
            button.backgroundColor = .clear
            button.setTitle(tab.title.uppercased(), for: UIControl.State())
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            button.setTitleColor(tab.isSelected ? UIColor.mainColor : #colorLiteral(red: 0.6156862745, green: 0.6196078431, blue: 0.6980392157, alpha: 1), for: UIControl.State())
            button.accessibilityIdentifier = tab.identifider
            button.addTarget(self, action: #selector(action(_:)), for: .touchUpInside)
            button.titleLabel?.setContentHuggingPriority(UILayoutPriority(1000), for: .horizontal)
            stackButton.addArrangedSubview(button)
        })
        reFrameUnderLine()
    }
    
    public func reFrameUnderLine() {
//        self.layoutIfNeeded()
        if selectIndex >= stackButton.arrangedSubviews.count || stackButton.arrangedSubviews.count == 0 {return}
        
        let f:CGRect = stackButton.convert(stackButton.arrangedSubviews[selectIndex].frame, to: scrollView)
        
        leading.constant = f.origin.x
        underLine.getWidthConstraint()?.constant = f.size.width
        
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
    
    public func setSpaceWithSafeAreaTop() {
        let size = self.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        if let height = getHeightConstraint() {
            height.constant = size.height + CGSize.getSizeNavigationBarIncludeStatus.height
        } else {
            self.heightAnchor.constraint(equalToConstant: size.height + CGSize.getSizeNavigationBarIncludeStatus.height).isActive = true
        }
    }
    
    public func removeSpaceWithSafeAreaTop() {
        if let height = getHeightConstraint() {
            self.removeConstraint(height)
        }
    }
    
    public func setBackground(color:UIColor){
        backgroundColor = color
    }
    
    // MARK: -  override
    public override func awakeFromNib() {
        super.awakeFromNib()
        config()
        backgroundColor = .white
        underLine.backgroundColor = .mainColor
        scrollView.contentInset = contentInset
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        reFrameUnderLine()
        scrollView.contentInset = contentInset
    }
    
    public func config() {
        scrollView.delegate = self
    }
}

extension ButtonScrollTabView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.onScrollDidChange?(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.onScrollDidChange?(scrollView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.onScrollDidChange?(scrollView)
        }
    }
}
