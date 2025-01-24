//
//  TableDynamicDataSource.swift
//  LearnRXSwift
//
//  Created by Dai Pham on 17/4/24.
//

import Foundation
import UIKit
import RxSwift

public extension UITableView {
    func dequeue<T: UITableViewCell>(_ cellType: T.Type) -> T {
        dequeueReusableCell(withIdentifier: String(describing: cellType.self)) as! T
    }
    
    func dequeue<T: UITableViewHeaderFooterView>(_ headerFooterType: T.Type) -> T? {
        dequeueReusableHeaderFooterView(withIdentifier: String(describing: headerFooterType.self)) as? T
    }
    
    func register<T: UITableViewCell>(_ cellType: T.Type) {
        register(UINib(nibName: String(describing: cellType.self), bundle: nil), forCellReuseIdentifier: String(describing: cellType.self))
    }
    
    func register<T: UITableViewHeaderFooterView>(_ headerFooterType: T.Type) {
        register(UINib(nibName: String(describing: headerFooterType.self), bundle: nil), forHeaderFooterViewReuseIdentifier: String(describing: headerFooterType.self))
    }
}


/// An Object control a collection view datasource with T is Item and Cell is cell will be showed
/// ```swift
///        dataSource = TableDynamicDataSource(
///            for: self.tableView,
///            cellsType: [TableViewCell.self, NoDataCell.self],
///            sectionsType: [TableHeaderView.self, TableFooterView.self],
///            configCell: {
///                item,
///                indexPath,
///                tableView in
///                if indexPath.row % 2 == 0 {
///                    let cell = tableView.dequeue(TableViewCell.self)
///                    cell.show(item)
///                    // cell.transform = .flip() //for chat
///                    return cell
///                } else {
///                    let cell = tableView.dequeue(TableViewCell2.self)
///                    // cell.transform = .flip() // for chat
///                    return cell
///                }
///            },
///            configHeaderFooter: { sectionModel, section, tableView, kind in
///                if case .header = kind {
///                    let view = tableView.dequeue(TableHeaderView.self)
///                    view?.show(UUID().uuidString)
///                    // view?.transform = .flip() //for chat
///                    return view
///                }
///                if case .footer = kind {
///                    let view = tableView.dequeue(TableFooterView.self)
///                    view?.show(UUID().uuidString)
///                    // view?.transform = .flip() // for chat
///                    return view
///                }
///                return nil
///            },
///            itemSelected: {[weak self] item in
///
///                self?.dataSource.removeItems(items: [item])
///                /*
///                 if let section = self?.dataSource.sections[0] {
///                 self?.dataSource.removeSections([section])
///                 }*/
///            },
///            configuration: .init(
///                leadingSwipeActionsConfiguration: { item, indexPath in
///                    return UISwipeActionsConfiguration(actions: [
///                        .init(style: .normal, title: "test", handler: { _, _, completion in
///                            completion(true)
///                        })
///                    ])
///                },
///                trailingSwipeActionsConfiguration: { item, indexPath in
///                    return UISwipeActionsConfiguration(actions: [
///                        .init(style: .destructive, title: "test", handler: { _, _, completion in
///                            completion(true)
///                        })
///                    ])
///                },
///                textNoData: "There are no items."
///            )
///        )
/// ```
public class TableDynamicDataSource<T: Hashable> :NSObject, UITableViewDelegate, UITableViewDataSource {
    public enum SupplementaryType {
        case footer
        case header
    }
    public class Configuration {
        var havePullToRefresh: Bool = false
        var leadingSwipeActionsConfiguration: SWIPE_CONFIGURATION<T> = nil
        var trailingSwipeActionsConfiguration: SWIPE_CONFIGURATION<T> = nil
        var textNoData: String?
        var viewNoData: UIView?
        var contentInsert: UIEdgeInsets
        
        /// Set up some advanced features for the tableView data source.
        /// - Parameters:
        ///   - leadingSwipeActionsConfiguration: Configure actions for swiping from left to right.
        ///   - trailingSwipeActionsConfiguration: Configure actions for swiping from right to left.
        ///   - textNoData: Text to show when there are no items.
        ///   - viewNoData: View to display when there are no items. This view will be shown with higher priority than textNoData.
        public init(
            havePullToRefresh: Bool = false,
            leadingSwipeActionsConfiguration: SWIPE_CONFIGURATION<T> = nil,
            trailingSwipeActionsConfiguration: SWIPE_CONFIGURATION<T> = nil,
            textNoData: String? = nil,
            viewNoData: UIView? = nil,
            contentInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 150, right: 0)
        ) {
            self.havePullToRefresh = havePullToRefresh
            self.leadingSwipeActionsConfiguration = leadingSwipeActionsConfiguration
            self.trailingSwipeActionsConfiguration = trailingSwipeActionsConfiguration
            self.textNoData = textNoData
            self.viewNoData = viewNoData
            self.contentInsert = contentInset
        }
        
        public static var `default`: Configuration {
            Configuration(
                textNoData: "There are no items."
            )
        }
    }
    
    private var _dataSource: Any?
    let tableView: UITableView
    
    var configCell: ((_ item: T,_ indexPath: IndexPath,_ tableView: UITableView) -> UITableViewCell)
    var configHeaderFooter: ((_ sectionModel: SectionDataSourceModel<T>,_ section: Int,_ tableView: UITableView, _ kind: SupplementaryType) -> UITableViewHeaderFooterView?)?
    private var heightForCell: ((_ indexPath: IndexPath,_ tableView: UITableView) -> CGFloat?)?
    
    private let refreshControl: UIRefreshControl = UIRefreshControl()
    private let loadMoreIndicator: DataSourceScrollViewConfiguration.LoadMoreActivityIndicator
    private var selectingItem:SELECTED_ITEM<T>
    private let configuration: Configuration
    
    public var sections:[SectionDataSourceModel<T>] = []
    public var scrollViewDelegating:((DataSourceScrollViewConfiguration) -> Void)?
    
    private var shouldReloadSections: [Int] = []
    
    private let _items = PublishSubject<[SectionDataSourceModel<T>]>()
    public var items: AnyObserver<[SectionDataSourceModel<T>]> { return _items.asObserver() }
    private let _stopLoading = PublishSubject<Void>()
    public var stopLoading: AnyObserver<Void> { return _stopLoading.asObserver() }
    
    private let disposeBag = DisposeBag()
    
    /// Declare a data source with dynamic cells and dynamic header and footer views.
    /// - Parameters:
    ///   - tableView: The tableView is applied.
    ///   - cellsType: List cell types registered to display.
    ///   - sectionsType: List of header and footer view types registered to display. Leave it empty to not display footer or header views.
    ///   - configCell: The closure retrieves a cell based on the item and indexPath.
    ///   - configHeaderFooter: The closure retrieves a footer or header view based on the section. It's optional
    ///   - itemSelected: The closure returns a selected item.
    ///   - configuration: ``Configuration`` set up leading and trailing swipe actions, and display a notice text when there are no items.
    public init(
        for tableView: UITableView,
        cellsType: [UITableViewCell.Type],
        sectionsType:[UITableViewHeaderFooterView.Type] = [],
        configCell:@escaping ((_ item: T,_ indexPath: IndexPath,_ tableView: UITableView) -> UITableViewCell),
        configHeaderFooter: ((_ sectionModel: SectionDataSourceModel<T>,_ section: Int,_ tableView: UITableView, _ kind: SupplementaryType) -> UITableViewHeaderFooterView?)? = nil,
        itemSelected: SELECTED_ITEM<T> = nil,
        heightForCell: ((_ indexPath: IndexPath,_ tableView: UITableView) -> CGFloat?)? = nil,
        configuration: Configuration = .default
    ) {
        self.tableView = tableView
        loadMoreIndicator = DataSourceScrollViewConfiguration.LoadMoreActivityIndicator(scrollView: self.tableView)
        self.selectingItem = itemSelected
        self.configuration = configuration
        self.configCell = configCell
        self.configHeaderFooter = configHeaderFooter
        self.heightForCell = heightForCell
        super.init()
        cellsType.forEach({ self.register(for: $0) })
        sectionsType.forEach({ self.register(for: $0) })
        if #available(iOS 13, *), !TEST_OLD_VERSION {
            self.setUpDataSource(configCell: configCell)
        } else {
            self.tableView.dataSource = self
        }
        self.tableView.delegate = self

        tableView.estimatedSectionFooterHeight = 50
        tableView.estimatedSectionHeaderHeight = 50
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0 // Remove the padding at the top for UITableView with a style different from plain.
        }
        tableView.tableHeaderView = UIView(frame: .init(origin: .zero, size: CGSize(width: 0, height: Double.leastNonzeroMagnitude)))
        tableView.contentInsetAdjustmentBehavior = .scrollableAxes // Prevent the padding at the top from increasing when pulling to refresh.
        
        tableView.contentInset = configuration.contentInsert
        loadMoreIndicator.originalContentInset = configuration.contentInsert
        
        // setup pull to refresh
        if configuration.havePullToRefresh {
            tableView.addSubview(refreshControl)
            tableView.sendSubviewToBack(refreshControl)
            refreshControl.tintColor = Resource.Color.primary
            refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
        }
        
        _items
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { owner, items in
                owner.finishLoadMore()
                owner.finishPullToRefresh()
                owner.updateSections(items: items)
            })
            .disposed(by: self.disposeBag)
        
        _stopLoading
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { owner, _ in
                owner.finishLoadMore()
                owner.finishPullToRefresh()
            })
            .disposed(by: self.disposeBag)
    }
    
    @objc func refreshAction(_ sender: Any) {
        self.scrollViewDelegating?(.pullToRefresh)
    }
   
    public func updateItems(_ items: [T], to section: Int = 0, animated: Bool = true) {
        if self.sections.isEmpty /*&& !(self is TableSectionsDataSource)*/ {
            self.sections = [SectionDataSourceModel(id: "", title: "", items: [])]
        }
        guard section < self.sections.count else {return}
        self.sections[section].updateItems(items)
        reloadData(animated)
    }
    
    public func appendItems(items: [T], to section: Int = 0) {
        if self.sections.isEmpty /*&& !(self is TableSectionsDataSource)*/ {
            self.sections = [SectionDataSourceModel(id: "", title: "", items: [])]
        }
        guard section < self.sections.count else {return}
        self.sections[section].appendItems(items)
        reloadData()
    }
    
    public func updateSections(items: [SectionDataSourceModel<T>]) {
        shouldReloadSections = []
        var section = 0
        zip(self.sections, items).forEach { (old, new) in
            if old != new {
                shouldReloadSections.append(section)
            }
            section += 1
        }
        self.sections = items
        reloadData()
    }
    
    public func appendSections(items: [SectionDataSourceModel<T>]) {
        self.sections.append(contentsOf: items)
        reloadData()
    }
    
    public func reloadSections(_ sections: [Int], animated: Bool = true) {
        if #available(iOS 13, *), !TEST_OLD_VERSION {
            var snap = self.getDataSource().snapshot()
            let numberSections = snap.numberOfSections
            let interSects = Array(Set(0..<numberSections).intersection(Set(sections)))
            snap.reloadSections(interSects)
            self.getDataSource().apply(snap, animatingDifferences: animated)
        } else {
            let numberSections = tableView.numberOfSections
            let interSects = IndexSet(Array(Set(0..<numberSections).intersection(Set(sections))))
            self.tableView.performBatchUpdates {
                self.tableView.reloadSections(interSects, with: animated ? .fade : .none)
            }
        }
        
    }
    
    public func reloadItems(_ items: [T], animated: Bool = true) {
        if #available(iOS 13, *), !TEST_OLD_VERSION {
            var snap = self.getDataSource().snapshot()
            snap.reloadItems(items)
            self.getDataSource().apply(snap, animatingDifferences: animated)
        } else {
            var indexPaths: [IndexPath] = []
            self.sections.enumerated().forEach { (offset, section) in
                section.items.enumerated().forEach { (row, item) in
                    if items.contains(item) {
                        indexPaths.append(IndexPath(row: row, section: offset))
                    }
                }
            }
            if !indexPaths.isEmpty {
                UIView.performWithoutAnimation {
                    self.tableView.performBatchUpdates {
                        self.tableView.reloadRows(at: indexPaths, with: animated ? .fade : .none)
                    }
                }
            }
        }
    }
    
    public func removeSections(_ sections: [SectionDataSourceModel<T>]) {
        self.sections.removeAll(where: { section in sections.contains(section) })
        if #available(iOS 13, *), !TEST_OLD_VERSION {
            // reload sections
            let sections = self.sections.enumerated().compactMap({ (offset, section) in
                if sections.contains(section) {
                    return offset
                }
                return nil
            })
            if !sections.isEmpty {
                var snap = getDataSource().snapshot()
                snap.reloadSections(sections)
                getDataSource().apply(snap)
            }
        }
        reloadData()
    }
    
    public func removeItems(items: [T]) {
        for item in items {
            if #available(iOS 13, *), !TEST_OLD_VERSION {
                if let indexPath = getDataSource().indexPath(for: item) {
                    // remove item at section
                    self.sections[indexPath.section].removeItem(indexPath.row)
                    if self.sections[indexPath.section].items.isEmpty {
                        // remove section if items  is empty
                        self.sections.remove(at: indexPath.section)
                        // reload section purpose for delete section's empty items
                        var snap = getDataSource().snapshot()
                        snap.reloadSections([indexPath.section])
                        getDataSource().apply(snap)
                    }
                }
            } else {
                let temp = self.sections
                for (offset,section) in temp.enumerated() {
                    if section.items.contains(item) {
                        temp[offset].removeItem(item)
                    }
                }
                self.sections = temp
            }
        }
        reloadData()
    }
    
    func reloadData(_ animated: Bool = true) {
        if self.sections.flatMap({ $0.items }).isEmpty {
            self.showNoData()
        } else {
            self.hideNoData()
        }
        if #available(iOS 13, *), !TEST_OLD_VERSION {
            var snap = NSDiffableDataSourceSnapshot<Int, T>()
            let sectionIndex = self.sections.enumerated().map{$0.0}
            snap.appendSections(sectionIndex)
            if !shouldReloadSections.isEmpty {
                snap.reloadSections(shouldReloadSections)
                shouldReloadSections = []
            }
            self.sections.enumerated().forEach { (offset,section) in
                snap.appendItems(section.items, toSection: offset)
            }
            DispatchQueue.main.async {
                self.getDataSource().apply(snap, animatingDifferences: animated)
            }
        } else {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    public func finishPullToRefresh() {
        refreshControl.endRefreshing()
    }
    
    public func finishLoadMore() {
        loadMoreIndicator.stop()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item: T? =
        if #available(iOS 13, *), !TEST_OLD_VERSION {
            getDataSource().itemIdentifier(for: indexPath)
        } else {
            if indexPath.section < sections.count, indexPath.item < sections[indexPath.section].items.count {
                sections[indexPath.section].items[indexPath.item]
            } else { nil }
        }
        guard let item else {return}
        selectingItem?(item)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegating?(.didScroll(scrollView: scrollView))
        // in case this closure have not implemented then it shouldn't executed
        if scrollViewDelegating != nil {
            self.scrollViewDelegating?(.shoudLoadMore({ [weak self] should in
                if should {
                    self?.loadingMore { [weak self] in
                        self?.scrollViewDelegating?(.loadMore)
                    }
                }
            }))
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegating?(.didEndDecelerating(scrollView: scrollView))
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewDelegating?(.didEndDragging(scrollView: scrollView))
    }
    
    public func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        scrollViewDelegating?(.willDisplayHeader(section: section, view: view))
    }
    
    public func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        scrollViewDelegating?(.willDisplayFooter(section: section, view: view))
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
        scrollViewDelegating?(.didEndDisplayHeader(section: section, view: view))
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int) {
        scrollViewDelegating?(.didEndDisplayFooter(section: section, view: view))
    }
    
    private func loadingMore(closure: (() -> Void)?) {
        loadMoreIndicator.start (closure: closure)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= sections.count {
            return 0
        }
        return sections[section].items.count
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < sections.count, indexPath.item < sections[indexPath.section].items.count else {
            return UITableViewCell()
        }
        let item = sections[indexPath.section].items[indexPath.item]
        return configCell(item, indexPath, tableView)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        self.heightForCell?(indexPath, tableView) ?? UITableView.automaticDimension
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section >= sections.count {
            return 0
        }
        return configHeaderFooter?(sections[section], section, tableView, .footer) == nil ? 0 : UITableView.automaticDimension
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section >= sections.count {
            return 0
        }
        return configHeaderFooter?(sections[section], section, tableView, .header) == nil ? 0 : UITableView.automaticDimension
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section >= sections.count {
            return nil
        }
        return configHeaderFooter?(sections[section],section,tableView,.header)
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section >= sections.count {
            return nil
        }
        return configHeaderFooter?(sections[section],section,tableView,.footer)
    }
    
    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item: T? =
        if #available(iOS 13, *), !TEST_OLD_VERSION {
            getDataSource().itemIdentifier(for: indexPath)
        } else {
            if indexPath.section < sections.count, indexPath.item < sections[indexPath.section].items.count {
                sections[indexPath.section].items[indexPath.item]
            } else { nil }
        }
        guard let item else {return nil}
        return configuration.leadingSwipeActionsConfiguration?(item, indexPath)
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item: T? =
        if #available(iOS 13, *), !TEST_OLD_VERSION {
            getDataSource().itemIdentifier(for: indexPath)
        } else {
            if indexPath.section < sections.count, indexPath.item < sections[indexPath.section].items.count {
                sections[indexPath.section].items[indexPath.item]
            } else { nil }
        }
        guard let item else {return nil}
        return configuration.trailingSwipeActionsConfiguration?(item, indexPath)
    }
}

private extension TableDynamicDataSource {
    
    func showNoData() {
        hideNoData()
        if let viewNoData = configuration.viewNoData {
            self.tableView.addSubview(viewNoData)
            viewNoData.translatesAutoresizingMaskIntoConstraints = false
            viewNoData.tag = 10000000
            self.tableView.addConstraints(
                [
                    .init(item: self.tableView, attribute: .centerXWithinMargins, relatedBy: .equal, toItem: viewNoData, attribute: .centerXWithinMargins, multiplier: 1, constant: 0),
                    .init(item: self.tableView, attribute: .centerYWithinMargins, relatedBy: .equal, toItem: viewNoData, attribute: .centerYWithinMargins, multiplier: 1, constant: 0)
                ]
            )
        } else if let text = configuration.textNoData {
            let label = UILabel()
            label.tag = 10000000
            label.font = .systemFont(ofSize: 16)
            label.textColor = .gray
            label.textAlignment = .center
            label.text = text
            self.tableView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            self.tableView.addConstraints(
                [
                    .init(item: self.tableView, attribute: .centerXWithinMargins, relatedBy: .equal, toItem: label, attribute: .centerXWithinMargins, multiplier: 1, constant: 0),
                    .init(item: self.tableView, attribute: .centerYWithinMargins, relatedBy: .equal, toItem: label, attribute: .centerYWithinMargins, multiplier: 1, constant: 0)
                ]
            )
        }
    }
    
    func hideNoData() {
        self.tableView.viewWithTag(10000000)?.removeFromSuperview()
    }
    
    func register(for cell: UITableViewCell.Type) {
        self.tableView.register(cell)
    }
    
    func register(for view: UITableViewHeaderFooterView.Type) {
        self.tableView.register(view)
    }
}

@available(iOS 13,*)
public extension TableDynamicDataSource {
    
    func getDataSource() -> SwipableDataSource<T> {
        let ds =  self._dataSource as! SwipableDataSource<T>
        ds.defaultRowAnimation = .fade
        return ds
    }
    
    private func setUpDataSource(
        configCell:@escaping ((_ item: T,_ indexPath: IndexPath,_ tableView: UITableView) -> UITableViewCell)
    ) {
        self._dataSource = SwipableDataSource<T>(tableView: self.tableView, cellProvider: { tableView, indexPath, itemIdentifier in
            return configCell(itemIdentifier, indexPath, tableView)
        })
    }
}
@available(iOS 13,*)
public class SwipableDataSource<T: Hashable>: UITableViewDiffableDataSource<Int, T> {
    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
