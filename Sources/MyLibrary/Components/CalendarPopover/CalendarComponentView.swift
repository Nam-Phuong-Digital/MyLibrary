//
//  CalendarComponentView.swift
//  Cabinbook
//
//  Created by Dai Pham on 16/10/2023.
//  Copyright © 2023 Nam Phuong Digital. All rights reserved.
//

import UIKit
import Algorithms

public class CalendarComponentIcon {
    public var icon:UIImage?
    public var bgIcon:UIColor?
}

public protocol CalendarComponentViewDelegate: AnyObject {
    func CalendarComponentView_getIcon(for date:Date) -> CalendarComponentIcon?
    func CalendarComponentView_allMonths(_ months:[CEVMonth])
    func CalendarComponentView_rangeMonths() -> RangeMonth?
    
    func CalendarComponentView_stateForNext(isDisabled:Bool)
    func CalendarComponentView_stateForPrevious(isDisabled:Bool)
}

public extension CalendarComponentViewDelegate {
    func CalendarComponentView_getIcon(for date:Date) -> CalendarComponentIcon? {
        nil
    }
    func CalendarComponentView_allMonths(_ months:[CEVMonth]) {}
    func CalendarComponentView_rangeMonths() -> RangeMonth? {nil}
    func CalendarComponentView_stateForNext(isDisabled:Bool){}
    func CalendarComponentView_stateForPrevious(isDisabled:Bool){}
}

fileprivate let EXPAND_HEIGHT = 320.0
fileprivate let COLLAPSE_HEIGHT = 50.0

public class CalendarComponentView: UIView {

    required init?(coder aDecoder: NSCoder) {   // 2 - storyboard initializer
        super.init(coder: aDecoder)
        fromNib(isModule: true)   // 5.
    }
    public init() {   // 3 - programmatic initializer
        super.init(frame: CGRect.zero)  // 4.
        fromNib(isModule: true)  // 6.
        config()
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        config()
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tabMonths: ButtonScrollTabView!
    @IBOutlet weak var vwMonth: UIView!
    @IBOutlet weak var heightCollectionView: NSLayoutConstraint!
    
    private var currentWeek:Int = 0
    
    private var _dataSource:Any?
    private var menuMonths:[CEVMonth] = [] {
        didSet {
            tabMonths.setButtons(
                titles: menuMonths.compactMap({
                    .init(
                        title: $0.date.toMonthCalendar(isLongName:true),
                        identifier: $0.date.toStringOriginal,
                        isSelected: false
                    )
                })
            )
            tabMonths.selectIndex = menuMonths.firstIndex(where: {$0.isEqual(Date())}) ?? 0
        }
    }
    
    var currentMonth:CEVMonth = .init(date: Date(), days: []) {
        didSet {
            self.currentWeek = 0
            self.selectionIndexpath = nil
            if #unavailable(iOS 13) {
                collectionView.reloadData()
            }
            self.onChangeMonth?(currentMonth.date)
        }
    }
    
    var selectionDate:CEVDate?

    weak var delegate:CalendarComponentViewDelegate? {
        didSet {
            self.delegate?.CalendarComponentView_allMonths(menuMonths)
            getDatesForMonths()
        }
    }
    
    private var selectionIndexpath:IndexPath?
    var onChangeDate:((Date?)->Void)?
    var onChangeMonth:((Date?)->Void)?
    
    private var icons:[String:UIImage?] = [:]
    
    public func config() {
        
        vwMonth.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.bounces = false
        collectionView.alwaysBounceHorizontal = false
        collectionView.alwaysBounceVertical = false
        if #available(iOS 13.0, *) {
            collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        
        tabMonths.contentInset = UIEdgeInsets(top: 0, left: tabMonths.frame.width/2, bottom: 0, right: tabMonths.frame.width/2)
        tabMonths.setBackground(color: .clear)
        tabMonths.delegate = self
        
        if #available(iOS 13, *) {
            self.collectionView.collectionViewLayout = UICollectionViewLayout.createLayout(columns: 7)
        } else {
            self.collectionView.collectionViewLayout = CalendarFlowLayout()
        }
        
        self.collectionView.delegate = self
        
        // Register cell classes
        self.collectionView.isPagingEnabled = true
        self.collectionView.register(DayComponentCell.nib(bundle: .module), forCellWithReuseIdentifier: DayComponentCell.identifier)

        if #available(iOS 13, *) {
            dataSource = UICollectionViewDiffableDataSource<Int, AnyHashable>(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DayComponentCell.identifier, for: indexPath) as! DayComponentCell
                let item = itemIdentifier as! CEVDate
                let type = self.delegate?.CalendarComponentView_getIcon(for: item.date)
                cell.show(
                    config: .init(
                        day: item.text, 
                        iconTask: type?.icon,
                        bgIcon:type?.bgIcon,
                        isHighligted: item.isEqual(Date()),
                        isSelected: item.isEqual(self.selectionDate?.date),
                        isBold: item.isBelongCurrentMonth
                    )
                )
                return cell
            })
        } else {
            self.collectionView.dataSource = self
        }
        
//        getDatesForMonths()
    }
    
    func setCurrentDay(date:Date = Date()) {
        if let current = self.menuMonths.first(where: {$0.isEqual(date)}) {
            if let date = current.days.first(where: {$0.isEqual(date)}) {
                self.selectionDate = date
                DispatchQueue.main.async {
                    if #available(iOS 13, *) {
                        self.updateDataSource()
                    } else {
                        self.collectionView.reloadData()
                    }
                }
            }
            setCurrentMonth(month: current)
        }
    }
    
    func setCurrentMonth(month:CEVMonth) {
        currentMonth = month
        if let index = menuMonths.firstIndex(of: currentMonth) {
            self.delegate?.CalendarComponentView_stateForNext(isDisabled: !(index < menuMonths.count - 1))
            self.delegate?.CalendarComponentView_stateForPrevious(isDisabled: !(index > 0))
        }
        if let index = menuMonths.firstIndex(where: {$0.isEqual(month.date)}) {
            tabMonths.setSelectIndex(index: index)
            guard index < tabMonths.buttonTabs.count else {return}
            self.selectTab(identifier: tabMonths.buttonTabs[index].identifider, buttonTab: nil)
        }
    }
    
    func showMonth() {
        UIView.transition(with: vwMonth, duration: 0.3) {[weak self] in guard let self = self else { return }
            self.tabMonths.isHidden.toggle()
        }
        
        if !self.tabMonths.isHidden {
            self.tabMonths.scrollToSelectIndex()
        }
    }
    
    func reloadIcons() {
        DispatchQueue.main.async {
            if #available(iOS 13, *) {
                if let sections = self.dataSource?.snapshot().numberOfSections {
                    self.reload(sections: Array(0..<sections))
                }
            } else {
                self.collectionView.reloadData()
            }
        }
    }
    
    @MainActor
    private func updateDataSource() {
        if #available(iOS 13, *) {
            self.updateDataSoure {[unowned self] in
                var snap = NSDiffableDataSourceSnapshot<Int, AnyHashable>()
                snap.appendSections(self.menuMonths.enumerated().compactMap({$0.offset}))
                self.menuMonths.enumerated().forEach { e in
                    snap.appendItems(e.element.days, toSection: e.offset)
                }
                return snap
            }
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.1, execute: {[weak self] in guard let self = self else { return }
                self.collectionView.scrollToItem(at: IndexPath(item: 0, section: self.tabMonths.selectIndex), at: .left, animated: false)
            })
        }
    }
    
    private func getDatesForMonths() {
        var temp = [CEVMonth]()
        let range = self.delegate?.CalendarComponentView_rangeMonths() ?? DefaultRangeMonth()
        for month in Date().getTaskMonths(range: range) {
            let result = loadWeekDates(from: month)
            temp.append(.init(date: month, days: result))
        }
        menuMonths = temp
        if let first = menuMonths.first(where: {$0.isEqual(Date())}) {
            currentMonth = first
        }
        DispatchQueue.main.async {
            if #available(iOS 13, *) {
                self.updateDataSource()
            } else {
                self.collectionView.reloadData()
            }
        }
    }
    
    public func loadWeekDates(from:Date) -> [CEVDate] {
        let list = from.getAllDays()
        let listWeekDaysOfMonth = list.compactMap({($0.weekDay(),$0)})
            .chunked(by: {$0.1.weekMonth() == $1.1.weekMonth()})
        var rowWeekDates:[[CEVDate]] = []
        listWeekDaysOfMonth.forEach { listWeekDays in
            let t = Array(listWeekDays)
            var rowWeekDate:[CEVDate] = []
            if let first = t.first {
                var firstWeekDay = first.0
                if firstWeekDay == 1 { // sunday
                    firstWeekDay = 8
                }
                if firstWeekDay > 2 {
                    var j = firstWeekDay - 2
                    for _ in 2..<firstWeekDay {
                        let date = first.1.addingTimeInterval(TimeInterval(-j*84600))
                        rowWeekDate.append(CEVDate(text: date.toString(format: "dd"), date: date, isBelongCurrentMonth: false))
                        j -= 1
                    }
                }
            }
            rowWeekDate.append(contentsOf:t.compactMap({CEVDate(text: $0.1.toString(format: "dd"), date: $0.1)}))
            if let v = t.last {
                var lastWeekDay = v.0
                if lastWeekDay != 1 {
                    lastWeekDay += 1
                    var j = 2
                    for _ in lastWeekDay...8 {
                        let date = v.1.addingTimeInterval(TimeInterval(j*84600))
                        rowWeekDate.append(CEVDate(text: date.toString(format: "dd"), date: date, isBelongCurrentMonth: false))
                        j += 1
                    }
                }
            }
            
            rowWeekDates.append(rowWeekDate)
        }
        return rowWeekDates.flatMap({$0})
    }
    
    @objc func selectorBack(_ sender: UIBarButtonItem) {
        if let index = self.menuMonths.firstIndex(of: currentMonth) {
            let target = index - 1
            if target >= 0 {
                setCurrentMonth(month: self.menuMonths[target])
            }
        }
    }
    @objc func selectorToday(_ sender: Any) {
        let date = Date()
        if let current = self.menuMonths.first(where: {$0.isEqual(date)}) {
            if let _ = current.days.first(where: {$0.isEqual(date)}) {
                if #available(iOS 13, *) {
                    updateDataSource()
                } else {
                    self.collectionView.reloadData()
                }
                
            }
            setCurrentMonth(month: current)
        }
    }
    @objc func selectorNext(_ sender: UIBarButtonItem) {
        if let index = self.menuMonths.firstIndex(of: currentMonth) {
            let target = index + 1
            if target < self.menuMonths.count {
                setCurrentMonth(month: self.menuMonths[target])
            }
        }
    }
}

extension CalendarComponentView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if #available(iOS 13.0, *) {
            var needreload:[CEVDate] = []
            if let selectionDate {
                needreload.append(selectionDate)
            }
            let item:CEVDate = self.dataSource?.itemIdentifier(for: indexPath) as! CEVDate
            guard !item.disabled else {
                self.onChangeDate?(nil)
                return
            }
            self.onChangeDate?(item.date)
            self.selectionDate = item
            if !item.isEqual(selectionDate?.date) {
                needreload.append(item)
                self.reload(rows: needreload)
            }
            
        } else {
            guard indexPath.section < menuMonths.count else {return}
            var reload = [IndexPath]()
            if let selectionIndexpath {
                reload.append(selectionIndexpath)
            }
            let item = currentMonth.days[indexPath.row]
            guard !item.disabled else {
                self.onChangeDate?(nil)
                return
            }
            self.onChangeDate?(item.date)
            if !item.isEqual(selectionDate?.date) {
                selectionIndexpath = indexPath
                reload.append(indexPath)
            }
            UIView.performWithoutAnimation {
                self.collectionView.reloadItems(at: reload)
            }
        }
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section < menuMonths.count else {return 0}
        let temp = currentMonth.days.chunks(ofCount: 7).filter({
            $0.filter({$0.shouldHidden}).count != 7
        })
        currentMonth.days = temp.flatMap({$0})
        return currentMonth.days.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DayComponentCell.identifier, for: indexPath) as! DayComponentCell
        let item = currentMonth.days[indexPath.row]
        let type = self.delegate?.CalendarComponentView_getIcon(for: item.date)
        cell.show(
            config: .init(
                day: item.text,
                iconTask: type?.icon,
                bgIcon: type?.bgIcon,
                isHighligted: item.isEqual(Date()),
                isSelected: item.isEqual(self.selectionDate?.date),
                isBold: item.isBelongCurrentMonth
            )
        )
        return cell
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.isEqual(self.collectionView) {
            var index = Int(scrollView.contentOffset.x/scrollView.frame.width)
            if index >= menuMonths.count {
                index = menuMonths.count - 1
            }
            if index < 0  {
                index = 0
            }
            tabMonths.selectIndex = index
            currentMonth = menuMonths[index]
            if let index = menuMonths.firstIndex(of: currentMonth) {
                self.delegate?.CalendarComponentView_stateForNext(isDisabled: !(index < menuMonths.count - 1))
                self.delegate?.CalendarComponentView_stateForPrevious(isDisabled: !(index > 0))
            }
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate, scrollView.isEqual(self.collectionView) {
            var index = Int(scrollView.contentOffset.x/scrollView.frame.width)
            if index >= menuMonths.count {
                index = menuMonths.count - 1
            }
            if index < 0  {
                index = 0
            }
            tabMonths.selectIndex = index
            currentMonth = menuMonths[index]
            if let index = menuMonths.firstIndex(of: currentMonth) {
                self.delegate?.CalendarComponentView_stateForNext(isDisabled: !(index < menuMonths.count - 1))
                self.delegate?.CalendarComponentView_stateForPrevious(isDisabled: !(index > 0))
            }
        }
    }
}

extension CalendarComponentView: ButtonScrollTabViewDelegate {
    public func selectTab(identifier: String?, buttonTab: ButtonTab?) {
        if let identifier,
           let index = menuMonths.firstIndex(where: {
               $0.date.toStringOriginal == identifier
           }) {
            
            if #available(iOS 13,*), index < dataSource?.snapshot().numberOfSections ?? 0 {
                collectionView.scrollToItem(at: IndexPath(item: 0, section: index), at: .left, animated: true)
            }
            currentMonth = menuMonths[index]
            if let index = menuMonths.firstIndex(of: currentMonth) {
                self.delegate?.CalendarComponentView_stateForNext(isDisabled: !(index < menuMonths.count - 1))
                self.delegate?.CalendarComponentView_stateForPrevious(isDisabled: !(index > 0))
            }
        }
    }
}

@available (iOS 13,*)
private extension CalendarComponentView {
    var dataSource: UICollectionViewDiffableDataSource<Int,AnyHashable>? {
        get {return _dataSource as? UICollectionViewDiffableDataSource<Int,AnyHashable>}
        set {_dataSource = newValue}
    }
    
    func getItem<T:Codable>(_ indexPath:IndexPath) -> T? {
        return dataSource?.itemIdentifier(for:indexPath) as? T
    }
    
    func getItem<T:Hashable>(_ indexPath:IndexPath) -> T? {
        return dataSource?.itemIdentifier(for:indexPath) as? T
    }
    
    func getItem(_ indexPath:IndexPath) -> AnyHashable? {
        return dataSource?.itemIdentifier(for: indexPath)
    }
    
    func updateDataSoure(items:[AnyHashable], section:Int) {
        guard let dataSourceCollection = dataSource else {return}
        var snapShot = NSDiffableDataSourceSnapshot<Int,AnyHashable>()
        snapShot.appendSections([section])
        snapShot.appendItems(items)
        dataSourceCollection.apply(snapShot, animatingDifferences: false)
    }

    func updateDataSoure(with snapShot:@escaping ()->NSDiffableDataSourceSnapshot<Int,AnyHashable>) {
        guard let dataSourceCollection = dataSource else {return}
        dataSourceCollection.apply(snapShot(), animatingDifferences: false)
    }
    
    func reload(rows:[AnyHashable]) {
        var snap = dataSource?.snapshot()
        snap?.reloadItems(rows)
        if let snap = snap {
            dataSource?.apply(snap, animatingDifferences: false)
        }
    }
    
    func reload(sections:[Int]) {
        var snap = dataSource?.snapshot()
        snap?.reloadSections(sections)
        if let snap = snap {
            dataSource?.apply(snap, animatingDifferences: false)
        }
    }
}
