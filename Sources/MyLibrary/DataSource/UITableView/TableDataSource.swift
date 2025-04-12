//
//  TableDataSource.swift
//  LearnRXSwift
//
//  Created by Dai Pham on 17/4/24.
//

import Foundation
import UIKit
#if canImport(RxSwift)
import RxSwift
#endif
public typealias ConfigCell<T: Hashable, CELL: UITableViewCell> = ((_ item: T,_ indexPath: IndexPath, _ cell: CELL) ->Void)
public typealias SELECTED_ITEM<T: Hashable> = ((T) -> Void)?
public typealias SWIPE_CONFIGURATION<T: Hashable> = ((_ item: T,_ indexPath: IndexPath) -> UISwipeActionsConfiguration?)?

public enum TableDataSourceAction {
    case endLoading
}

/// An Object control a collection view datasource with T is Item and Cell is cell will be showed
/// ```swift
///        var dataSource: TableDataSource<ItemModel, TableViewCell>!
///
///        dataSource = TableSectionsDataSource(
///            for: self.tableView,
///            // config content for registered cell
///            configCell: {
///                item, indexPath, cell in
///                cell.show(item)
///            },
///            // handling item selected
///            itemSelected: {[weak self] item in
///                if let section = self?.dataSectionsSource.sections[0] {
///                    self?.dataSectionsSource.removeSections([section])
///                }
///            }
///        )
/// ```
public class TableDataSource<T: Hashable, CELL: UITableViewCell>:NSObject, UITableViewDelegate, UITableViewDataSource {
    
    public class Configuration {
        var havePullToRefresh: Bool = false
        var haveLoadMore: Bool = false
        var leadingSwipeActionsConfiguration: SWIPE_CONFIGURATION<T> = nil
        var trailingSwipeActionsConfiguration: SWIPE_CONFIGURATION<T> = nil
        var textNoData: String?
        var viewNoData: UIView?
        
        /// Set up some advanced features for the tableView data source.
        /// - Parameters:
        ///   - leadingSwipeActionsConfiguration: Configure actions for swiping from left to right.
        ///   - trailingSwipeActionsConfiguration: Configure actions for swiping from right to left.
        ///   - textNoData: Text to show when there are no items.
        ///   - viewNoData: View to display when there are no items. This view will be shown with higher priority than textNoData.
        public init(
            havePullToRefresh: Bool = false,
            haveLoadMore: Bool = false,
            leadingSwipeActionsConfiguration: SWIPE_CONFIGURATION<T> = nil,
            trailingSwipeActionsConfiguration: SWIPE_CONFIGURATION<T> = nil,
            textNoData: String? = nil,
            viewNoData: UIView? = nil
        ) {
            self.havePullToRefresh = havePullToRefresh
            self.haveLoadMore = haveLoadMore
            self.leadingSwipeActionsConfiguration = leadingSwipeActionsConfiguration
            self.trailingSwipeActionsConfiguration = trailingSwipeActionsConfiguration
            self.textNoData = textNoData
            self.viewNoData = viewNoData
        }
        
        public static var `default`: Configuration {
            Configuration(
                textNoData: "There are no items."
            )
        }
    }
    
    private var _dataSource: Any?
    let tableView: UITableView
    
    private let refreshControl: UIRefreshControl = UIRefreshControl()
    private let loadMoreIndicator: DataSourceScrollViewConfiguration.LoadMoreActivityIndicator
    private var selectingItem:SELECTED_ITEM<T>
    private var configCell:ConfigCell<T, CELL>
    private let configuration: Configuration
    
    public var sections:[SectionDataSourceModel<T>] = []
    public var scrollViewDelegating:((DataSourceScrollViewConfiguration) -> Void)?
    
    private var shouldReloadSections: [Int] = []
    
#if canImport(RxSwift)
    private let _stopLoading = PublishSubject<Void>()
    public var stopLoading: AnyObserver<Void> { return _stopLoading.asObserver() }
    private let _scrollViewAction = PublishSubject<DataSourceScrollViewConfiguration>()
    private let _items = PublishSubject<[SectionDataSourceModel<T>]>()
    public var items: AnyObserver<[SectionDataSourceModel<T>]> { return _items.asObserver() }
    private let _selectedItem = PublishSubject<T>()
    private let disposeBag = DisposeBag()
    public struct Input {
        let items: Observable<[SectionDataSourceModel<T>]>
        let action: Observable<TableDataSourceAction>
        public init(items: Observable<[SectionDataSourceModel<T>]>, action: Observable<TableDataSourceAction>) {
            self.items = items
            self.action = action
        }
    }
    public struct Output {
        public let selectedItem: Observable<T>
        public let scrollViewAction: Observable<DataSourceScrollViewConfiguration>
        public init(selectedItem: Observable<T>, scrollViewAction: Observable<DataSourceScrollViewConfiguration>) {
            self.selectedItem = selectedItem
            self.scrollViewAction = scrollViewAction
        }
    }
    public func transform(_ input: Input) -> Output {
        
        let getItems = input.items.share(replay: 1, scope: .whileConnected)
        
        Observable<TableDataSourceAction>.merge(
            input.action,
            getItems.map({_ in .endLoading})
        )
        .observe(on: MainScheduler.instance)
        .subscribe(with: self, onNext: { owner, action in
                switch action {
                case .endLoading:
                    owner.finishLoadMore()
                    owner.finishPullToRefresh()
                }
        })
        .disposed(by: self.disposeBag)
        
        getItems
            .observe(on: MainScheduler.instance)
            .subscribe(with: self, onNext: { owner, items in
                owner.finishLoadMore()
                owner.finishPullToRefresh()
                owner.updateSections(items: items)
            })
            .disposed(by: self.disposeBag)
        
        return Output(
            selectedItem: _selectedItem.asObserver(),
            scrollViewAction: _scrollViewAction.asObserver()
        )
    }
#endif
    
    
    /// data source manage behaviours of table view
    /// - Parameters:
    ///   - tableView: `UITableView` to handle.
    ///   - configCell: closure call back with `T` generic  object, indexPath of item. `CELL` registered.
    ///   - itemSelected: closure call back selected `T` generic object.
    ///   - configuration: Set up some advanced features for the tableView data source.
    public init(
        for tableView: UITableView,
        configCell: @escaping ConfigCell<T, CELL>,
        itemSelected: SELECTED_ITEM<T> = nil,
        configuration: Configuration = .default
    ) {
        self.tableView = tableView
        self.configCell = configCell
        loadMoreIndicator = DataSourceScrollViewConfiguration.LoadMoreActivityIndicator(scrollView: self.tableView)
        self.selectingItem = itemSelected
        self.configuration = configuration
        super.init()
        if #available(iOS 13, *), !TEST_OLD_VERSION {
            self.setUpDataSource(configCell: configCell)
        } else {
            self.tableView.dataSource = self
        }
        self.register(for: CELL.self)
        self.tableView.delegate = self
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0 // Remove the padding at the top for UITableView with a style different from plain.
        }
        tableView.contentInsetAdjustmentBehavior = .scrollableAxes // Prevent the padding at the top from increasing when pulling to refresh.
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 150, right: 0)
        
        // setup pull to refresh
        if configuration.havePullToRefresh {
            tableView.addSubview(refreshControl)
            tableView.sendSubviewToBack(refreshControl)
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
#if canImport(RxSwift)
        _scrollViewAction.onNext(.pullToRefresh)
#endif
    }
   
    public func updateItems(_ items: [T], to section: Int = 0) {
        if self.sections.isEmpty && !(self is TableSectionsDataSource) {
            self.sections = [SectionDataSourceModel(id: "", title: "", items: [])]
        }
        guard section < self.sections.count else {return}
        self.sections[section].updateItems(items)
        reloadData()
    }
    
    public func appendItems(items: [T], to section: Int = 0) {
        if self.sections.isEmpty && !(self is TableSectionsDataSource) {
            self.sections = [SectionDataSourceModel(id: "", title: "", items: [])]
        }
        guard section < self.sections.count else {return}
        self.sections[section].appendItems(items)
        reloadData()
    }
    
    public func updateSections(items: [SectionDataSourceModel<T>]) {
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
    
    func reloadData() {
        if self.sections.flatMap({ $0.items }).isEmpty && self.sections.filter({ $0._isExpand == false }).isEmpty {
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
                self.getDataSource().apply(snap)
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
#if canImport(RxSwift)
        _selectedItem.onNext(item)
#endif
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegating?(.didScroll(scrollView: scrollView))
        // in case this closure have not implemented then it shouldn't executed
        if configuration.haveLoadMore || self.scrollViewDelegating != nil {
            loadingMore {[weak self] in guard let self else { return }
                self.scrollViewDelegating?(.loadMore)
#if canImport(RxSwift)
                self._scrollViewAction.onNext(.loadMore)
#endif
            }
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegating?(.didEndDecelerating(scrollView: scrollView))
#if canImport(RxSwift)
        self._scrollViewAction.onNext(.didEndDecelerating(scrollView: scrollView))
#endif
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewDelegating?(.didEndDragging(scrollView: scrollView))
#if canImport(RxSwift)
        self._scrollViewAction.onNext(.didEndDragging(scrollView: scrollView))
#endif
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
        let cell = tableView.dequeue(CELL.self)
        configCell(item, indexPath, cell)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
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

private extension TableDataSource {
    
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
    
    func register(for cell: CELL.Type) {
        if CELL.isEqual(UITableViewCell.self) {
            self.tableView.register(cell.self, forCellReuseIdentifier: String(describing: cell.self))
        } else {
            self.tableView.register(cell)
        }
    }
}

@available(iOS 13,*)
public extension TableDataSource {
    
    func getDataSource() -> SwipableDataSource<T> {
        let ds =  self._dataSource as! SwipableDataSource<T>
        ds.defaultRowAnimation = .fade
        return ds
    }
    
    func setUpDataSource(configCell:@escaping ((_ item:T,_ indexPath: IndexPath, _ cell: CELL) ->Void?)) {
        self._dataSource = SwipableDataSource<T>(tableView: self.tableView, cellProvider: { tableView, indexPath, itemIdentifier in
            let cell = tableView.dequeue(CELL.self)
            configCell(itemIdentifier, indexPath, cell)
            return cell
        })
    }
}
