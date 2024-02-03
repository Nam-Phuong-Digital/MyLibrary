//
//  LoadmoreIndicatorActivity.swift
//  Cabinbook
//
//  Created by Dai Pham on 25/07/2022.
//  Copyright © 2022 Nam Phuong Digital. All rights reserved.
//

import UIKit

public protocol LoadMoreActivityPtotocol {
    func finishLoadMore()
}

public class LoadMoreActivityIndicator {

    private let spacingFromLastCell: CGFloat
    private let spacingFromLastCellWhenLoadMoreActionStart: CGFloat
    private weak var activityIndicatorView: UIActivityIndicatorView?
    private weak var scrollView: UIScrollView?
    private var originalContentInset:UIEdgeInsets = .zero
    
    private var defaultY: CGFloat {
        guard let height = scrollView?.contentSize.height else { return 0.0 }
        return height + spacingFromLastCell
    }

    deinit { activityIndicatorView?.removeFromSuperview() }

    public init (scrollView: UIScrollView, spacingFromLastCell: CGFloat = 10, spacingFromLastCellWhenLoadMoreActionStart: CGFloat = 100) {
        self.scrollView = scrollView
        self.spacingFromLastCell = spacingFromLastCell
        self.spacingFromLastCellWhenLoadMoreActionStart = spacingFromLastCellWhenLoadMoreActionStart
        let size:CGFloat = 40
        let frame = CGRect(x: (scrollView.frame.width-size)/2, y: scrollView.contentSize.height + spacingFromLastCell, width: size, height: size)
        let activityIndicatorView = UIActivityIndicatorView(frame: frame)
        if #available(iOS 13.0, *)
        {
            activityIndicatorView.color = .label
        }
        else
        {
            activityIndicatorView.color = .black
        }
        activityIndicatorView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        activityIndicatorView.hidesWhenStopped = true
        scrollView.addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
    }

    private var isHidden: Bool {
        guard let scrollView = scrollView else { return true }
        return scrollView.contentSize.height < scrollView.frame.size.height
    }

    public func start(closure: (() -> Void)?) {
        guard let scrollView = scrollView, let activityIndicatorView = activityIndicatorView else { return }
        originalContentInset = scrollView.contentInset
        let offsetY = scrollView.contentOffset.y
//        activityIndicatorView.isHidden = isHidden
        if !isHidden && offsetY >= 0 {
            let contentDelta = scrollView.contentSize.height - scrollView.frame.size.height
            let offsetDelta = offsetY - contentDelta
            
            let newY = defaultY-offsetDelta
            if newY < scrollView.frame.height {
                activityIndicatorView.frame.origin.y = newY
            } else {
                if activityIndicatorView.frame.origin.y != defaultY {
                    activityIndicatorView.frame.origin.y = defaultY
                }
            }

            if !activityIndicatorView.isAnimating {
                if offsetY > contentDelta && offsetDelta >= spacingFromLastCellWhenLoadMoreActionStart && !activityIndicatorView.isAnimating {
                    activityIndicatorView.isHidden = false
                    activityIndicatorView.startAnimating()
                    closure?()
                }
            }

            if scrollView.isDecelerating {
                if activityIndicatorView.isAnimating && scrollView.contentInset.bottom == 0 {
                    UIView.animate(withDuration: 0.3) { [weak self] in
                        if let bottom = self?.spacingFromLastCellWhenLoadMoreActionStart {
                            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
                        }
                    }
                }
            }
        }
    }

    public func stop(completion: (() -> Void)? = nil) {
        guard let scrollView = scrollView , let activityIndicatorView = activityIndicatorView else { return }
        let contentDelta = scrollView.contentSize.height - scrollView.frame.size.height
        let offsetDelta = scrollView.contentOffset.y - contentDelta
        if offsetDelta >= 0 {
            UIView.animate(withDuration: 0.3, animations: {
            }) {[scrollView] _ in
                completion?()
                scrollView.contentInset = self.originalContentInset
            }
        } else {
            scrollView.contentInset = self.originalContentInset
            completion?()
        }
        activityIndicatorView.stopAnimating()
        activityIndicatorView.setNeedsDisplay()
    }
}
