//
//  MLCheckBox.swift
//  
//
//  Created by Dai Pham on 5/6/24.
//

import UIKit

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
    
    @IBInspectable
    public var alignment: UIStackView.Alignment = .center
    
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
        
        stack.frame = bounds
        stack.axis = .horizontal
        stack.alignment = alignment
        stack.distribution = .fill
        stack.spacing = 10
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        
        imageView.image = normalImage
        imageView.highlightedImage = selectedImage
        imageView.addConstraints([
            .init(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 24),
            .init(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: 0)
        ])
        
        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(titleLabel)
        
        let height = self.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        let top = NSLayoutConstraint(item: stack, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 10)
        let leading = NSLayoutConstraint(item: stack, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 15)
        let trailing = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: stack, attribute: .trailing, multiplier: 1, constant: 15)
        let bottom = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: stack, attribute: .trailing, multiplier: 1, constant: 10)
        let constraint = [top, leading, trailing, bottom, height]
        constraint.forEach{ $0.priority = UILayoutPriority(999) }
        self.addConstraints(constraint)

        updateUI()
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
        titleLabel.textColor = color
    }
    
    public func setTitle(_ text: String?) {
        titleLabel.text = text
    }
}
