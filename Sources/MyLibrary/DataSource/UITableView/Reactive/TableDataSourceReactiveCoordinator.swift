//
//  TableDataSourceReactiveCoordinator.swift
//  MyLibrary
//
//  Created by Claude Code
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa

/// Centralized reactive coordinator for TableDynamicDataSource
public final class TableDataSourceReactiveCoordinator<T: Hashable> {
    // MARK: - Properties

    private weak var dataSource: TableDynamicDataSource<T>?
    private let disposeBag = DisposeBag()

    // Relays for better memory management (no onCompleted/onError)
    private let itemsRelay = PublishRelay<[SectionDataSourceModel<T>]>()
    private let selectionRelay = PublishRelay<T>()
    private let scrollEventRelay = PublishRelay<DataSourceScrollViewConfiguration>()
    private let loadingStateRelay = BehaviorRelay<LoadingState>(value: .idle)

    // MARK: - Initialization

    init(dataSource: TableDynamicDataSource<T>) {
        self.dataSource = dataSource
        setupBindings()
    }

    // MARK: - Public Observables

    /// Observable of item selection events
    public var itemSelected: Observable<T> {
        return selectionRelay.asObservable()
    }

    /// Observable of pull-to-refresh events
    public var pullToRefresh: Observable<Void> {
        return scrollEventRelay
            .compactMap { config in
                if case .pullToRefresh = config {
                    return ()
                }
                return nil
            }
    }

    /// Observable of load more events
    public var loadMore: Observable<Void> {
        return scrollEventRelay
            .compactMap { config in
                if case .loadMore = config {
                    return ()
                }
                return nil
            }
    }

    /// Observable of scroll events
    public var didScroll: Observable<UIScrollView> {
        return scrollEventRelay
            .compactMap { config in
                if case .didScroll(let scrollView) = config {
                    return scrollView
                }
                return nil
            }
    }

    /// Observable of loading state changes
    public var loadingState: Observable<LoadingState> {
        return loadingStateRelay.asObservable()
    }

    /// Observable of all scroll view events
    public var scrollEvents: Observable<DataSourceScrollViewConfiguration> {
        return scrollEventRelay.asObservable()
    }

    // MARK: - Public Binders

    /// Binder for updating items
    public var items: Binder<[T]> {
        return Binder(self) { coordinator, items in
            let section = SectionDataSourceModel(id: "default", title: "", items: items)
            coordinator.dataSource?.updateSections(items: [section])
        }
    }

    /// Binder for updating sections
    public var sections: Binder<[SectionDataSourceModel<T>]> {
        return Binder(self) { coordinator, sections in
            coordinator.dataSource?.updateSections(items: sections)
        }
    }

    /// Binder for stopping all loading indicators
    public var stopLoading: Binder<Void> {
        return Binder(self) { coordinator, _ in
            coordinator.dataSource?.finishPullToRefresh()
            coordinator.dataSource?.finishLoadMore()
            coordinator.loadingStateRelay.accept(.idle)
        }
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Automatically update items when itemsRelay emits
        itemsRelay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak dataSource] sections in
                dataSource?.updateSections(items: sections)
            })
            .disposed(by: disposeBag)

        // Setup selection handler
        dataSource?.setItemSelectionHandler { [weak self] item in
            self?.selectionRelay.accept(item)
        }

        // Setup scroll view delegating
        dataSource?.setScrollViewDelegating { [weak self] config in
            self?.scrollEventRelay.accept(config)

            // Update loading state based on events
            switch config {
            case .pullToRefresh:
                self?.loadingStateRelay.accept(.refreshing)
            case .loadMore:
                self?.loadingStateRelay.accept(.loadingMore)
            default:
                break
            }
        }
    }

    // MARK: - Public Methods

    /// Trigger manual selection
    public func select(_ item: T) {
        selectionRelay.accept(item)
    }

    /// Update loading state manually
    public func updateLoadingState(_ state: LoadingState) {
        loadingStateRelay.accept(state)
    }
}

// MARK: - TableDynamicDataSource Extension

public extension TableDynamicDataSource {
    /// Create a reactive coordinator for this data source
    func createReactiveCoordinator() -> TableDataSourceReactiveCoordinator<T> {
        return TableDataSourceReactiveCoordinator(dataSource: self)
    }
}
