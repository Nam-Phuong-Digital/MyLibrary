//
//  EmptyStateConfiguration.swift
//  MyLibrary
//
//  Created by Claude Code
//

import UIKit

/// Configuration for empty state display in table view
public struct EmptyStateConfiguration {
    /// Text to display when there are no items
    public let text: String?

    /// Custom view to display when there are no items (takes priority over text)
    public let customView: UIView?

    /// Background color for empty state
    public let backgroundColor: UIColor?

    /// Font for empty state text
    public let font: UIFont

    /// Text color for empty state
    public let textColor: UIColor

    /// Image to display above text (optional)
    public let image: UIImage?

    /// Vertical offset from center
    public let verticalOffset: CGFloat

    public init(
        text: String? = nil,
        customView: UIView? = nil,
        backgroundColor: UIColor? = nil,
        font: UIFont = .systemFont(ofSize: 16),
        textColor: UIColor = .gray,
        image: UIImage? = nil,
        verticalOffset: CGFloat = 0
    ) {
        self.text = text
        self.customView = customView
        self.backgroundColor = backgroundColor
        self.font = font
        self.textColor = textColor
        self.image = image
        self.verticalOffset = verticalOffset
    }

    /// Default empty state configuration
    public static let `default` = EmptyStateConfiguration(
        text: "No items to display"
    )

    /// Builder for creating custom configurations
    public final class Builder {
        private var text: String?
        private var customView: UIView?
        private var backgroundColor: UIColor?
        private var font: UIFont = .systemFont(ofSize: 16)
        private var textColor: UIColor = .gray
        private var image: UIImage?
        private var verticalOffset: CGFloat = 0

        public init() {}

        public func text(_ text: String) -> Builder {
            self.text = text
            return self
        }

        public func customView(_ view: UIView) -> Builder {
            self.customView = view
            return self
        }

        public func backgroundColor(_ color: UIColor) -> Builder {
            self.backgroundColor = color
            return self
        }

        public func font(_ font: UIFont) -> Builder {
            self.font = font
            return self
        }

        public func textColor(_ color: UIColor) -> Builder {
            self.textColor = color
            return self
        }

        public func image(_ image: UIImage) -> Builder {
            self.image = image
            return self
        }

        public func verticalOffset(_ offset: CGFloat) -> Builder {
            self.verticalOffset = offset
            return self
        }

        public func build() -> EmptyStateConfiguration {
            return EmptyStateConfiguration(
                text: text,
                customView: customView,
                backgroundColor: backgroundColor,
                font: font,
                textColor: textColor,
                image: image,
                verticalOffset: verticalOffset
            )
        }
    }
}
