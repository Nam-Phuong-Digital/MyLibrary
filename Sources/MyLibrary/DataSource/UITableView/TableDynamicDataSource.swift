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
    
    func registerClass<T: UITableViewCell>(_ cellType: T.Type) {
        register(cellType.self, forCellReuseIdentifier: String(describing: cellType.self))
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
        if self.sections.isEmpty {
            self.showNoData()
        } else {
            self.hideNoData()
        }
        if #available(iOS 13, *), !TEST_OLD_VERSION {
            var snap = NSDiffableDataSourceSnapshot<Int, T>()
            let sectionIndex = self.sections.enumerated().map{$0.0}
            snap.appendSections(sectionIndex)
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

    /// Set the item selection handler
    public func setItemSelectionHandler(_ handler: SELECTED_ITEM<T>) {
        self.selectingItem = handler
    }

    /// Set the scroll view delegating handler
    public func setScrollViewDelegating(_ handler: ((DataSourceScrollViewConfiguration) -> Void)?) {
        self.scrollViewDelegating = handler
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

public  extension TableDynamicDataSource {
    
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
        let className = String(describing: cell)
        let bundle = Bundle(for: cell)

        if bundle.path(forResource: className, ofType: "nib") != nil {
            let nib = UINib(nibName: className, bundle: bundle)
            self.tableView.register(nib, forCellReuseIdentifier: className)
        } else {
            self.tableView.registerClass(cell)
        }
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

// MARK: - Reactive Extension for TableDynamicDataSource
public extension TableDynamicDataSource {

    /// Provides access to reactive extensions
    var rx: RxTableDynamicDataSourceExtension<T> {
        return RxTableDynamicDataSourceExtension(base: self)
    }
}

/// Reactive extensions for TableDynamicDataSource
public struct RxTableDynamicDataSourceExtension<T: Hashable> {
    internal let base: TableDynamicDataSource<T>

    fileprivate init(base: TableDynamicDataSource<T>) {
        self.base = base
    }

    /// Reactive binding for updating items in a single section
    /// - Usage:
    /// ```swift
    /// viewModel.items
    ///     .bind(to: dataSource.rx.items)
    ///     .disposed(by: disposeBag)
    /// ```
    public var items: Binder<[T]> {
        return Binder(base) { dataSource, items in
            dataSource.updateItems(items, to: 0, animated: true)
        }
    }

    /// Reactive binding for updating items in a specific section with animation control
    /// - Usage:
    /// ```swift
    /// viewModel.items
    ///     .bind(to: dataSource.rx.items(section: 0, animated: true))
    ///     .disposed(by: disposeBag)
    /// ```
    public func items(section: Int = 0, animated: Bool = true) -> Binder<[T]> {
        return Binder(base) { dataSource, items in
            dataSource.updateItems(items, to: section, animated: animated)
        }
    }

    /// Reactive binding for updating multiple sections
    /// - Usage:
    /// ```swift
    /// viewModel.sections
    ///     .bind(to: dataSource.rx.sections)
    ///     .disposed(by: disposeBag)
    /// ```
    public var sections: Binder<[SectionDataSourceModel<T>]> {
        return Binder(base) { dataSource, sections in
            dataSource.updateSections(items: sections)
        }
    }

    /// Reactive binding for appending items to a section
    /// - Usage:
    /// ```swift
    /// viewModel.newItems
    ///     .bind(to: dataSource.rx.appendItems(to: 0))
    ///     .disposed(by: disposeBag)
    /// ```
    public func appendItems(to section: Int = 0) -> Binder<[T]> {
        return Binder(base) { dataSource, items in
            dataSource.appendItems(items: items, to: section)
        }
    }

    /// Reactive binding for appending sections
    /// - Usage:
    /// ```swift
    /// viewModel.newSections
    ///     .bind(to: dataSource.rx.appendSections)
    ///     .disposed(by: disposeBag)
    /// ```
    public var appendSections: Binder<[SectionDataSourceModel<T>]> {
        return Binder(base) { dataSource, sections in
            dataSource.appendSections(items: sections)
        }
    }

    /// Reactive binding for stopping pull to refresh control
    /// - Usage:
    /// ```swift
    /// viewModel.finishedLoading
    ///     .bind(to: dataSource.rx.stopPullRefresh)
    ///     .disposed(by: disposeBag)
    /// ```
    public var stopPullRefresh: Binder<Void> {
        return Binder(base) { dataSource, _ in
            dataSource.finishPullToRefresh()
        }
    }

    /// Reactive binding for stopping load more indicator
    /// - Usage:
    /// ```swift
    /// viewModel.finishedLoadingMore
    ///     .bind(to: dataSource.rx.stopLoadMore)
    ///     .disposed(by: disposeBag)
    /// ```
    public var stopLoadMore: Binder<Void> {
        return Binder(base) { dataSource, _ in
            dataSource.finishLoadMore()
        }
    }

    /// Reactive binding for stopping both pull refresh and load more
    /// - Usage:
    /// ```swift
    /// viewModel.finishedLoading
    ///     .bind(to: dataSource.rx.stopLoading)
    ///     .disposed(by: disposeBag)
    /// ```
    public var stopLoading: Binder<Void> {
        return Binder(base) { dataSource, _ in
            dataSource.finishPullToRefresh()
            dataSource.finishLoadMore()
        }
    }

    /// Reactive binding for reloading specific items
    /// - Usage:
    /// ```swift
    /// viewModel.updatedItems
    ///     .bind(to: dataSource.rx.reloadItems(animated: true))
    ///     .disposed(by: disposeBag)
    /// ```
    public func reloadItems(animated: Bool = true) -> Binder<[T]> {
        return Binder(base) { dataSource, items in
            dataSource.reloadItems(items, animated: animated)
        }
    }

    /// Reactive binding for reloading specific sections
    /// - Usage:
    /// ```swift
    /// Observable.just([0, 1])
    ///     .bind(to: dataSource.rx.reloadSections(animated: true))
    ///     .disposed(by: disposeBag)
    /// ```
    public func reloadSections(animated: Bool = true) -> Binder<[Int]> {
        return Binder(base) { dataSource, sections in
            dataSource.reloadSections(sections, animated: animated)
        }
    }

    /// Reactive binding for removing items
    /// - Usage:
    /// ```swift
    /// viewModel.itemsToRemove
    ///     .bind(to: dataSource.rx.removeItems)
    ///     .disposed(by: disposeBag)
    /// ```
    public var removeItems: Binder<[T]> {
        return Binder(base) { dataSource, items in
            dataSource.removeItems(items: items)
        }
    }

    /// Reactive binding for removing sections
    /// - Usage:
    /// ```swift
    /// viewModel.sectionsToRemove
    ///     .bind(to: dataSource.rx.removeSections)
    ///     .disposed(by: disposeBag)
    /// ```
    public var removeSections: Binder<[SectionDataSourceModel<T>]> {
        return Binder(base) { dataSource, sections in
            dataSource.removeSections(sections)
        }
    }

    /// Observable for item selection events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.itemSelected
    ///     .subscribe(onNext: { item in
    ///         print("Selected item: \(item)")
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    public var itemSelected: Observable<T> {
        let subject = PublishSubject<T>()
        base.setItemSelectionHandler { item in
            subject.onNext(item)
        }
        return subject.asObservable()
    }

    /// Observable for pull to refresh events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.pullToRefresh
    ///     .flatMapLatest { viewModel.fetchItems() }
    ///     .bind(to: dataSource.rx.items)
    ///     .disposed(by: disposeBag)
    /// ```
    public var pullToRefresh: Observable<Void> {
        return scrollViewDelegating
            .compactMap { config in
                if case .pullToRefresh = config {
                    return ()
                }
                return nil
            }
    }

    /// Observable for load more events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.loadMore
    ///     .flatMapLatest { viewModel.fetchMoreItems() }
    ///     .bind(to: dataSource.rx.appendItems())
    ///     .disposed(by: disposeBag)
    /// ```
    public var loadMore: Observable<Void> {
        return scrollViewDelegating
            .compactMap { config in
                if case .loadMore = config {
                    return ()
                }
                return nil
            }
    }

    /// Observable for scroll events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.didScroll
    ///     .subscribe(onNext: { scrollView in
    ///         print("Content offset: \(scrollView.contentOffset)")
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    public var didScroll: Observable<UIScrollView> {
        return scrollViewDelegating
            .compactMap { config in
                if case .didScroll(let scrollView) = config {
                    return scrollView
                }
                return nil
            }
    }

    /// Observable for all scroll view delegating events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.scrollViewDelegating
    ///     .subscribe(onNext: { config in
    ///         switch config {
    ///         case .pullToRefresh:
    ///             print("Pull to refresh triggered")
    ///         case .loadMore:
    ///             print("Load more triggered")
    ///         case .didScroll(let scrollView):
    ///             print("Scrolling at offset: \(scrollView.contentOffset)")
    ///         case .didEndDecelerating(let scrollView):
    ///             print("Ended decelerating")
    ///         case .didEndDragging(let scrollView):
    ///             print("Ended dragging")
    ///         case .willDisplayHeader(let section, let view):
    ///             print("Will display header for section \(section)")
    ///         case .willDisplayFooter(let section, let view):
    ///             print("Will display footer for section \(section)")
    ///         case .didEndDisplayHeader(let section, let view):
    ///             print("Did end display header for section \(section)")
    ///         case .didEndDisplayFooter(let section, let view):
    ///             print("Did end display footer for section \(section)")
    ///         case .shoudLoadMore(let closure):
    ///             // Check if should load more
    ///             let shouldLoad = true
    ///             closure(shouldLoad)
    ///         }
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    public var scrollViewDelegating: Observable<DataSourceScrollViewConfiguration> {
        return Observable.create { [weak base] observer in
            guard let base = base else {
                observer.onCompleted()
                return Disposables.create()
            }

            base.setScrollViewDelegating { config in
                observer.onNext(config)
            }

            return Disposables.create()
        }
    }

    /// Observable for scroll view did end decelerating events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.didEndDecelerating
    ///     .subscribe(onNext: { scrollView in
    ///         print("Scroll ended at: \(scrollView.contentOffset)")
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    public var didEndDecelerating: Observable<UIScrollView> {
        return scrollViewDelegating
            .compactMap { config in
                if case .didEndDecelerating(let scrollView) = config {
                    return scrollView
                }
                return nil
            }
    }

    /// Observable for scroll view did end dragging events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.didEndDragging
    ///     .subscribe(onNext: { scrollView in
    ///         print("Dragging ended")
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    public var didEndDragging: Observable<UIScrollView> {
        return scrollViewDelegating
            .compactMap { config in
                if case .didEndDragging(let scrollView) = config {
                    return scrollView
                }
                return nil
            }
    }

    /// Observable for will display header events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.willDisplayHeader
    ///     .subscribe(onNext: { (section, view) in
    ///         print("Will display header for section: \(section)")
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    public var willDisplayHeader: Observable<(section: Int, view: UIView)> {
        return scrollViewDelegating
            .compactMap { config in
                if case .willDisplayHeader(let section, let view) = config {
                    return (section, view)
                }
                return nil
            }
    }

    /// Observable for will display footer events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.willDisplayFooter
    ///     .subscribe(onNext: { (section, view) in
    ///         print("Will display footer for section: \(section)")
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    public var willDisplayFooter: Observable<(section: Int, view: UIView)> {
        return scrollViewDelegating
            .compactMap { config in
                if case .willDisplayFooter(let section, let view) = config {
                    return (section, view)
                }
                return nil
            }
    }

    /// Observable for did end display header events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.didEndDisplayHeader
    ///     .subscribe(onNext: { (section, view) in
    ///         print("Did end display header for section: \(section)")
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    public var didEndDisplayHeader: Observable<(section: Int, view: UIView)> {
        return scrollViewDelegating
            .compactMap { config in
                if case .didEndDisplayHeader(let section, let view) = config {
                    return (section, view)
                }
                return nil
            }
    }

    /// Observable for did end display footer events
    /// - Usage:
    /// ```swift
    /// dataSource.rx.didEndDisplayFooter
    ///     .subscribe(onNext: { (section, view) in
    ///         print("Did end display footer for section: \(section)")
    ///     })
    ///     .disposed(by: disposeBag)
    /// ```
    public var didEndDisplayFooter: Observable<(section: Int, view: UIView)> {
        return scrollViewDelegating
            .compactMap { config in
                if case .didEndDisplayFooter(let section, let view) = config {
                    return (section, view)
                }
                return nil
            }
    }

    /// Binder for setting scroll view delegating closure
    /// - Usage:
    /// ```swift
    /// let delegatingClosure: (DataSourceScrollViewConfiguration) -> Void = { config in
    ///     // Handle scroll view events
    /// }
    /// Observable.just(delegatingClosure)
    ///     .bind(to: dataSource.rx.setScrollViewDelegating)
    ///     .disposed(by: disposeBag)
    /// ```
    public var setScrollViewDelegatingHandler: Binder<((DataSourceScrollViewConfiguration) -> Void)?> {
        return Binder(base) { dataSource, delegating in
            dataSource.setScrollViewDelegating(delegating)
        }
    }
}
