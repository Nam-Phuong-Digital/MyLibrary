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
        if title != nil || !subItems.isEmpty {
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

class FilterMutilSelectedController<T: Hashable & DropDownItem, S: Hashable & DropDownItem>: UIViewController, UITableViewDelegate, UITableViewDataSource {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.maxSelect > 1 {
            let doneButton = UIBarButtonItem(image: Resource.Icon.checkMark, style: .done, target: self, action: #selector(self.selectorDone(_:)))
            doneButton.tintColor = .white
            self.navigationItem.rightBarButtonItem = doneButton
        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        if #available(iOS 13, *) {
            setupDataSource {
                .init(tableView: self.tableView) {[weak self] tableView, indexPath, itemIdentifier in guard let self else { return nil}
                    guard let item = itemIdentifier as? T else {
                        return nil
                    }
                    
                    return config(tableView: tableView, item: item)
                }
            }
        } else {
            tableView.dataSource = self
        }
        tableView.delegate = self
        
        updateHeight()
        
        reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateHeight()
    }
    
    private func updateHeight() {
        let max = UIScreen.bounceWindow.height * 0.8
        var height:CGFloat = CGFloat(items.count * 50)
        if let nv = self.navigationController {
            height += nv.navigationBar.frame.height
        }
        height = min(height,max)
        preferredContentSize = CGSize(width: 300, height: height)
        if let nv = self.navigationController {
            nv.preferredContentSize = preferredContentSize
            nv.parent?.preferredContentSize = preferredContentSize
        } else {
            self.parent?.preferredContentSize = preferredContentSize
        }
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
    
    private func reloadData() {
        if #available(iOS 13, *) {
            updateDataSource(items: items, section: 0)
        } else {
            tableView.reloadData()
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item: T? =
        if #available(iOS 13, *) {
            getItemIdentifier(indexPath)
        } else {
            if indexPath.row < items.count {
                items[indexPath.row]
            } else {
                nil
            }
        }
        guard let item else {return}
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
        if #available(iOS 13, *) {
            reloadDataSource(rows: [item])
        } else {
            tableView.performBatchUpdates {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.isEmpty ? 1 : items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < items.count else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        return config(tableView: tableView, item: item)
    }
}

@available(iOS 13,*)
extension FilterMutilSelectedController {
    
    @available(iOS 13.0, *)
    func getDatasource() -> UITableViewDiffableDataSource<Int,AnyHashable>? {
        return _dataSource as? UITableViewDiffableDataSource<Int,AnyHashable>
    }
    
    @available(iOS 13.0, *)
    @MainActor
    func reloadDataSource(section:Int, animated:Bool = true) {
//        dataSource?.defaultRowAnimation = .fade
        var snap = getDatasource()?.snapshot()
        if snap?.numberOfSections ?? 0 > 0 {
            snap?.reloadSections([section])
            if let snap = snap {
                getDatasource()?.apply(snap, animatingDifferences: animated)
            }
        }
    }
    
    @available(iOS 13,*)
    @MainActor
    func reloadAllSections(for tableView:UITableView,animated:Bool = true) {
        if let s = self.getDatasource()?.numberOfSections(in: tableView) {
            var sections:[Int] = []
            for i in 0..<s {
                sections.append(i)
            }
            if !sections.isEmpty {
                var snap = getDatasource()?.snapshot()
                snap?.reloadSections(sections)
                if let snap = snap {
                    getDatasource()?.apply(snap, animatingDifferences: animated)
                }
            }
        }
    }
    
    @available(iOS 13,*)
    @MainActor
    func reloadDataSource(rows:[AnyHashable], animated:Bool = true) {
        var snap = getDatasource()?.snapshot()
        snap?.reloadItems(rows)
        if let snap = snap {
            getDatasource()?.apply(snap,animatingDifferences: animated)
        }
    }
    
    @available(iOS 13,*)
    @MainActor
    func deleteTableRows(rows:[AnyHashable], animated:Bool = true) {
        var snap = getDatasource()?.snapshot()
        snap?.deleteItems(rows)
        if let snap = snap {
            getDatasource()?.apply(snap,animatingDifferences: animated)
        }
    }
    
    @available(iOS 13,*)
    func setupDataSource(_ dataSource:@escaping ()->UITableViewDiffableDataSource<Int,AnyHashable>) {
        _dataSource = dataSource()
    }
    
    @available(iOS 13,*)
    func getItemIdentifier(_ indexPath:IndexPath) -> T? {
        return getDatasource()?.itemIdentifier(for:indexPath) as? T
    }
    
    @available(iOS 13,*)
    func getItemIdentifier(_ indexPath:IndexPath) -> AnyHashable? {
        return getDatasource()?.itemIdentifier(for: indexPath)
    }
    
    @available(iOS 13,*)
    @MainActor
    func updateDataSource(
        items:[AnyHashable],
        section:Int,
        animation:UITableView.RowAnimation? = nil,
        showNodata:Bool = true,
        animated:Bool = true
    ) {
        guard let dataSource = getDatasource() else {return}
        if let animation = animation {
            dataSource.defaultRowAnimation = animation
        }
        var snapShot = NSDiffableDataSourceSnapshot<Int,AnyHashable>()
        snapShot.appendSections([section])
        if showNodata, items.isEmpty {
            snapShot.appendItems([""])
        } else {
            snapShot.appendItems(items)
        }
        dataSource.apply(snapShot, animatingDifferences: animated)
    }

    @available(iOS 13,*)
    @MainActor
    func updateDataSoure(
        animated:Bool = true,
        with snapShot:@escaping ()->NSDiffableDataSourceSnapshot<Int,AnyHashable>
    ) {
        guard let dataSource = getDatasource() else {return}
//        dataSource.defaultRowAnimation = dataSource.snapshot().numberOfItems > 0 ? .fade : .top
        dataSource.apply(snapShot(), animatingDifferences: animated)
    }
}
