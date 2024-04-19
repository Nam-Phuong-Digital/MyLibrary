//
//  CollectionDataSource.swift
//  LearnRXSwift
//
//  Created by Dai Pham on 17/4/24.
//

import Foundation
import UIKit

/// An Object control a collection view datasource with T is Item and Cell is cell will be showed
public final class CollectionSectionsDataSource<
    T: Hashable,
    CELL: UICollectionViewCell,
    HEADER: UICollectionReusableView,
    FOOTER: UICollectionReusableView
>:  CollectionDataSource<T, CELL> {
    
    enum SupplementaryType {
        case header(HEADER?)
        case footer(FOOTER?)
    }
    
    private var configSupplementary:((_ section:SectionDataSourceModel<T>,_ indexPath: IndexPath,_ sup: SupplementaryType) ->Void)
    
    /// declare a datasource with have supplementary to collection view
    /// - Parameters:
    ///   - collectionView: collection view
    ///   - configCell: config  content for `CELL.self`
    ///   - configSupplementary: config content for supplementary kind
    ///   - layout: setup a layout to collection view
    init(
        for collectionView: UICollectionView,
        configCell:@escaping ((_ item:T,_ indexPath: IndexPath, _ cell: CELL) ->Void),
        configSupplementary:@escaping ((_ section:SectionDataSourceModel<T>,_ indexPath: IndexPath,_ sup: SupplementaryType) ->Void),
        itemSelected:((T) -> Void)? = nil,
        layout: UICollectionViewLayout? = nil
    ) {
        self.configSupplementary = configSupplementary
        super.init(for: collectionView, configCell: configCell, itemSelected: itemSelected, layout: layout)
        // If it's a UICollectionReusableView, don't register it, intended for cases where only the footer or header is desired.
        if !(HEADER.isEqual(UICollectionReusableView.self)) {
            self.register(for: HEADER.self, kind: UICollectionView.elementKindSectionHeader)
        }
        if !(FOOTER.isEqual(UICollectionReusableView.self)) {
            self.register(for: FOOTER.self, kind: UICollectionView.elementKindSectionFooter)
        }
        
        if #available(iOS 13, *), !TEST_OLD_VERSION {
            self.getDataSource().supplementaryViewProvider = {[weak self] collectionView, kind, indexPath in
                guard let self else { return nil}
                switch kind {
                case UICollectionView.elementKindSectionHeader:
                    let sup = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: HEADER.self), for: indexPath) as? HEADER
                    configSupplementary(self.sections[indexPath.section], indexPath, .header(sup))
                    return sup
                case UICollectionView.elementKindSectionFooter:
                    let sup = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: String(describing: FOOTER.self), for: indexPath) as? FOOTER
                    configSupplementary(self.sections[indexPath.section], indexPath, .footer(sup))
                    return sup
                default: return nil
                }
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            if let sup = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: HEADER.self), for: indexPath) as? HEADER {
                configSupplementary(self.sections[indexPath.section], indexPath, .header(sup))
                return sup
            }
        case UICollectionView.elementKindSectionFooter:
            if let sup = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: String(describing: FOOTER.self), for: indexPath) as? FOOTER {
                configSupplementary(self.sections[indexPath.section], indexPath, .footer(sup))
                return sup
            }
        default: return UICollectionReusableView(frame: .zero)
        }
        return UICollectionReusableView(frame: .zero)
    }
}

private extension CollectionSectionsDataSource {
    /// register cell
    /// - Parameter cell: type of cell
    func register(for cell:CELL.Type) {
        self.collectionView.register(UINib(nibName: String(describing: cell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: cell))
    }
    
    /// register supplementary for collection view
    /// - Parameters:
    ///   - sup: type registered
    ///   - kind:UICollectionView.elementKindSectionFooter or Header
    func register(for sup:UICollectionReusableView.Type, kind: String) {
        self.collectionView.register(UINib(nibName: String(describing: sup.self), bundle: nil), forSupplementaryViewOfKind: kind, withReuseIdentifier: String(describing: sup.self))
    }
}
