//
//  ScrollCoordinator.swift
//  MyLibrary
//
//  Created by Claude Code
//

import UIKit
import RxSwift
import RxRelay

/// Manages scroll events and scroll-related behaviors
public final class ScrollCoordinator {
    // MARK: - Properties

    private weak var scrollView: UIScrollView?
    private let scrollEventRelay = PublishRelay<ScrollEvent>()
    private let disposeBag = DisposeBag()

    // Configuration
    private var loadMoreThreshold: CGFloat = 100.0
    private var isLoadMoreEnabled: Bool = false
    private var isPullToRefreshEnabled: Bool = false

    // MARK: - Scroll Events

    public enum ScrollEvent {
        case didScroll(UIScrollView)
        case didEndDragging(UIScrollView, willDecelerate: Bool)
        case didEndDecelerating(UIScrollView)
        case willBeginDragging(UIScrollView)
        case didScrollToTop(UIScrollView)
        case reachedBottom(UIScrollView)
        case reachedTop(UIScrollView)
    }

    // MARK: - Initialization

    public init(scrollView: UIScrollView) {
        self.scrollView = scrollView
    }

    // MARK: - Configuration

    /// Enable load more functionality
    /// - Parameter threshold: Distance from bottom to trigger load more (in points)
    public func enableLoadMore(threshold: CGFloat = 100.0) {
        self.isLoadMoreEnabled = true
        self.loadMoreThreshold = threshold
    }

    /// Disable load more functionality
    public func disableLoadMore() {
        self.isLoadMoreEnabled = false
    }

    /// Enable pull to refresh functionality
    public func enablePullToRefresh() {
        self.isPullToRefreshEnabled = true
    }

    /// Disable pull to refresh functionality
    public func disablePullToRefresh() {
        self.isPullToRefreshEnabled = false
    }

    // MARK: - Scroll View Delegate Methods

    /// Call from scrollViewDidScroll
    public func didScroll() {
        guard let scrollView = scrollView else { return }

        scrollEventRelay.accept(.didScroll(scrollView))

        // Check if reached bottom for load more
        if isLoadMoreEnabled {
            let offsetY = scrollView.contentOffset.y
            let contentHeight = scrollView.contentSize.height
            let frameHeight = scrollView.frame.size.height

            if offsetY > 0 && (offsetY + frameHeight >= contentHeight - loadMoreThreshold) {
                scrollEventRelay.accept(.reachedBottom(scrollView))
            }
        }

        // Check if at top
        if scrollView.contentOffset.y <= 0 {
            scrollEventRelay.accept(.reachedTop(scrollView))
        }
    }

    /// Call from scrollViewDidEndDragging
    public func didEndDragging(willDecelerate: Bool) {
        guard let scrollView = scrollView else { return }
        scrollEventRelay.accept(.didEndDragging(scrollView, willDecelerate: willDecelerate))
    }

    /// Call from scrollViewDidEndDecelerating
    public func didEndDecelerating() {
        guard let scrollView = scrollView else { return }
        scrollEventRelay.accept(.didEndDecelerating(scrollView))
    }

    /// Call from scrollViewWillBeginDragging
    public func willBeginDragging() {
        guard let scrollView = scrollView else { return }
        scrollEventRelay.accept(.willBeginDragging(scrollView))
    }

    /// Call from scrollViewDidScrollToTop
    public func didScrollToTop() {
        guard let scrollView = scrollView else { return }
        scrollEventRelay.accept(.didScrollToTop(scrollView))
    }

    // MARK: - Observables

    /// All scroll events
    public var events: Observable<ScrollEvent> {
        return scrollEventRelay.asObservable()
    }

    /// Scroll position changes
    public var scrollPosition: Observable<CGPoint> {
        return scrollEventRelay
            .compactMap { event in
                switch event {
                case .didScroll(let scrollView):
                    return scrollView.contentOffset
                default:
                    return nil
                }
            }
    }

    /// When scroll reaches bottom (for load more)
    public var reachedBottom: Observable<Void> {
        return scrollEventRelay
            .compactMap { event in
                if case .reachedBottom = event {
                    return ()
                }
                return nil
            }
    }

    /// When scroll reaches top
    public var reachedTop: Observable<Void> {
        return scrollEventRelay
            .compactMap { event in
                if case .reachedTop = event {
                    return ()
                }
                return nil
            }
    }

    /// Scroll velocity (calculated from drag end and deceleration)
    public var scrollVelocity: Observable<CGPoint> {
        return scrollEventRelay
            .compactMap { [weak scrollView] event in
                guard let scrollView = scrollView else { return nil }

                switch event {
                case .didEndDragging, .didEndDecelerating:
                    // Calculate velocity based on content offset change
                    // This is a simplified version - in production you might use panGestureRecognizer.velocity
                    return scrollView.panGestureRecognizer.velocity(in: scrollView)
                default:
                    return nil
                }
            }
    }

    /// Observable indicating if currently at top
    public var isAtTop: Observable<Bool> {
        return scrollEventRelay
            .compactMap { event in
                switch event {
                case .didScroll(let scrollView):
                    return scrollView.contentOffset.y <= 0
                default:
                    return nil
                }
            }
            .distinctUntilChanged()
    }

    /// Observable indicating if currently at bottom
    public var isAtBottom: Observable<Bool> {
        return scrollEventRelay
            .compactMap { [weak self] event in
                guard let self = self else { return nil }

                switch event {
                case .didScroll(let scrollView):
                    let offsetY = scrollView.contentOffset.y
                    let contentHeight = scrollView.contentSize.height
                    let frameHeight = scrollView.frame.size.height
                    return offsetY + frameHeight >= contentHeight - self.loadMoreThreshold
                default:
                    return nil
                }
            }
            .distinctUntilChanged()
    }

    // MARK: - Utility Methods

    /// Scroll to top with animation
    /// - Parameter animated: Whether to animate the scroll
    public func scrollToTop(animated: Bool = true) {
        scrollView?.setContentOffset(.zero, animated: animated)
    }

    /// Scroll to bottom with animation
    /// - Parameter animated: Whether to animate the scroll
    public func scrollToBottom(animated: Bool = true) {
        guard let scrollView = scrollView else { return }

        let bottomOffset = CGPoint(
            x: 0,
            y: scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom
        )

        if bottomOffset.y > 0 {
            scrollView.setContentOffset(bottomOffset, animated: animated)
        }
    }

    /// Get current scroll percentage (0.0 to 1.0)
    public var scrollPercentage: CGFloat {
        guard let scrollView = scrollView else { return 0 }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        guard contentHeight > frameHeight else { return 0 }

        return max(0, min(1, offsetY / (contentHeight - frameHeight)))
    }

    /// Observable of scroll percentage
    public var scrollPercentageObservable: Observable<CGFloat> {
        return scrollEventRelay
            .compactMap { [weak self] event in
                guard let self = self else { return nil }

                switch event {
                case .didScroll:
                    return self.scrollPercentage
                default:
                    return nil
                }
            }
            .distinctUntilChanged()
    }
}

// MARK: - Reactive Extensions

public extension Reactive where Base: ScrollCoordinator {
    /// All scroll events
    var events: Observable<ScrollCoordinator.ScrollEvent> {
        return base.events
    }

    /// Scroll position
    var position: Observable<CGPoint> {
        return base.scrollPosition
    }

    /// Reached bottom
    var reachedBottom: Observable<Void> {
        return base.reachedBottom
    }

    /// Reached top
    var reachedTop: Observable<Void> {
        return base.reachedTop
    }

    /// Scroll percentage (0.0 to 1.0)
    var percentage: Observable<CGFloat> {
        return base.scrollPercentageObservable
    }

    /// Is at top
    var isAtTop: Observable<Bool> {
        return base.isAtTop
    }

    /// Is at bottom
    var isAtBottom: Observable<Bool> {
        return base.isAtBottom
    }
}

// Make ScrollCoordinator ReactiveCompatible
extension ScrollCoordinator: ReactiveCompatible {}
