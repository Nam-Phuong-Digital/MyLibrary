//
//  TableDynamicDataSource+TypeSafe.swift
//  MyLibrary
//
//  Created by Claude Code
//  Phase 3: Type-Safe API Simplification
//

import UIKit
import RxSwift
import RxRelay

// MARK: - Type-Safe Cell Configuration

public extension TableDataSourceBuilder {

    /// Configure cell with automatic type inference
    /// - Parameter configurator: Type-safe configuration closure
    /// - Returns: Builder for chaining
    @discardableResult
    func configure<Cell: UITableViewCell>(
        _ configurator: @escaping (Cell, T, IndexPath) -> Void
    ) -> Self {
        cellConfigurator = { item, indexPath, tableView in
            let cell = tableView.dequeue(Cell.self)
            configurator(cell, item, indexPath)
            return cell
        }
        return self
    }

    /// Configure cell with simple closure (no indexPath)
    /// - Parameter configurator: Simplified configuration closure
    /// - Returns: Builder for chaining
    @discardableResult
    func configureCell<Cell: UITableViewCell>(
        _ configurator: @escaping (Cell, T) -> Void
    ) -> Self {
        cellConfigurator = { item, indexPath, tableView in
            let cell = tableView.dequeue(Cell.self)
            configurator(cell, item)
            return cell
        }
        return self
    }
}

// MARK: - Multiple Cell Type Support

public extension TableDataSourceBuilder {

    /// Configure multiple cell types with type-safe switch
    /// - Parameter configurator: Closure to determine cell type and configure
    /// - Returns: Builder for chaining
    @discardableResult
    func configureCells(_ configurator: @escaping (T, IndexPath, UITableView) -> UITableViewCell) -> Self {
        cellConfigurator = configurator
        return self
    }
}

// MARK: - Common Presets

public extension TableDynamicDataSource {

    /// Create a simple list data source with minimal configuration
    /// - Parameters:
    ///   - tableView: The table view
    ///   - cellType: Cell type conforming to ConfigurableCell
    /// - Returns: Configured data source
    static func simpleList<Cell: ConfigurableCell>(
        for tableView: UITableView,
        cellType: Cell.Type
    ) -> TableDynamicDataSource<Cell.Item> where Cell.Item == T {
        return TableDataSourceBuilder<Cell.Item>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType) { cell, item in
                cell.configure(with: item)
            }
            .emptyStateText("No items to display")
            .build()
    }

    /// Create a refreshable list with pull-to-refresh
    /// - Parameters:
    ///   - tableView: The table view
    ///   - cellType: Cell type conforming to ConfigurableCell
    ///   - emptyMessage: Message to show when empty
    /// - Returns: Configured data source
    static func refreshableList<Cell: ConfigurableCell>(
        for tableView: UITableView,
        cellType: Cell.Type,
        emptyMessage: String = "No items found"
    ) -> TableDynamicDataSource<Cell.Item> where Cell.Item == T {
        return TableDataSourceBuilder<Cell.Item>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType) { cell, item in
                cell.configure(with: item)
            }
            .enablePullToRefresh()
            .emptyStateText(emptyMessage)
            .build()
    }

    /// Create a paginated list with pull-to-refresh and load more
    /// - Parameters:
    ///   - tableView: The table view
    ///   - cellType: Cell type conforming to ConfigurableCell
    ///   - emptyMessage: Message to show when empty
    /// - Returns: Configured data source
    static func paginatedList<Cell: ConfigurableCell>(
        for tableView: UITableView,
        cellType: Cell.Type,
        emptyMessage: String = "No items found"
    ) -> TableDynamicDataSource<Cell.Item> where Cell.Item == T {
        return TableDataSourceBuilder<Cell.Item>(tableView: tableView)
            .cells(cellType)
            .configureCell(cellType) { cell, item in
                cell.configure(with: item)
            }
            .enablePullToRefresh()
            .enableLoadMore()
            .emptyStateText(emptyMessage)
            .build()
    }
}

// MARK: - ConfigurableCell Protocol

/// Protocol for cells that can configure themselves
public protocol ConfigurableCell: UITableViewCell {
    associatedtype Item: Hashable
    func configure(with item: Item)
}

// MARK: - Sections Support

public extension TableDataSourceBuilder {

    /// Configure sections with type-safe header
    /// - Parameters:
    ///   - headerType: Header view type
    ///   - configurator: Header configuration closure
    /// - Returns: Builder for chaining
    @discardableResult
    func configureSectionHeader<Header: UITableViewHeaderFooterView>(
        _ headerType: Header.Type,
        with configurator: @escaping (Header, SectionDataSourceModel<T>, Int) -> Void
    ) -> Self {
        headerFooterTypes.append(headerType)
        headerFooterConfigurator = { section, index, tableView, kind in
            guard case .header = kind else { return nil }
            let header = tableView.dequeue(headerType)
            if let header = header {
                configurator(header, section, index)
            }
            return header
        }
        return self
    }

    /// Configure sections with type-safe footer
    /// - Parameters:
    ///   - footerType: Footer view type
    ///   - configurator: Footer configuration closure
    /// - Returns: Builder for chaining
    @discardableResult
    func configureSectionFooter<Footer: UITableViewHeaderFooterView>(
        _ footerType: Footer.Type,
        with configurator: @escaping (Footer, SectionDataSourceModel<T>, Int) -> Void
    ) -> Self {
        headerFooterTypes.append(footerType)
        let currentHeaderFooter = headerFooterConfigurator
        headerFooterConfigurator = { section, index, tableView, kind in
            switch kind {
            case .header:
                return currentHeaderFooter?(section, index, tableView, kind)
            case .footer:
                let footer = tableView.dequeue(footerType)
                if let footer = footer {
                    configurator(footer, section, index)
                }
                return footer
            }
        }
        return self
    }
}

// MARK: - Reactive Binding Shortcuts

public extension TableDynamicDataSource {

    /// Quick setup for simple reactive binding
    /// - Parameters:
    ///   - items: Observable of items
    ///   - disposeBag: Dispose bag
    func bindItems(_ items: Observable<[T]>, disposeBag: DisposeBag) {
        items.bind(to: rx.items).disposed(by: disposeBag)
    }

    /// Quick setup for reactive binding with selection
    /// - Parameters:
    ///   - items: Observable of items
    ///   - onSelect: Selection handler
    ///   - disposeBag: Dispose bag
    func bindItems(
        _ items: Observable<[T]>,
        onSelect: @escaping (T) -> Void,
        disposeBag: DisposeBag
    ) {
        items.bind(to: rx.items).disposed(by: disposeBag)
        rx.itemSelected.subscribe(onNext: onSelect).disposed(by: disposeBag)
    }

    /// Quick setup for sections binding
    /// - Parameters:
    ///   - sections: Observable of sections
    ///   - disposeBag: Dispose bag
    func bindSections(_ sections: Observable<[SectionDataSourceModel<T>]>, disposeBag: DisposeBag) {
        sections.bind(to: rx.sections).disposed(by: disposeBag)
    }
}

// MARK: - Chainable Configuration

public extension TableDynamicDataSource {

    /// Apply configuration closure
    /// - Parameter configure: Configuration closure
    /// - Returns: Self for chaining
    @discardableResult
    func applying(_ configure: (TableDynamicDataSource<T>) -> Void) -> Self {
        configure(self)
        return self
    }

    /// Setup pull-to-refresh handler
    /// - Parameters:
    ///   - handler: Refresh handler returning Observable
    ///   - disposeBag: Dispose bag
    /// - Returns: Self for chaining
    @discardableResult
    func onPullToRefresh(
        _ handler: @escaping () -> Observable<Void>,
        disposeBag: DisposeBag
    ) -> Self {
        rx.pullToRefresh
            .flatMapLatest { handler() }
            .bind(to: rx.stopPullRefresh)
            .disposed(by: disposeBag)
        return self
    }

    /// Setup load more handler
    /// - Parameters:
    ///   - handler: Load more handler returning Observable
    ///   - disposeBag: Dispose bag
    /// - Returns: Self for chaining
    @discardableResult
    func onLoadMore(
        _ handler: @escaping () -> Observable<Void>,
        disposeBag: DisposeBag
    ) -> Self {
        rx.loadMore
            .flatMapLatest { handler() }
            .bind(to: rx.stopLoadMore)
            .disposed(by: disposeBag)
        return self
    }

    /// Setup selection handler
    /// - Parameters:
    ///   - handler: Selection handler
    ///   - disposeBag: Dispose bag
    /// - Returns: Self for chaining
    @discardableResult
    func onSelection(
        _ handler: @escaping (T) -> Void,
        disposeBag: DisposeBag
    ) -> Self {
        rx.itemSelected
            .subscribe(onNext: handler)
            .disposed(by: disposeBag)
        return self
    }
}

// MARK: - View Model Integration

public extension TableDynamicDataSource {

    /// Bind to a view model conforming to TableViewModelProtocol
    /// - Parameters:
    ///   - viewModel: View model to bind to
    ///   - disposeBag: Dispose bag
    func bind<VM: TableViewModelProtocol>(
        to viewModel: VM,
        disposeBag: DisposeBag
    ) where VM.Item == T {
        // Bind items
        viewModel.items
            .bind(to: rx.items)
            .disposed(by: disposeBag)

        // Bind pull to refresh
        rx.pullToRefresh
            .bind(to: viewModel.refresh)
            .disposed(by: disposeBag)

        // Bind load more if available
        if let loadMore = viewModel.loadMore {
            rx.loadMore
                .bind(to: loadMore)
                .disposed(by: disposeBag)
        }

        // Bind selection if available
        if let didSelect = viewModel.didSelectItem {
            rx.itemSelected
                .bind(to: didSelect)
                .disposed(by: disposeBag)
        }

        // Bind loading state
        viewModel.isLoading
            .subscribe(onNext: { [weak self] isLoading in
                if !isLoading {
                    self?.finishPullToRefresh()
                    self?.finishLoadMore()
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - TableViewModelProtocol

/// Protocol for view models that work with TableDynamicDataSource
public protocol TableViewModelProtocol {
    associatedtype Item: Hashable

    var items: Observable<[Item]> { get }
    var isLoading: Observable<Bool> { get }
    var refresh: AnyObserver<Void> { get }
    var loadMore: AnyObserver<Void>? { get }
    var didSelectItem: AnyObserver<Item>? { get }
}

// MARK: - Default ViewModel Implementation

open class TableViewModel<Item: Hashable>: TableViewModelProtocol {

    // MARK: - Properties

    private let itemsRelay = BehaviorRelay<[Item]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let refreshTrigger = PublishSubject<Void>()
    private let loadMoreTrigger = PublishSubject<Void>()
    private let selectionTrigger = PublishSubject<Item>()
    private let disposeBag = DisposeBag()

    // MARK: - TableViewModelProtocol

    public var items: Observable<[Item]> {
        return itemsRelay.asObservable()
    }

    public var isLoading: Observable<Bool> {
        return isLoadingRelay.asObservable()
    }

    public var refresh: AnyObserver<Void> {
        return refreshTrigger.asObserver()
    }

    public var loadMore: AnyObserver<Void>? {
        return loadMoreTrigger.asObserver()
    }

    public var didSelectItem: AnyObserver<Item>? {
        return selectionTrigger.asObserver()
    }

    // MARK: - Initialization

    public init() {
        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Override in subclass to implement refresh logic
        refreshTrigger
            .subscribe(onNext: { [weak self] in
                self?.performRefresh()
            })
            .disposed(by: disposeBag)

        loadMoreTrigger
            .subscribe(onNext: { [weak self] in
                self?.performLoadMore()
            })
            .disposed(by: disposeBag)

        selectionTrigger
            .subscribe(onNext: { [weak self] item in
                self?.handleSelection(item)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Methods to Override

    /// Override to implement refresh logic
    open func performRefresh() {
        // Implement in subclass
    }

    /// Override to implement load more logic
    open func performLoadMore() {
        // Implement in subclass
    }

    /// Override to handle item selection
    open func handleSelection(_ item: Item) {
        // Implement in subclass
    }

    // MARK: - Helper Methods

    /// Update items
    public func updateItems(_ items: [Item]) {
        itemsRelay.accept(items)
    }

    /// Append items
    public func appendItems(_ items: [Item]) {
        var current = itemsRelay.value
        current.append(contentsOf: items)
        itemsRelay.accept(current)
    }

    /// Set loading state
    public func setLoading(_ loading: Bool) {
        isLoadingRelay.accept(loading)
    }
}
