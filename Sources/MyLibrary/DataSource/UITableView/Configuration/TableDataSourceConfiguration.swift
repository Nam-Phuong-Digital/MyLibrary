//
//  TableDataSourceConfiguration.swift
//  MyLibrary
//
//  Created by Claude Code
//

import UIKit

/// Immutable configuration for TableDynamicDataSource
public final class TableDataSourceConfiguration<T: Hashable> {
    // MARK: - Properties

    /// Enable pull-to-refresh functionality
    public let pullToRefreshEnabled: Bool

    /// Enable load more functionality
    public let loadMoreEnabled: Bool

    /// Empty state configuration
    public let emptyState: EmptyStateConfiguration

    /// Swipe actions configuration
    public let swipeActions: SwipeActionsConfiguration<T>

    /// Content inset for table view
    public let contentInset: UIEdgeInsets

    /// Refresh control tint color
    public let refreshControlTintColor: UIColor

    /// Enable automatic cell height calculation
    public let automaticDimension: Bool

    // MARK: - Initialization

    private init(builder: Builder) {
        self.pullToRefreshEnabled = builder.pullToRefreshEnabled
        self.loadMoreEnabled = builder.loadMoreEnabled
        self.emptyState = builder.emptyState
        self.swipeActions = builder.swipeActions
        self.contentInset = builder.contentInset
        self.refreshControlTintColor = builder.refreshControlTintColor
        self.automaticDimension = builder.automaticDimension
    }

    /// Default configuration
    public static var `default`: TableDataSourceConfiguration<T> {
        return Builder().build()
    }

    // MARK: - Builder

    public final class Builder {
        var pullToRefreshEnabled = false
        var loadMoreEnabled = false
        var emptyState = EmptyStateConfiguration.default
        var swipeActions = SwipeActionsConfiguration<T>()
        var contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 150, right: 0)
        var refreshControlTintColor: UIColor = .systemBlue
        var automaticDimension = true

        public init() {}

        @discardableResult
        public func enablePullToRefresh(tintColor: UIColor = .systemBlue) -> Builder {
            pullToRefreshEnabled = true
            refreshControlTintColor = tintColor
            return self
        }

        @discardableResult
        public func enableLoadMore() -> Builder {
            loadMoreEnabled = true
            return self
        }

        @discardableResult
        public func emptyState(_ config: EmptyStateConfiguration) -> Builder {
            emptyState = config
            return self
        }

        @discardableResult
        public func emptyStateText(_ text: String) -> Builder {
            emptyState = EmptyStateConfiguration(text: text)
            return self
        }

        @discardableResult
        public func swipeActions(_ config: SwipeActionsConfiguration<T>) -> Builder {
            swipeActions = config
            return self
        }

        @discardableResult
        public func contentInset(_ inset: UIEdgeInsets) -> Builder {
            contentInset = inset
            return self
        }

        @discardableResult
        public func automaticDimension(_ enabled: Bool) -> Builder {
            automaticDimension = enabled
            return self
        }

        public func build() -> TableDataSourceConfiguration<T> {
            return TableDataSourceConfiguration(builder: self)
        }
    }
}

/// Configuration for swipe actions
public struct SwipeActionsConfiguration<T: Hashable> {
    public typealias ActionProvider = (T, IndexPath) -> UISwipeActionsConfiguration?

    public let leading: ActionProvider?
    public let trailing: ActionProvider?

    public init(
        leading: ActionProvider? = nil,
        trailing: ActionProvider? = nil
    ) {
        self.leading = leading
        self.trailing = trailing
    }

    /// Create configuration with leading actions
    public static func leading(_ provider: @escaping ActionProvider) -> SwipeActionsConfiguration {
        return SwipeActionsConfiguration(leading: provider, trailing: nil)
    }

    /// Create configuration with trailing actions
    public static func trailing(_ provider: @escaping ActionProvider) -> SwipeActionsConfiguration {
        return SwipeActionsConfiguration(leading: nil, trailing: provider)
    }

    /// Create configuration with both leading and trailing actions
    public static func both(
        leading: @escaping ActionProvider,
        trailing: @escaping ActionProvider
    ) -> SwipeActionsConfiguration {
        return SwipeActionsConfiguration(leading: leading, trailing: trailing)
    }
}
