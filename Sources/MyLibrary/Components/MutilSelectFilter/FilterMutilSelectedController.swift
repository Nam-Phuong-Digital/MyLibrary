//
//  FilterMutilSelectedController.swift
//  Cabinbook
//
//  Created by Dai Pham on 18/02/2024.
//  Copyright © 2024 Nam Phuong Digital. All rights reserved.
//

import UIKit

public extension UIViewController {
    func selectMutilFilter<T: Hashable & DropDownItem,S: Hashable & DropDownItem>(
        title:String? = nil,
        subTitle:String? = nil,
        sourceView:Any?,
        current: [T],
        items: [T],
        subItems: [S] = [],
        maxSelect:Int = 1,
        maxSubSelect: Int = 1,
        onMaximumSelected:(()->String)? = nil,
        result:@escaping (_ item: [T],_ subItem: [S])->()
    ) {
        let vc = FilterMutilSelectedController(
            subTitle: subTitle,
            current: current,
            items: items,
            subItems: subItems,
            maxSelect: maxSelect,
            maxSubSelect:maxSubSelect,
            onMaximumSelected: onMaximumSelected,
            result: result
        )
        if (title != nil || !subItems.isEmpty) {
            vc.title = title
            let nv = UINavigationController(rootViewController: vc)
            if #available(iOS 15.0, *) {
                if let sheet = nv.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                }
            }
            self.present(nv, animated: true)
        } else {
            let popVC = PopoverContainerController(
                sourceView: sourceView,
                contentController: vc
            )
            if #available(iOS 15.0, *) {
                if let sheet = popVC.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                }
            }
            self.present(popVC, animated: true)
        }
    }
}

class FilterMutilSelectedController<T: Hashable & DropDownItem, S: Hashable & DropDownItem>: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var subTitle: String?
    private var maxSelect:Int
    private let items: [T]
    private var current: [T]
    private var subItems: [S]
    private var result: (_ item: [T],_ subItem: [S])->()
    private var onMaximumSelected: (()->String)?
    init(
        subTitle: String?,
        current: [T],
        items: [T],
        subItems: [S] = [],
        maxSelect:Int,
        maxSubSelect:Int,
        onMaximumSelected:(()->String)?,
        result:@escaping (_ item: [T], _ subItem: [S])->()
    ) {
        self.subTitle = subTitle
        self.items = items
        self.current = current
        self.result = result
        self.maxSelect = maxSelect
        self.onMaximumSelected = onMaximumSelected
        self.subItems = subItems
        super.init(nibName: "FilterMutilSelectedController", bundle: .module)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var _dataSource:Any?
    
    private var ds: TableDynamicDataSource<T>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.maxSelect > 1 {
            let doneButton = UIBarButtonItem(image: Resource.Icon.checkMark, style: .done, target: self, action: #selector(self.selectorDone(_:)))
            doneButton.tintColor = .white
            self.navigationItem.rightBarButtonItem = doneButton
        }
        
        
        ds = .init(
            for: tableView,
            cellsType: [UITableViewCell.self],
            configCell: { [weak self] item, indexPath, tableView in guard let self else { return UITableViewCell() }
                return self.config(tableView: tableView, item: item)
            },
            itemSelected: { [weak self] item in guard let self else { return }
                if self.current.contains(item) {
                    self.current.removeAll(where: {$0 == item})
                } else {
                    if self.current.count == self.maxSelect, let message = self.onMaximumSelected?() {
                        let vc = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                        vc.addAction(.init(title: "OK", style: .cancel))
                        self.present(vc, animated: true)
                        return
                    }
                    self.current.append(item)
                    if self.maxSelect == 1 {
                        self.selectorDone(String())
                    }
                }
                self.ds.reloadItems([item])
            }
        )
        
        self.ds.updateItems(Array(Set(items)))
    }
   
    @objc func selectorDone(_ sender: Any) {
        if subItems.isEmpty {
            self.result(self.current, [])
            self.dismiss(animated: true)
        } else {
            let vc = FilterMutilSelectedController<S,S>(
                subTitle: self.subTitle,
                current: [],
                items: subItems,
                maxSelect: 1,
                maxSubSelect: 0,
                onMaximumSelected: nil
            ) {[weak self] item,_ in guard let self else { return }
                self.result(self.current, item)
            }
            vc.title = self.subTitle
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func config(tableView:UITableView, item: T) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if #available(iOS 14.0, *) {
            var configure = UIListContentConfiguration.cell()
            configure.text = item.content
            configure.textProperties.numberOfLines = 3
            cell?.contentConfiguration = configure
        } else {
            cell?.textLabel?.numberOfLines = 3
            cell?.textLabel?.text = item.content
        }
        cell?.accessoryType = self.current.contains(item) ? .checkmark : .none
        cell?.setBGColor(.clear)
        return cell ?? UITableViewCell()
    }
}
