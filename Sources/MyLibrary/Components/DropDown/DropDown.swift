//
//  DropDown.swift
//  Cabinbook
//
//  Created by Dai Pham on 18/02/2024.
//  Copyright © 2024 Nam Phuong Digital. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public protocol DropDownItem {
    var content: String { get }
}

public extension UIViewController {
    func presentDropdown<T: Hashable & DropDownItem>(
        sourceView:Any?,
        current: T?,
        items: [T],
        canInteract: Bool = false,
        result:@escaping (_ T:T?)->()
    ) {
        guard !items.isEmpty else {return}
        let vc = DropDown(
            current: current,
            items: items,
            sourceView: sourceView,
            holdController: self,
            canInteract: canInteract,
            result: result
        )
        self.present(vc, animated: true)
        
    }
}

fileprivate class DropDown<T: Hashable & DropDownItem>: UIViewController, UIPopoverPresentationControllerDelegate {

    struct Item: Hashable {
        let title: String
    }
    private let disposeBag = DisposeBag()
    @IBOutlet weak var tableView: UITableView!
    private var sourceView:Any?
    private let items:[T]
    private var current:T?
    private var result:(_ T:T?)->()
    init(
        current: T?,
        items: [T],
        sourceView:Any?,
        holdController: UIViewController?,
        canInteract:Bool,
        result:@escaping (_ T:T?)->()
    ) {
        self.items = items
        self.current = current
        self.result = result
        self.sourceView = sourceView
        super.init(nibName: "DropDown", bundle: .module)
        self.modalPresentationStyle = .popover
        if let pop = self.popoverPresentationController {
            pop.canOverlapSourceViewRect = true
            pop.popoverBackgroundViewClass = DropdownBackground.self
            pop.delegate = self
//            if let view = sourceView as? UIView, canInteract {
//                pop.passthroughViews = [view] // view can interactive
//            }
            if let vc = holdController {
                pop.sourceView = vc.view
                if let sourceView = sourceView as? UIView,
                   let rect = sourceView.superview?.convert(sourceView.frame, to: vc.view)
                {
                    pop.sourceRect = rect
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var ds: TableDataSource<T, UITableViewCell>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ds = TableDataSource(
            for: tableView,
            configCell: {[weak self] item, indexPath, cell in guard let self else { return }
            if #available(iOS 14.0, *) {
                var configure = UIListContentConfiguration.cell()
                configure.text = item.content
                configure.textProperties.numberOfLines = 3
                cell.contentConfiguration = configure
            } else {
                cell.textLabel?.numberOfLines = 3
                cell.textLabel?.text = item.content
            }
            cell.accessoryType = item == self.current ? .checkmark : .none
            cell.setBGColor(.clear)
        },
            itemSelected: {[weak self] item in guard let self else { return }
                self.current = item
                self.dismiss(animated: true)
            }
        )
        tableView.contentInset = .zero
        
        let width: CGFloat
        if let sourceView = sourceView as? UIView {
            width = max(300, sourceView.frame.width)
        } else {
            width = max(300, (popoverPresentationController?.sourceRect.width ?? 0) - 30)
        }
        let max = UIScreen.bounceWindow.height * 0.8
//        var height:CGFloat = CGFloat(items.count * 50)
//        if let nv = self.navigationController {
//            height += nv.navigationBar.frame.height
//        }
//        height = min(height,max)
//        preferredContentSize = CGSize(width: width, height: height)
        
        ds.updateItems(items)
        
        tableView.rx.observe(CGSize.self, #keyPath(UIScrollView.contentSize))
            .map { $0?.height }
            .filter { [weak self] in $0 != nil && self?.preferredContentSize.height != $0 }
            .map { $0! }
            .distinctUntilChanged()
            .subscribe(with: self, onNext: { s, height in
                if height > self.preferredContentSize.height {
                    s.preferredContentSize =
                    CGSize(
                        width: width,
                        height: height
                    )
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        result(current) // involked result when dismissed
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        .none
    }
}

fileprivate class DropdownBackground: UIPopoverBackgroundView {
    
    private var offset = CGFloat(0)
    private var arrow = UIPopoverArrowDirection.any
    
    override class func contentViewInsets() -> UIEdgeInsets {
        return .zero
    }
    
    override class func arrowHeight() -> CGFloat {
        return .zero
    }
    
    override var arrowDirection: UIPopoverArrowDirection {
        get {
            return arrow
        }
        set {
            arrow = newValue
        }
    }
    override var arrowOffset: CGFloat {
        get {
            return offset
        }
        set {
            self.offset = newValue
        }
    }
    
    override class func arrowBase() -> CGFloat {
        .zero
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.isHidden = true // hidden this background to remove default shadow
    }
}

fileprivate extension UIViewController {
    func getFirst() -> UIViewController? {
        if let parent = self.parent {
            return parent.getFirst()
        }
        return self
    }
}
