//
//  EmptyStateManager.swift
//  MyLibrary
//
//  Created by Claude Code
//

import UIKit

/// Manages empty state display for table views
final class EmptyStateManager {
    private weak var containerView: UIView?
    private let configuration: EmptyStateConfiguration
    private var emptyStateView: UIView?

    private static let emptyStateTag = 10000000

    init(containerView: UIView, configuration: EmptyStateConfiguration) {
        self.containerView = containerView
        self.configuration = configuration
    }

    /// Show empty state view
    func show() {
        guard let containerView = containerView else { return }

        hide() // Remove any existing empty state

        let emptyView: UIView

        if let customView = configuration.customView {
            emptyView = customView
        } else {
            emptyView = createDefaultEmptyView()
        }

        emptyView.tag = Self.emptyStateTag
        emptyView.translatesAutoresizingMaskIntoConstraints = false

        if let backgroundColor = configuration.backgroundColor {
            emptyView.backgroundColor = backgroundColor
        }

        containerView.addSubview(emptyView)

        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emptyView.centerYAnchor.constraint(
                equalTo: containerView.centerYAnchor,
                constant: configuration.verticalOffset
            ),
            emptyView.leadingAnchor.constraint(
                greaterThanOrEqualTo: containerView.leadingAnchor,
                constant: 20
            ),
            emptyView.trailingAnchor.constraint(
                lessThanOrEqualTo: containerView.trailingAnchor,
                constant: -20
            )
        ])

        self.emptyStateView = emptyView
    }

    /// Hide empty state view
    func hide() {
        containerView?.viewWithTag(Self.emptyStateTag)?.removeFromSuperview()
        emptyStateView = nil
    }

    /// Check if empty state is currently showing
    var isShowing: Bool {
        return emptyStateView != nil
    }

    // MARK: - Private Methods

    private func createDefaultEmptyView() -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16

        // Add image if provided
        if let image = configuration.image {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = configuration.textColor.withAlphaComponent(0.6)

            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 80),
                imageView.heightAnchor.constraint(equalToConstant: 80)
            ])

            stackView.addArrangedSubview(imageView)
        }

        // Add text label if provided
        if let text = configuration.text {
            let label = UILabel()
            label.text = text
            label.font = configuration.font
            label.textColor = configuration.textColor
            label.textAlignment = .center
            label.numberOfLines = 0

            stackView.addArrangedSubview(label)
        }

        return stackView
    }
}
