//
//  CalendarPopoverController.swift
//  Cabinbook
//
//  Created by Dai Pham on 04/02/2024.
//  Copyright © 2024 Nam Phuong Digital. All rights reserved.
//

import UIKit

public extension UIViewController {
    
    /// show Canlendar
    /// - Parameters:
    ///   - currentDate: current selected date
    ///   - sourceView: control destination for arrow
    ///   - rangeMonths: range of months to display on calendar, base ``RangeMonth``
    ///   - result: return a clouse with `Date`
    func presentCalendarComponent(
        currentDate:Date? = Date(),
        sourceView:Any?,
        rangeMonths:RangeMonth = DefaultRangeMonth(),
        _ result: @escaping ((Date?) -> Void)
    ) {
        self.view.findResignReponser()
        let group = DispatchGroup()
        group.enter()
        let vc = CalendarPopoverController(
            currentDate: currentDate,
            sourceView:sourceView,
            rangeMonths: rangeMonths,
            scrollCompleted: {
                group.leave()
            },
            result
        )
        group.notify(queue: .main) {[weak self] in
            self?.present(PopoverNavigationController(root: vc, sourceView: sourceView), animated: true)
        }
    }
}
fileprivate var screenWidth = (UIApplication.shared.keyWindow?.frame ?? UIScreen.main.bounds).size.width
fileprivate let is_smallWidth = screenWidth <= 320
fileprivate let is_iphone = UIDevice.current.userInterfaceIdiom != .pad
/* @class CalendarPopoverController */
public class CalendarPopoverController: UIViewController {

    @IBOutlet weak var calendar: CalendarComponentView!
    
    private var result: ((Date?) -> Void)
    private var sourceView:Any?
    private var sourceRect:CGRect = .zero
    private let rangeMonths:RangeMonth
    private var currentDate:Date?
    private weak var scrollView:UIScrollView? // purpose support scroll to perfect position to show calendar
    private var originOffset:CGPoint?
    public init(
        currentDate:Date?,
        sourceView:Any?,
        rangeMonths:RangeMonth,
        scrollCompleted:@escaping ()->(),
        _ result: @escaping ((Date?) -> Void)
    ) {
        self.sourceView = sourceView
        self.currentDate = currentDate
        self.result = result
        self.rangeMonths = rangeMonths
        super.init(nibName: "CalendarPopoverController", bundle: .module)
        if let sourceView = sourceView as? UIView {
            scrollView = sourceView.getScrollView()
            originOffset = scrollView?.contentOffset
            scrollToFitSpace(sourceView: sourceView,scrollCompleted: scrollCompleted)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if #available(iOS 14, *) {
            AppLogger.shared.loggerApp.log("\("\(NSStringFromClass(type(of: self))) \(#function)")")
        }
    }
    
    private func scrollToFitSpace(
        sourceView:UIView?,
        scrollCompleted:@escaping ()->()
    ) {
        guard let sourceView, let scrollView else {
            scrollCompleted()
            return
        }
        
        if let rect = sourceView.superview?.convert(sourceView.frame, to: nil) {
            let height:CGFloat = 550 // height calendar
            let heightScreen:CGFloat = sourceView.window?.frame.height ?? scrollView.frame.height
            let centerSourceViewY:CGFloat = (rect.origin.y + rect.size.height/2) - (heightScreen - scrollView.frame.height)
            var y:CGFloat?
            // check out of safe area
            if scrollView.frame.height - centerSourceViewY < height && centerSourceViewY < scrollView.frame.height/2 { // check with bottom and should be at half top side
                if centerSourceViewY < height {
                    y = height - (scrollView.frame.height - centerSourceViewY)
                }
            } else if centerSourceViewY < height && centerSourceViewY > scrollView.frame.height/2 {// check with top
                if height - centerSourceViewY < height {
                    y = -(height - centerSourceViewY)
                }
            }
            if let y {
                scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y + y), animated: true)
                Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { timer in
                    timer.invalidate()
                    scrollCompleted()
                }
            } else {
                scrollCompleted()
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let previous = UIBarButtonItem(image: Resource.Icon.back?.resizeImageWith(newSize: .standardButtonBar), style: .done, target: calendar, action: #selector(calendar.selectorBack(_:)))
        previous.tintColor = Resource.Color.onPrimary
        let next = UIBarButtonItem(image: Resource.Icon.right?.resizeImageWith(newSize: .standardButtonBar), style: .done, target: calendar, action: #selector(calendar.selectorNext(_:)))
        next.tintColor = Resource.Color.onPrimary
        let btnToday = UIButton(type: .custom)
        btnToday.setTitleStyle(title: "Today".localizedString(), color: Resource.Color.onPrimary)
        btnToday.addTarget(calendar, action: #selector(calendar.selectorToday(_:)), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = previous
        self.navigationItem.rightBarButtonItem = next
        self.navigationItem.titleView = btnToday
        
        calendar.delegate = self
        calendar.onChangeDate = {[weak self] in
            self?.result($0)
            if let originOffset = self?.originOffset {
                self?.scrollView?.setContentOffset(originOffset, animated: true)
            }
            self?.dismiss(animated: true)
        }
        updateSize()
    }
    
    @available(iOS 13,*)
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        if let currentDate {
            calendar.setCurrentDay(date: currentDate)
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #unavailable (iOS 13) {
            if let currentDate {
                calendar.setCurrentDay(date: currentDate)
            }
        }
        
        updateSize()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSize()
    }
    
    private func updateSize() {
        let width:CGFloat =
        if is_smallWidth {
            320
        } else {
            350
        }
        UIView.animate(withDuration: 0.1) {
            self.preferredContentSize = CGSizeMake(
                width,
                self.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            )
            self.navigationController?.preferredContentSize = self.preferredContentSize
        }
    }
}

extension CalendarPopoverController:CalendarComponentViewDelegate {
    public func CalendarComponentView_rangeMonths() -> RangeMonth? {
        return rangeMonths
    }
    
    public func CalendarComponentView_stateForNext(isDisabled: Bool) {
        self.navigationItem.rightBarButtonItem?.isEnabled = !isDisabled
    }
    
    public func CalendarComponentView_stateForPrevious(isDisabled: Bool) {
        self.navigationItem.leftBarButtonItem?.isEnabled = !isDisabled
    }
}

class PopoverBackgroundView: UIPopoverBackgroundView {
    
    private var offset = CGFloat(0)
    private var backgroundImageView: UIImageView!
    private var _arrow:UIPopoverArrowDirection = .any
    override var arrowDirection: UIPopoverArrowDirection {
        get { return _arrow }
        set { _arrow = newValue}
    }
    
    override var arrowOffset: CGFloat {
        get { return offset }
        set { offset = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override static func contentViewInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
    }
    
    override static func arrowHeight() -> CGFloat {
        return 20
    }
    
    override class var wantsDefaultContentAppearance: Bool {
        return true
    }
}
