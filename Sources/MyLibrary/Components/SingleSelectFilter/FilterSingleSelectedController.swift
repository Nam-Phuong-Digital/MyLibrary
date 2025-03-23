//
//  FilterSingleSelectedController.swift
//  Cabinbook
//
//  Created by Dai Pham on 18/02/2024.
//  Copyright © 2024 Nam Phuong Digital. All rights reserved.
//

import UIKit

public typealias MyActionHandler<T: Hashable & DropDownItem> = (T) -> Void
@available(iOS 13,*)
public class MyAction<T: Hashable & DropDownItem>: UIAction {
    public var object: T
    public convenience init(
        _ object: T,
        title: String = "",
        image: UIImage? = nil,
        identifier: UIAction.Identifier? = nil,
        discoverabilityTitle: String? = nil,
        attributes: UIMenuElement.Attributes = [],
        state: UIMenuElement.State = .off,
        handler: @escaping MyActionHandler<T>
    ) {
        self.init(title: title, image: image, identifier: identifier, discoverabilityTitle: discoverabilityTitle, attributes: attributes, state: state, handler: { _ in
            handler(object)
        })
        self.object = object
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension UIViewController {
    
    func makeBarButtonItemMenu<T: Hashable & DropDownItem>(
        title:String? = nil,
        image: UIImage? = nil,
        current: T?,
        items: [T],
        action: Selector?,
        result:@escaping (_ item:T?)->()
    ) -> UIBarButtonItem? {
        if #available(iOS 14, *) {
            let menus = UIMenu(title: title ?? "",
                               children: items.compactMap{
                MyAction<T>.init(
                    $0,
                    title: $0.content,
                    image: nil,
                    state: current == $0 ? .on : .off) { selected in
                        result(selected)
                    }
                }
            )
            return UIBarButtonItem(title: title, image: image, menu: menus)
        } else {
            if let title {
                return UIBarButtonItem(title: title, style: .plain, target: self, action: action)
            } else if let image {
                return UIBarButtonItem(image: image, style: .plain, target: self, action: action)
            } else {
                return UIBarButtonItem(title: "", style: .plain, target: self, action: action)
            }
        }
    }
    
    func selectSingleAction<T: Hashable & DropDownItem>(
        title:String? = nil,
        for button:UIButton,
        current: T?,
        items: [T],
        result:@escaping (_ item:T?)->()
    ) {
        self.selectSingleFilter(title: title, sourceView: button, current: current, items: items, result: result)
    }
    
    func selectSingleFilter<T: Hashable & DropDownItem>(
        title:String? = nil,
        sourceView:Any?,
        current: T?,
        items: [T],
        result:@escaping (_ T:T?)->()
    ) {
        let vc = FilterSingleSelectedController<T>(current: current, items: items, result: result)
        if let title {
            vc.title = title
            let nv = UINavigationController(rootViewController: vc)
            self.present(nv, animated: true)
            if #available(iOS 15.0, *) {
                if let sheet = nv.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                }
            }
        } else {
            self.present(vc, animated: true)
            if #available(iOS 15.0, *) {
                if let sheet = vc.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                }
            }
        }
    }
}

public struct FilterSingleSelectedObject: Hashable {
    public static func == (lhs: FilterSingleSelectedObject, rhs: FilterSingleSelectedObject) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    let id:String = .generateIdentifier
    public let object:Any?
    public let title:String
    public init(object: Any?, title: String) {
        self.object = object
        self.title = title
    }
}

class FilterSingleSelectedController<T: Hashable & DropDownItem>: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var ds: TableDynamicDataSource<T>!
    
    private let items:[T]
    private var current:T?
    private var result:(_ T:T?)->()
    init(
        current: T?,
        items: [T],
        result:@escaping (_ item:T?)->()
    ) {
        self.items = items
        self.current = current
        self.result = result
        super.init(nibName: "FilterSingleSelectedController", bundle: .module)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var _dataSource:Any?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ds = .init(
            for: tableView,
            cellsType: [UITableViewCell.self],
            configCell: { item, indexPath, tableView in
                let cell = tableView.dequeue(UITableViewCell.self)
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
                return cell
            },
            itemSelected: { [weak self] selectedItem in guard let self else { return }
                self.current = selectedItem
                self.dismiss(animated: true)
            }
        )
        
        self.ds.updateItems(Array(Set(items)))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        result(current) // involked result when dismissed
    }
}
