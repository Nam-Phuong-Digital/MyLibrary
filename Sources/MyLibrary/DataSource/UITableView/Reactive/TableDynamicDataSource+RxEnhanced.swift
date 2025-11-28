//
//  TableDynamicDataSource+RxEnhanced.swift
//  MyLibrary
//
//  Created by Claude Code
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa

// MARK: - Enhanced Reactive Extensions

public extension TableDynamicDataSource {

    /// Create a reactive coordinator for advanced reactive patterns
    /// This provides better memory management using Relays instead of Subjects
    /// - Returns: A reactive coordinator with enhanced observables and binders
    /// - Usage:
    /// ```swift
    /// let coordinator = dataSource.rxCoordinator()
    ///
    /// // Use coordinator's observables
    /// coordinator.itemSelected
    ///     .subscribe(onNext: { item in
    ///         print("Selected: \(item)")
    ///     })
    ///     .disposed(by: disposeBag)
    ///
    /// // Use coordinator's binders
    /// viewModel.items
    ///     .bind(to: coordinator.items)
    ///     .disposed(by: disposeBag)
    /// ```
    func rxCoordinator() -> TableDataSourceReactiveCoordinator<T> {
        return createReactiveCoordinator()
    }
}

// MARK: - Additional Reactive Utilities

public extension RxTableDynamicDataSourceExtension {

    /// Bind to items with error handling
    /// - Usage:
    /// ```swift
    /// viewModel.items
    ///     .bind(to: dataSource.rx.itemsWithErrorHandling { error in
    ///         print("Error loading items: \(error)")
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    func itemsWithErrorHandling(
        section: Int = 0,
        animated: Bool = true,
        errorHandler: @escaping (Error) -> Void
    ) -> Binder<Result<[T], Error>> {
        return Binder(base) { dataSource, result in
            switch result {
            case .success(let items):
                dataSource.updateItems(items, to: section, animated: animated)
            case .failure(let error):
                errorHandler(error)
            }
        }
    }

    /// Bind to sections with error handling
    func sectionsWithErrorHandling(
        errorHandler: @escaping (Error) -> Void
    ) -> Binder<Result<[SectionDataSourceModel<T>], Error>> {
        return Binder(base) { dataSource, result in
            switch result {
            case .success(let sections):
                dataSource.updateSections(items: sections)
            case .failure(let error):
                errorHandler(error)
            }
        }
    }

    // Note: totalItemsCount and isEmpty observables would require
    // access to internal data source state which isn't publicly exposed.
    // For these features, use the TableDataSourceReactiveCoordinator instead.
}

// MARK: - Reactive Helpers for Common Patterns

public extension TableDynamicDataSource {

    /// Setup standard pull-to-refresh + load more pattern
    /// - Parameters:
    ///   - refreshObservable: Observable that triggers on pull-to-refresh
    ///   - loadMoreObservable: Observable that triggers on load more
    ///   - disposeBag: DisposeBag for managing subscriptions
    /// - Usage:
    /// ```swift
    /// dataSource.setupStandardRefreshPattern(
    ///     refresh: viewModel.refresh(),
    ///     loadMore: viewModel.loadMore(),
    ///     disposeBag: disposeBag
    /// )
    /// ```
    func setupStandardRefreshPattern(
        refresh refreshObservable: Observable<[T]>,
        loadMore loadMoreObservable: Observable<[T]>,
        disposeBag: DisposeBag
    ) {
        // Pull to refresh
        rx.pullToRefresh
            .flatMapLatest { refreshObservable }
            .do(onNext: { [weak self] _ in
                self?.finishPullToRefresh()
            })
            .bind(to: rx.items)
            .disposed(by: disposeBag)

        // Load more
        rx.loadMore
            .flatMapLatest { loadMoreObservable }
            .do(onNext: { [weak self] _ in
                self?.finishLoadMore()
            })
            .bind(to: rx.appendItems())
            .disposed(by: disposeBag)
    }

    /// Setup reactive bindings with a view model
    /// - Parameters:
    ///   - itemsObservable: Observable of items to display
    ///   - refreshTrigger: Optional refresh trigger
    ///   - loadMoreTrigger: Optional load more trigger
    ///   - selectionHandler: Optional selection handler
    ///   - disposeBag: DisposeBag for managing subscriptions
    /// - Usage:
    /// ```swift
    /// dataSource.bind(
    ///     items: viewModel.items,
    ///     refresh: viewModel.refresh,
    ///     loadMore: viewModel.loadMore,
    ///     onSelect: { item in
    ///         print("Selected: \(item)")
    ///     },
    ///     disposeBag: disposeBag
    /// )
    /// ```
    func bind(
        items itemsObservable: Observable<[T]>,
        refresh refreshTrigger: (() -> Observable<Void>)? = nil,
        loadMore loadMoreTrigger: (() -> Observable<Void>)? = nil,
        onSelect selectionHandler: ((T) -> Void)? = nil,
        disposeBag: DisposeBag
    ) {
        // Bind items
        itemsObservable
            .bind(to: rx.items)
            .disposed(by: disposeBag)

        // Setup refresh if provided
        if let refreshTrigger = refreshTrigger {
            rx.pullToRefresh
                .flatMapLatest { refreshTrigger() }
                .bind(to: rx.stopPullRefresh)
                .disposed(by: disposeBag)
        }

        // Setup load more if provided
        if let loadMoreTrigger = loadMoreTrigger {
            rx.loadMore
                .flatMapLatest { loadMoreTrigger() }
                .bind(to: rx.stopLoadMore)
                .disposed(by: disposeBag)
        }

        // Setup selection if provided
        if let selectionHandler = selectionHandler {
            rx.itemSelected
                .subscribe(onNext: selectionHandler)
                .disposed(by: disposeBag)
        }
    }
}

// MARK: - Reactive Driver Extensions

public extension RxTableDynamicDataSourceExtension {

    /// Bind items using Driver (main thread guaranteed, never errors)
    /// - Usage:
    /// ```swift
    /// viewModel.itemsDriver
    ///     .drive(dataSource.rx.itemsDriver)
    ///     .disposed(by: disposeBag)
    /// ```
    var itemsDriver: Binder<[T]> {
        return Binder(base) { dataSource, items in
            DispatchQueue.main.async {
                dataSource.updateItems(items, to: 0, animated: true)
            }
        }
    }

    /// Bind sections using Driver
    var sectionsDriver: Binder<[SectionDataSourceModel<T>]> {
        return Binder(base) { dataSource, sections in
            DispatchQueue.main.async {
                dataSource.updateSections(items: sections)
            }
        }
    }

    /// Driver for item selection (never errors, main thread)
    var itemSelectedDriver: Driver<T> {
        return itemSelected.asDriver(onErrorDriveWith: .never())
    }

    /// Driver for pull to refresh events
    var pullToRefreshDriver: Driver<Void> {
        return pullToRefresh.asDriver(onErrorDriveWith: .never())
    }

    /// Driver for load more events
    var loadMoreDriver: Driver<Void> {
        return loadMore.asDriver(onErrorDriveWith: .never())
    }
}

// MARK: - Debugging and Monitoring Extensions

public extension RxTableDynamicDataSourceExtension {

    /// Observable that logs all data updates
    /// - Parameter prefix: Prefix for log messages
    /// - Returns: Observable of update events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.debug(prefix: "MyList")
    ///     .subscribe()
    ///     .disposed(by: disposeBag)
    /// ```
    func debug(prefix: String = "TableDataSource") -> Observable<String> {
        return Observable.merge(
            itemSelected.map { "\(prefix): Selected item: \($0)" },
            pullToRefresh.map { "\(prefix): Pull to refresh triggered" },
            loadMore.map { "\(prefix): Load more triggered" },
            didScroll.map { "\(prefix): Scrolled to offset: \($0.contentOffset)" }
        )
    }

    /// Monitor loading states
    /// - Returns: Observable of loading state changes
    var loadingStateMonitor: Observable<String> {
        return Observable.merge(
            pullToRefresh.map { "Loading: Pull to Refresh Started" },
            loadMore.map { "Loading: Load More Started" }
        )
    }
}
