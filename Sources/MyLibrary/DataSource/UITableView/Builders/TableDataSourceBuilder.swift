//
//  TableDataSourceBuilder.swift
//  MyLibrary
//
//  Created by Claude Code
//

import UIKit

/// Fluent builder for creating TableDynamicDataSource instances
public final class TableDataSourceBuilder<T: Hashable> {
    // MARK: - Properties

    private let tableView: UITableView
    internal var cellTypes: [UITableViewCell.Type] = []
    internal var headerFooterTypes: [UITableViewHeaderFooterView.Type] = []
    internal var configurationBuilder = TableDataSourceConfiguration<T>.Builder()
    internal var cellConfigurator: ((T, IndexPath, UITableView) -> UITableViewCell)?
    internal var headerFooterConfigurator: ((SectionDataSourceModel<T>, Int, UITableView, TableDynamicDataSource<T>.SupplementaryType) -> UITableViewHeaderFooterView?)?
    internal var selectionHandler: ((T) -> Void)?
    internal var heightForCell: ((IndexPath, UITableView) -> CGFloat?)?

    // MARK: - Initialization

    public init(tableView: UITableView) {
        self.tableView = tableView
    }

    // MARK: - Cell Configuration

    /// Register cell types
    @discardableResult
    public func cells(_ types: UITableViewCell.Type...) -> Self {
        cellTypes.append(contentsOf: types)
        return self
    }

    /// Configure cell for item
    @discardableResult
    public func configure(cell: @escaping (T, IndexPath, UITableView) -> UITableViewCell) -> Self {
        cellConfigurator = cell
        return self
    }

    /// Configure cell with simplified closure (no indexPath, tableView)
    @discardableResult
    public func configureCell<Cell: UITableViewCell>(
        _ cellType: Cell.Type,
        with configurator: @escaping (Cell, T) -> Void
    ) -> Self {
        cellTypes.append(cellType)
        cellConfigurator = { item, indexPath, tableView in
            let cell = tableView.dequeue(cellType)
            configurator(cell, item)
            return cell
        }
        return self
    }

    /// Set cell height calculator
    @discardableResult
    public func cellHeight(_ calculator: @escaping (IndexPath, UITableView) -> CGFloat?) -> Self {
        heightForCell = calculator
        return self
    }

    /// Set fixed cell height
    @discardableResult
    public func cellHeight(_ height: CGFloat) -> Self {
        heightForCell = { _, _ in height }
        return self
    }

    // MARK: - Header/Footer Configuration

    /// Register header and footer types
    @discardableResult
    public func headerFooterViews(_ types: UITableViewHeaderFooterView.Type...) -> Self {
        headerFooterTypes.append(contentsOf: types)
        return self
    }

    /// Configure header and footer views
    @discardableResult
    public func configure(
        headerFooter: @escaping (SectionDataSourceModel<T>, Int, UITableView, TableDynamicDataSource<T>.SupplementaryType) -> UITableViewHeaderFooterView?
    ) -> Self {
        headerFooterConfigurator = headerFooter
        return self
    }

    // MARK: - Selection

    /// Handle item selection
    @discardableResult
    public func onItemSelected(_ handler: @escaping (T) -> Void) -> Self {
        selectionHandler = handler
        return self
    }

    // MARK: - Configuration

    /// Enable pull-to-refresh
    @discardableResult
    public func enablePullToRefresh(tintColor: UIColor = .systemBlue) -> Self {
        configurationBuilder.enablePullToRefresh(tintColor: tintColor)
        return self
    }

    /// Enable load more
    @discardableResult
    public func enableLoadMore() -> Self {
        configurationBuilder.enableLoadMore()
        return self
    }

    /// Set empty state text
    @discardableResult
    public func emptyStateText(_ text: String) -> Self {
        configurationBuilder.emptyStateText(text)
        return self
    }

    /// Set empty state configuration
    @discardableResult
    public func emptyState(_ config: EmptyStateConfiguration) -> Self {
        configurationBuilder.emptyState(config)
        return self
    }

    /// Configure swipe actions
    @discardableResult
    public func swipeActions(_ config: SwipeActionsConfiguration<T>) -> Self {
        configurationBuilder.swipeActions(config)
        return self
    }

    /// Set leading swipe actions
    @discardableResult
    public func leadingSwipeActions(
        _ provider: @escaping (T, IndexPath) -> UISwipeActionsConfiguration?
    ) -> Self {
        let currentTrailing = configurationBuilder.swipeActions.trailing
        configurationBuilder.swipeActions(
            SwipeActionsConfiguration(leading: provider, trailing: currentTrailing)
        )
        return self
    }

    /// Set trailing swipe actions
    @discardableResult
    public func trailingSwipeActions(
        _ provider: @escaping (T, IndexPath) -> UISwipeActionsConfiguration?
    ) -> Self {
        let currentLeading = configurationBuilder.swipeActions.leading
        configurationBuilder.swipeActions(
            SwipeActionsConfiguration(leading: currentLeading, trailing: provider)
        )
        return self
    }

    /// Set content inset
    @discardableResult
    public func contentInset(_ inset: UIEdgeInsets) -> Self {
        configurationBuilder.contentInset(inset)
        return self
    }

    /// Set content inset with single value for all edges
    @discardableResult
    public func contentInset(_ value: CGFloat) -> Self {
        configurationBuilder.contentInset(UIEdgeInsets(
            top: value,
            left: value,
            bottom: value,
            right: value
        ))
        return self
    }

    // MARK: - Build

    /// Build the TableDynamicDataSource
    public func build() -> TableDynamicDataSource<T> {
        guard let cellConfigurator = cellConfigurator else {
            fatalError("Cell configurator is required. Use configure(cell:) or configureCell(_:with:)")
        }

        // Convert new configuration to legacy configuration
        let config = configurationBuilder.build()
        let legacyConfig = TableDynamicDataSource<T>.Configuration(
            havePullToRefresh: config.pullToRefreshEnabled,
            leadingSwipeActionsConfiguration: config.swipeActions.leading,
            trailingSwipeActionsConfiguration: config.swipeActions.trailing,
            textNoData: config.emptyState.text,
            viewNoData: config.emptyState.customView,
            contentInset: config.contentInset
        )

        return TableDynamicDataSource(
            for: tableView,
            cellsType: cellTypes,
            sectionsType: headerFooterTypes,
            configCell: cellConfigurator,
            configHeaderFooter: headerFooterConfigurator,
            itemSelected: selectionHandler,
            heightForCell: heightForCell,
            configuration: legacyConfig
        )
    }
}

// MARK: - Convenience Extension

public extension TableDynamicDataSource {
    /// Create a builder for this table view
    static func builder<T>(for tableView: UITableView) -> TableDataSourceBuilder<T> {
        return TableDataSourceBuilder(tableView: tableView)
    }
}
