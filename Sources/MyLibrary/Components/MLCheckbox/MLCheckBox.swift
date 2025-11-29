//
//  MLCheckBox.swift
//  
//
//  Created by Dai Pham on 5/6/24.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: MLCheckBox {
    public var isChecked: Observable<Bool> {
        return base.rx.controlEvent(.valueChanged)
            .map { self.base.isChecked }
    }
}

@IBDesignable
public class MLCheckBox: UIControl {

    @IBInspectable
    public var normalImage: UIImage?
    
    @IBInspectable
    public var selectedImage: UIImage?
    
    @IBInspectable
    public var isChecked: Bool = false {
        didSet {
            updateUI()
        }
    }
    
    public var font: UIFont = .systemFont(ofSize: 16) {
        didSet {
            titleLabel.font = font
        }
    }
    
    public var textColor: UIColor = .black {
        didSet {
            titleLabel.textColor = textColor
        }
    }
    
    @IBInspectable
    public var alignment: UIStackView.Alignment = .center
    
    public var object: Any?
    
    public init(
        normalImage: UIImage?,
        selectedImage: UIImage?,
        isChecked: Bool = false,
        alignment: UIStackView.Alignment = .center
    ) {
        self.normalImage = normalImage
        self.selectedImage = selectedImage
        self.isChecked = isChecked
        super.init(frame: .zero)
        self.alignment = alignment
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        self.isChecked = false
        super.init(coder: coder)
        setupViews()
    }
    
    private let titleLabel = UILabel()
    private let stack = UIStackView(frame: .zero)
    private let imageView = UIImageView()
    
    private func setupViews() {
        
        [stack, titleLabel, imageView].forEach{ $0.isUserInteractionEnabled = false }
        
        stack.axis = .horizontal
        stack.alignment = alignment
        stack.distribution = .fill
        stack.spacing = 8
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = font
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        titleLabel.textColor = textColor
        
        imageView.image = normalImage
        imageView.highlightedImage = selectedImage
        imageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 1).isActive = true
        
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(titleLabel)
        stack.boundInside(self, insets: .init(top: 3, left: 0, bottom: 3, right: 0))

        updateUI()
        
        _ = rx.controlEvent(.touchUpInside)
            .take(until: rx.deallocated)
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { owner, _ in
                owner.isChecked.toggle()
                owner.sendActions(for: .valueChanged)
            })
    }
    
    private func updateUI() {
        imageView.isHighlighted = isChecked
    }
    
    // MARK: -  PUBLIC APIS
    public func setColor(_ color: UIColor) {
        tintColor = color
        imageView.tintColor = color
        imageView.image = normalImage?.withRenderingMode(.alwaysTemplate).tint(with: color)
        imageView.highlightedImage = selectedImage?.withRenderingMode(.alwaysTemplate).tint(with: color)
    }
    
    public func setTitle(_ text: String?) {
        titleLabel.text = text
    }
}
