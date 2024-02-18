//
//  FilterSingleSelectedController.swift
//  Cabinbook
//
//  Created by Dai Pham on 18/02/2024.
//  Copyright © 2024 Nam Phuong Digital. All rights reserved.
//

import UIKit

public extension UIViewController {
    func selectSingleFilter(
        title:String? = nil,
        sourceView:Any?,
        current: String?,
        items: [String],
        result:@escaping (_ T:String?)->()
    ) {
        let vc = FilterSingleSelectedController(current: current, items: items, result: result)
        if let title {
            vc.title = title
            let nv = UINavigationController(rootViewController: vc)
            let popVC = PopoverContainerController(
                sourceView: sourceView,
                contentController: nv
            )
            self.present(popVC, animated: true)
        } else {
            let popVC = PopoverContainerController(
                sourceView: sourceView,
                contentController: vc
            )
            self.present(popVC, animated: true)
        }
    }
}


class FilterSingleSelectedController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private let items:[String]
    private var current:String?
    private var result:(_ T:String?)->()
    init(
        current: String?,
        items: [String],
        result:@escaping (_ T:String?)->()
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

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        if #available(iOS 13, *) {
            setupDataSource {
                .init(tableView: self.tableView) {[weak self] tableView, indexPath, itemIdentifier in guard let self else { return nil}
                    guard let item = itemIdentifier as? String, !self.items.isEmpty else {
                        return nil
                    }
                    let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
                    if #available(iOS 14.0, *) {
                        var configure = UIListContentConfiguration.cell()
                        configure.text = item
                        cell?.contentConfiguration = configure
                    } else {
                        cell?.textLabel?.text = item
                    }
                    cell?.accessoryType = item == self.current ? .checkmark : .none
                    cell?.setBGColor(.clear)
                    return cell
                }
            }
        } else {
            tableView.dataSource = self
        }
        tableView.delegate = self
        
        let max = UIScreen.bounceWindow.height * 0.5
        var height:CGFloat = CGFloat(items.count * 50)
        if let nv = self.navigationController {
            height += nv.navigationBar.frame.height
        }
        if height > max {
            height = max
        }
        preferredContentSize = CGSize(width: 300, height: height)
        if let nv = self.navigationController {
            nv.preferredContentSize = preferredContentSize
            nv.parent?.preferredContentSize = preferredContentSize
        } else {
            self.parent?.preferredContentSize = preferredContentSize
        }
        
        reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        result(current) // involked result when dismissed
    }
    
    private func reloadData() {
        if #available(iOS 13, *) {
            updateDataSource(items: items, section: 0)
        } else {
            tableView.reloadData()
        }
    }
}

extension FilterSingleSelectedController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item: String? =
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
        self.current = item
        self.dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.isEmpty ? 1 : items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < items.count else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        if #available(iOS 14.0, *) {
            var configure = UIListContentConfiguration.cell()
            configure.text = item
            cell.contentConfiguration = configure
        } else {
            cell.textLabel?.text = item
        }
        cell.setBGColor(.clear)
        cell.accessoryType = item == self.current ? .checkmark : .none
        return cell
    }
}

@available (iOS 13,*)
extension FilterSingleSelectedController {
    
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
    
    @available (iOS 13,*)
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
    
    @available (iOS 13,*)
    @MainActor
    func reloadDataSource(rows:[AnyHashable], animated:Bool = true) {
        var snap = getDatasource()?.snapshot()
        snap?.reloadItems(rows)
        if let snap = snap {
            getDatasource()?.apply(snap,animatingDifferences: animated)
        }
    }
    
    @available (iOS 13,*)
    @MainActor
    func deleteTableRows(rows:[AnyHashable], animated:Bool = true) {
        var snap = getDatasource()?.snapshot()
        snap?.deleteItems(rows)
        if let snap = snap {
            getDatasource()?.apply(snap,animatingDifferences: animated)
        }
    }
    
    @available (iOS 13,*)
    func setupDataSource(_ dataSource:@escaping ()->UITableViewDiffableDataSource<Int,AnyHashable>) {
        _dataSource = dataSource()
    }
    
    @available (iOS 13,*)
    func getItemIdentifier<T:Codable>(_ indexPath:IndexPath) -> T? {
        return getDatasource()?.itemIdentifier(for:indexPath) as? T
    }
    
    @available (iOS 13,*)
    func getItemIdentifier<T:Hashable>(_ indexPath:IndexPath) -> T? {
        return getDatasource()?.itemIdentifier(for:indexPath) as? T
    }
    
    @available (iOS 13,*)
    func getItemIdentifier(_ indexPath:IndexPath) -> AnyHashable? {
        return getDatasource()?.itemIdentifier(for: indexPath)
    }
    
    @available (iOS 13,*)
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

    @available (iOS 13,*)
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