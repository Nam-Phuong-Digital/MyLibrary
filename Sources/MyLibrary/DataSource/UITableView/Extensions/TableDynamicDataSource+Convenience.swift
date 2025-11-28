//
//  TableDynamicDataSource+Convenience.swift
//  MyLibrary
//
//  Created by Claude Code
//

import UIKit

// MARK: - Convenience Initializers

public extension TableDynamicDataSource {

    /// Simple initializer for single cell type
    /// - Parameters:
    ///   - tableView: The table view to configure
    ///   - cellType: The cell type to use
    ///   - configure: Closure to configure the cell with an item
    convenience init(
        tableView: UITableView,
        cellType: UITableViewCell.Type,
        configure: @escaping (UITableViewCell, T) -> Void
    ) {
        self.init(
            for: tableView,
            cellsType: [cellType],
            sectionsType: [],
            configCell: { item, indexPath, tableView in
                let cell = tableView.dequeue(cellType)
                configure(cell, item)
                return cell
            },
            configHeaderFooter: nil,
            itemSelected: nil,
            heightForCell: nil,
            configuration: .default
        )
    }

    /// Initializer with typed cell configuration
    /// - Parameters:
    ///   - tableView: The table view to configure
    ///   - cellType: The specific cell type to use
    ///   - configure: Strongly-typed configuration closure
    convenience init<Cell: UITableViewCell>(
        tableView: UITableView,
        cellType: Cell.Type,
        configure: @escaping (Cell, T, IndexPath) -> Void
    ) {
        self.init(
            for: tableView,
            cellsType: [cellType],
            sectionsType: [],
            configCell: { item, indexPath, tableView in
                let cell = tableView.dequeue(cellType)
                configure(cell, item, indexPath)
                return cell
            },
            configHeaderFooter: nil,
            itemSelected: nil,
            heightForCell: nil,
            configuration: .default
        )
    }

    /// Initializer with cell type and selection handler
    /// - Parameters:
    ///   - tableView: The table view to configure
    ///   - cellType: The cell type to use
    ///   - configure: Closure to configure the cell
    ///   - onSelect: Handler for item selection
    convenience init(
        tableView: UITableView,
        cellType: UITableViewCell.Type,
        configure: @escaping (UITableViewCell, T) -> Void,
        onSelect: @escaping (T) -> Void
    ) {
        self.init(
            for: tableView,
            cellsType: [cellType],
            sectionsType: [],
            configCell: { item, indexPath, tableView in
                let cell = tableView.dequeue(cellType)
                configure(cell, item)
                return cell
            },
            configHeaderFooter: nil,
            itemSelected: onSelect,
            heightForCell: nil,
            configuration: .default
        )
    }

    /// Initializer with pull-to-refresh enabled
    /// - Parameters:
    ///   - tableView: The table view to configure
    ///   - cellType: The cell type to use
    ///   - configure: Closure to configure the cell
    ///   - emptyText: Text to show when there are no items
    convenience init(
        tableView: UITableView,
        cellType: UITableViewCell.Type,
        configure: @escaping (UITableViewCell, T) -> Void,
        emptyText: String = "No items to display"
    ) {
        self.init(
            for: tableView,
            cellsType: [cellType],
            sectionsType: [],
            configCell: { item, indexPath, tableView in
                let cell = tableView.dequeue(cellType)
                configure(cell, item)
                return cell
            },
            configHeaderFooter: nil,
            itemSelected: nil,
            heightForCell: nil,
            configuration: Configuration(
                havePullToRefresh: false,
                textNoData: emptyText
            )
        )
    }

    /// Initializer with cell and header configuration
    /// - Parameters:
    ///   - tableView: The table view to configure
    ///   - cellType: The cell type to use
    ///   - headerType: The header view type to use
    ///   - configureCell: Closure to configure cells
    ///   - configureHeader: Closure to configure headers
    convenience init<Header: UITableViewHeaderFooterView>(
        tableView: UITableView,
        cellType: UITableViewCell.Type,
        headerType: Header.Type,
        configureCell: @escaping (UITableViewCell, T) -> Void,
        configureHeader: @escaping (Header, SectionDataSourceModel<T>, Int) -> Void
    ) {
        self.init(
            for: tableView,
            cellsType: [cellType],
            sectionsType: [headerType],
            configCell: { item, indexPath, tableView in
                let cell = tableView.dequeue(cellType)
                configureCell(cell, item)
                return cell
            },
            configHeaderFooter: { sectionModel, section, tableView, kind in
                guard case .header = kind else { return nil }
                let header = tableView.dequeue(headerType)
                if let header = header {
                    configureHeader(header, sectionModel, section)
                }
                return header
            },
            itemSelected: nil,
            heightForCell: nil,
            configuration: .default
        )
    }
}

// MARK: - Factory Methods

public extension TableDynamicDataSource {

    /// Create a basic data source with minimal configuration
    /// - Parameters:
    ///   - tableView: The table view
    ///   - cellType: Cell type
    ///   - configure: Cell configuration closure
    /// - Returns: Configured data source
    static func create(
        for tableView: UITableView,
        cellType: UITableViewCell.Type,
        configure: @escaping (UITableViewCell, T) -> Void
    ) -> TableDynamicDataSource<T> {
        return TableDynamicDataSource(
            tableView: tableView,
            cellType: cellType,
            configure: configure
        )
    }

    /// Create a data source with selection handling
    /// - Parameters:
    ///   - tableView: The table view
    ///   - cellType: Cell type
    ///   - configure: Cell configuration closure
    ///   - onSelect: Selection handler
    /// - Returns: Configured data source
    static func create(
        for tableView: UITableView,
        cellType: UITableViewCell.Type,
        configure: @escaping (UITableViewCell, T) -> Void,
        onSelect: @escaping (T) -> Void
    ) -> TableDynamicDataSource<T> {
        return TableDynamicDataSource(
            tableView: tableView,
            cellType: cellType,
            configure: configure,
            onSelect: onSelect
        )
    }
}
