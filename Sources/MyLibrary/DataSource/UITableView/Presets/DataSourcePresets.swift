//
//  DataSourcePresets.swift
//  MyLibrary
//
//  Created by Claude Code
//  Phase 3: Common preset configurations
//

import UIKit
import RxSwift

// MARK: - DataSourcePreset

/// Namespace for common data source presets
public enum DataSourcePreset {

    // MARK: - Basic Presets

    /// Simple static list
    public static func staticList<T: Hashable, Cell: UITableViewCell>(
        tableView: UITableView,
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void
    ) -> TableDynamicDataSource<T> {
        return TableDataSourceBuilder<T>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType, with: configure)
            .emptyStateText("No items")
            .build()
    }

    /// Interactive list with selection
    public static func selectableList<T: Hashable, Cell: UITableViewCell>(
        tableView: UITableView,
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void,
        onSelect: @escaping (T) -> Void
    ) -> TableDynamicDataSource<T> {
        return TableDataSourceBuilder<T>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType, with: configure)
            .onItemSelected(onSelect)
            .emptyStateText("No items to select")
            .build()
    }

    /// Swipeable list with actions
    public static func swipeableList<T: Hashable, Cell: UITableViewCell>(
        tableView: UITableView,
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void,
        leadingActions: ((T, IndexPath) -> UISwipeActionsConfiguration?)? = nil,
        trailingActions: ((T, IndexPath) -> UISwipeActionsConfiguration?)? = nil
    ) -> TableDynamicDataSource<T> {
        let builder = TableDataSourceBuilder<T>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType, with: configure)
            .emptyStateText("No items")

        if let leading = leadingActions {
            builder.leadingSwipeActions(leading)
        }

        if let trailing = trailingActions {
            builder.trailingSwipeActions(trailing)
        }

        return builder.build()
    }

    // MARK: - Refreshable Presets

    /// Pull-to-refresh list
    public static func refreshableList<T: Hashable, Cell: UITableViewCell>(
        tableView: UITableView,
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void,
        tintColor: UIColor = .systemBlue
    ) -> TableDynamicDataSource<T> {
        return TableDataSourceBuilder<T>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType, with: configure)
            .enablePullToRefresh(tintColor: tintColor)
            .emptyStateText("Pull to refresh")
            .build()
    }

    /// Paginated list with load more
    public static func paginatedList<T: Hashable, Cell: UITableViewCell>(
        tableView: UITableView,
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void,
        tintColor: UIColor = .systemBlue
    ) -> TableDynamicDataSource<T> {
        return TableDataSourceBuilder<T>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType, with: configure)
            .enablePullToRefresh(tintColor: tintColor)
            .enableLoadMore()
            .emptyStateText("No items found")
            .build()
    }

    // MARK: - Advanced Presets

    /// Search results list
    public static func searchResultsList<T: Hashable, Cell: UITableViewCell>(
        tableView: UITableView,
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void,
        onSelect: @escaping (T) -> Void
    ) -> TableDynamicDataSource<T> {
        return TableDataSourceBuilder<T>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType, with: configure)
            .onItemSelected(onSelect)
            .emptyState(
                EmptyStateConfiguration.Builder()
                    .text("No results found")
                    .textColor(.gray)
                    .build()
            )
            .build()
    }

    /// Settings list
    public static func settingsList<T: Hashable, Cell: UITableViewCell>(
        tableView: UITableView,
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void,
        onSelect: @escaping (T) -> Void
    ) -> TableDynamicDataSource<T> {
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 44

        return TableDataSourceBuilder<T>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType, with: configure)
            .onItemSelected(onSelect)
            .cellHeight(44)
            .build()
    }

    /// Form list
    public static func formList<T: Hashable, Cell: UITableViewCell>(
        tableView: UITableView,
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void
    ) -> TableDynamicDataSource<T> {
        tableView.separatorStyle = .none
        tableView.allowsSelection = false

        return TableDataSourceBuilder<T>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType, with: configure)
            .build()
    }

    /// Feed/Timeline list
    public static func feedList<T: Hashable, Cell: UITableViewCell>(
        tableView: UITableView,
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void,
        tintColor: UIColor = .systemBlue
    ) -> TableDynamicDataSource<T> {
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableView.automaticDimension

        return TableDataSourceBuilder<T>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType, with: configure)
            .enablePullToRefresh(tintColor: tintColor)
            .enableLoadMore()
            .emptyState(
                EmptyStateConfiguration.Builder()
                    .text("No posts yet")
                    .textColor(.gray)
                    .build()
            )
            .build()
    }
}

// MARK: - Reactive Presets

public extension DataSourcePreset {

    /// Reactive list that automatically binds to view model
    static func reactive<T: Hashable, Cell: UITableViewCell, VM: TableViewModelProtocol>(
        tableView: UITableView,
        cellType: Cell.Type,
        viewModel: VM,
        configure: @escaping (Cell, T) -> Void,
        disposeBag: DisposeBag
    ) -> TableDynamicDataSource<T> where VM.Item == T {
        let dataSource = TableDataSourceBuilder<T>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType, with: configure)
            .enablePullToRefresh()
            .emptyStateText("No items")
            .build()

        dataSource.bind(to: viewModel, disposeBag: disposeBag)
        return dataSource
    }

    /// Reactive paginated list
    static func reactivePaginated<T: Hashable, Cell: UITableViewCell, VM: TableViewModelProtocol>(
        tableView: UITableView,
        cellType: Cell.Type,
        viewModel: VM,
        configure: @escaping (Cell, T) -> Void,
        disposeBag: DisposeBag
    ) -> TableDynamicDataSource<T> where VM.Item == T {
        let dataSource = TableDataSourceBuilder<T>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType, with: configure)
            .enablePullToRefresh()
            .enableLoadMore()
            .emptyStateText("No items found")
            .build()

        dataSource.bind(to: viewModel, disposeBag: disposeBag)
        return dataSource
    }

    /// Reactive search list
    static func reactiveSearch<T: Hashable, Cell: UITableViewCell>(
        tableView: UITableView,
        cellType: Cell.Type,
        searchResults: Observable<[T]>,
        configure: @escaping (Cell, T) -> Void,
        onSelect: @escaping (T) -> Void,
        disposeBag: DisposeBag
    ) -> TableDynamicDataSource<T> {
        let dataSource = searchResultsList(
            tableView: tableView,
            cellType: cellType,
            configure: configure,
            onSelect: onSelect
        )

        searchResults
            .bind(to: dataSource.rx.items)
            .disposed(by: disposeBag)

        return dataSource
    }
}

// MARK: - Quick Setup Extensions

public extension UITableView {

    /// Quick setup for simple list
    func setupSimpleList<T: Hashable, Cell: UITableViewCell>(
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void
    ) -> TableDynamicDataSource<T> {
        return DataSourcePreset.staticList(
            tableView: self,
            cellType: cellType,
            configure: configure
        )
    }

    /// Quick setup for selectable list
    func setupSelectableList<T: Hashable, Cell: UITableViewCell>(
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void,
        onSelect: @escaping (T) -> Void
    ) -> TableDynamicDataSource<T> {
        return DataSourcePreset.selectableList(
            tableView: self,
            cellType: cellType,
            configure: configure,
            onSelect: onSelect
        )
    }

    /// Quick setup for paginated list
    func setupPaginatedList<T: Hashable, Cell: UITableViewCell>(
        cellType: Cell.Type,
        configure: @escaping (Cell, T) -> Void
    ) -> TableDynamicDataSource<T> {
        return DataSourcePreset.paginatedList(
            tableView: self,
            cellType: cellType,
            configure: configure
        )
    }

    /// Quick setup with view model
    func setupWithViewModel<T: Hashable, Cell: UITableViewCell, VM: TableViewModelProtocol>(
        cellType: Cell.Type,
        viewModel: VM,
        configure: @escaping (Cell, T) -> Void,
        disposeBag: DisposeBag
    ) -> TableDynamicDataSource<T> where VM.Item == T {
        return DataSourcePreset.reactive(
            tableView: self,
            cellType: cellType,
            viewModel: viewModel,
            configure: configure,
            disposeBag: disposeBag
        )
    }
}
