//
//  LoadingStateManager.swift
//  MyLibrary
//
//  Created by Claude Code
//

import UIKit
import RxSwift
import RxRelay

/// Represents the current loading state of the data source
public enum LoadingState {
    case idle
    case refreshing
    case loadingMore
    case loading

    public var isLoading: Bool {
        switch self {
        case .idle:
            return false
        default:
            return true
        }
    }

    public var isRefreshing: Bool {
        if case .refreshing = self { return true }
        return false
    }

    public var isLoadingMore: Bool {
        if case .loadingMore = self { return true }
        return false
    }
}

/// Manages loading states and UI indicators
final class LoadingStateManager {
    // MARK: - Properties

    private let stateRelay = BehaviorRelay<LoadingState>(value: .idle)
    private let refreshControl: UIRefreshControl
    private let loadMoreIndicator: DataSourceScrollViewConfiguration.LoadMoreActivityIndicator
    private let disposeBag = DisposeBag()

    /// Observable of current loading state
    var state: Observable<LoadingState> {
        return stateRelay.asObservable()
    }

    /// Current loading state value
    var currentState: LoadingState {
        return stateRelay.value
    }

    // MARK: - Initialization

    init(
        refreshControl: UIRefreshControl,
        loadMoreIndicator: DataSourceScrollViewConfiguration.LoadMoreActivityIndicator
    ) {
        self.refreshControl = refreshControl
        self.loadMoreIndicator = loadMoreIndicator
        setupBindings()
    }

    // MARK: - Public Methods

    /// Start pull-to-refresh
    func startRefreshing() {
        guard !currentState.isLoading else { return }
        stateRelay.accept(.refreshing)
        refreshControl.beginRefreshing()
    }

    /// Start load more
    func startLoadingMore(completion: (() -> Void)? = nil) {
        guard !currentState.isLoading else { return }
        stateRelay.accept(.loadingMore)
        loadMoreIndicator.start(closure: completion)
    }

    /// Stop pull-to-refresh
    func stopRefreshing() {
        refreshControl.endRefreshing()
        if currentState.isRefreshing {
            stateRelay.accept(.idle)
        }
    }

    /// Stop load more
    func stopLoadingMore() {
        loadMoreIndicator.stop()
        if currentState.isLoadingMore {
            stateRelay.accept(.idle)
        }
    }

    /// Stop all loading indicators
    func stopAll() {
        refreshControl.endRefreshing()
        loadMoreIndicator.stop()
        stateRelay.accept(.idle)
    }

    /// Check if can start loading more
    func canLoadMore() -> Bool {
        return !currentState.isLoading
    }

    /// Check if can refresh
    func canRefresh() -> Bool {
        return !currentState.isLoading
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Auto-update UI when state changes
        stateRelay
            .distinctUntilChanged { lhs, rhs in
                switch (lhs, rhs) {
                case (.idle, .idle),
                     (.refreshing, .refreshing),
                     (.loadingMore, .loadingMore),
                     (.loading, .loading):
                    return true
                default:
                    return false
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.updateUIForState(state)
            })
            .disposed(by: disposeBag)
    }

    private func updateUIForState(_ state: LoadingState) {
        switch state {
        case .idle:
            // UI cleanup handled by stop methods
            break
        case .refreshing:
            // UI setup handled by start methods
            break
        case .loadingMore:
            // UI setup handled by start methods
            break
        case .loading:
            // Generic loading state
            break
        }
    }
}
