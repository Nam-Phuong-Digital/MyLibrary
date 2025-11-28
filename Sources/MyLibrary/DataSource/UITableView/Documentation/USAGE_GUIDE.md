# TableDynamicDataSource Usage Guide

## Overview

`TableDynamicDataSource` is a powerful, flexible wrapper around `UITableView` that simplifies data source management with RxSwift integration, automatic diffing, and a modern API.

## Quick Start

### Basic Usage (Simplest)

```swift
import MyLibrary
import RxSwift

// Create data source with single cell type
let dataSource = TableDynamicDataSource<MyModel>(
    tableView: tableView,
    cellType: MyCell.self,
    configure: { cell, item in
        cell.titleLabel.text = item.title
    }
)

// Bind data
viewModel.items
    .bind(to: dataSource.rx.items)
    .disposed(by: disposeBag)
```

### Using Builder Pattern (Recommended)

```swift
let dataSource = TableDataSourceBuilder<MyModel>(for: tableView)
    .cells(MyCell.self, AlternateCell.self)
    .configureCell(MyCell.self) { cell, item in
        cell.titleLabel.text = item.title
        cell.subtitleLabel.text = item.subtitle
    }
    .enablePullToRefresh()
    .enableLoadMore()
    .emptyStateText("No items found")
    .onItemSelected { item in
        print("Selected: \(item)")
    }
    .build()
```

### Using Factory Method

```swift
let dataSource = TableDynamicDataSource<MyModel>.builder(for: tableView)
    .cells(MyCell.self)
    .configure { item, indexPath, tableView in
        let cell = tableView.dequeue(MyCell.self)
        cell.configure(with: item)
        return cell
    }
    .enablePullToRefresh()
    .build()
```

## Configuration

### Empty State

```swift
// Simple text
.emptyStateText("No items to display")

// Custom configuration
.emptyState(
    EmptyStateConfiguration.Builder()
        .text("No items found")
        .image(UIImage(systemName: "tray"))
        .textColor(.gray)
        .font(.systemFont(ofSize: 18))
        .build()
)

// Custom view
let customView = MyEmptyStateView()
.emptyState(
    EmptyStateConfiguration(customView: customView)
)
```

### Pull-to-Refresh

```swift
let dataSource = builder
    .enablePullToRefresh(tintColor: .systemBlue)
    .build()

// Handle refresh events
dataSource.rx.pullToRefresh
    .flatMapLatest { viewModel.fetchItems() }
    .bind(to: dataSource.rx.items)
    .disposed(by: disposeBag)

// Stop refreshing
viewModel.finishedLoading
    .bind(to: dataSource.rx.stopPullRefresh)
    .disposed(by: disposeBag)
```

### Load More

```swift
let dataSource = builder
    .enableLoadMore()
    .build()

// Handle load more events
dataSource.rx.loadMore
    .flatMapLatest { viewModel.fetchMoreItems() }
    .bind(to: dataSource.rx.appendItems())
    .disposed(by: disposeBag)

// Stop loading
viewModel.finishedLoadingMore
    .bind(to: dataSource.rx.stopLoadMore)
    .disposed(by: disposeBag)
```

### Swipe Actions

```swift
let dataSource = builder
    .leadingSwipeActions { item, indexPath in
        let action = UIContextualAction(style: .normal, title: "Edit") { _, _, completion in
            // Handle edit
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
    .trailingSwipeActions { item, indexPath in
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            // Handle delete
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    .build()
```

## Reactive Bindings

### Data Binding

```swift
// Bind items to default section
viewModel.items
    .bind(to: dataSource.rx.items)
    .disposed(by: disposeBag)

// Bind items to specific section with animation
viewModel.items
    .bind(to: dataSource.rx.items(section: 0, animated: true))
    .disposed(by: disposeBag)

// Bind multiple sections
viewModel.sections
    .bind(to: dataSource.rx.sections)
    .disposed(by: disposeBag)

// Append items
viewModel.newItems
    .bind(to: dataSource.rx.appendItems(to: 0))
    .disposed(by: disposeBag)
```

### Event Observables

```swift
// Item selection
dataSource.rx.itemSelected
    .subscribe(onNext: { item in
        print("Selected: \(item)")
    })
    .disposed(by: disposeBag)

// Scroll events
dataSource.rx.didScroll
    .subscribe(onNext: { scrollView in
        print("Offset: \(scrollView.contentOffset)")
    })
    .disposed(by: disposeBag)

// Pull to refresh
dataSource.rx.pullToRefresh
    .subscribe(onNext: {
        // Handle refresh
    })
    .disposed(by: disposeBag)

// Load more
dataSource.rx.loadMore
    .subscribe(onNext: {
        // Handle load more
    })
    .disposed(by: disposeBag)
```

### Loading States

```swift
// Stop all loading
viewModel.finishedLoading
    .bind(to: dataSource.rx.stopLoading)
    .disposed(by: disposeBag)

// Stop specific loaders
viewModel.finishedRefreshing
    .bind(to: dataSource.rx.stopPullRefresh)
    .disposed(by: disposeBag)

viewModel.finishedLoadingMore
    .bind(to: dataSource.rx.stopLoadMore)
    .disposed(by: disposeBag)
```

## Advanced Usage

### Multiple Cell Types

```swift
let dataSource = builder
    .cells(TextCell.self, ImageCell.self, VideoCell.self)
    .configure { item, indexPath, tableView in
        switch item.type {
        case .text:
            let cell = tableView.dequeue(TextCell.self)
            cell.configure(with: item)
            return cell
        case .image:
            let cell = tableView.dequeue(ImageCell.self)
            cell.configure(with: item)
            return cell
        case .video:
            let cell = tableView.dequeue(VideoCell.self)
            cell.configure(with: item)
            return cell
        }
    }
    .build()
```

### Headers and Footers

```swift
let dataSource = TableDynamicDataSource<MyModel>(
    tableView: tableView,
    cellType: MyCell.self,
    headerType: MySectionHeader.self,
    configureCell: { cell, item in
        cell.configure(with: item)
    },
    configureHeader: { header, section, sectionIndex in
        header.titleLabel.text = section.title
    }
)
```

### Custom Cell Heights

```swift
let dataSource = builder
    .cellHeight { indexPath, tableView in
        return indexPath.row == 0 ? 100 : 60
    }
    .build()

// Or fixed height
let dataSource = builder
    .cellHeight(80)
    .build()
```

### Using Reactive Coordinator (NEW - Phase 2)

```swift
// Create coordinator for advanced reactive features
let coordinator = dataSource.createReactiveCoordinator()
// Or use the convenience method
let coordinator = dataSource.rxCoordinator()

// Use coordinator observables
coordinator.itemSelected
    .subscribe(onNext: { item in
        // Handle selection
    })
    .disposed(by: disposeBag)

coordinator.loadingState
    .subscribe(onNext: { state in
        switch state {
        case .idle:
            print("Not loading")
        case .refreshing:
            print("Refreshing...")
        case .loadingMore:
            print("Loading more...")
        case .loading:
            print("Loading...")
        }
    })
    .disposed(by: disposeBag)
```

### Enhanced Reactive Utilities (NEW - Phase 2)

#### Error Handling

```swift
// Bind with error handling
viewModel.fetchItems()
    .map { .success($0) }
    .catchAndReturn(.failure(NetworkError.unknown))
    .bind(to: dataSource.rx.itemsWithErrorHandling { error in
        print("Failed to load: \(error)")
        showErrorAlert(error)
    })
    .disposed(by: disposeBag)
```

#### Standard Refresh Pattern

```swift
// Simplified setup for common pull-to-refresh + load more pattern
dataSource.setupStandardRefreshPattern(
    refresh: viewModel.refresh(),
    loadMore: viewModel.loadMore(),
    disposeBag: disposeBag
)
```

#### Bind Helper

```swift
// All-in-one binding setup
dataSource.bind(
    items: viewModel.items,
    refresh: { viewModel.refresh() },
    loadMore: { viewModel.loadMore() },
    onSelect: { [weak self] item in
        self?.showDetail(for: item)
    },
    disposeBag: disposeBag
)
```

#### Driver Support

```swift
// Use Driver for main-thread guaranteed, never-error bindings
viewModel.itemsDriver
    .drive(dataSource.rx.itemsDriver)
    .disposed(by: disposeBag)

dataSource.rx.itemSelectedDriver
    .drive(onNext: { item in
        print("Selected: \(item)")
    })
    .disposed(by: disposeBag)
```

#### Debugging

```swift
// Monitor all data source events
dataSource.rx.debug(prefix: "MyList")
    .subscribe(onNext: { message in
        print(message)
    })
    .disposed(by: disposeBag)
```

## Complete Example

```swift
class ViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    private var dataSource: TableDynamicDataSource<Item>!
    private let viewModel = ViewModel()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        setupBindings()
    }

    private func setupDataSource() {
        dataSource = TableDataSourceBuilder<Item>(for: tableView)
            .cells(ItemCell.self)
            .configureCell(ItemCell.self) { cell, item in
                cell.titleLabel.text = item.title
                cell.imageView?.sd_setImage(with: item.imageURL)
            }
            .enablePullToRefresh(tintColor: .systemBlue)
            .enableLoadMore()
            .emptyStateText("No items found")
            .trailingSwipeActions { item, indexPath in
                let deleteAction = UIContextualAction(
                    style: .destructive,
                    title: "Delete"
                ) { [weak self] _, _, completion in
                    self?.viewModel.delete(item)
                    completion(true)
                }
                return UISwipeActionsConfiguration(actions: [deleteAction])
            }
            .build()
    }

    private func setupBindings() {
        // Bind data
        viewModel.items
            .bind(to: dataSource.rx.items)
            .disposed(by: disposeBag)

        // Handle pull to refresh
        dataSource.rx.pullToRefresh
            .flatMapLatest { [weak self] in
                self?.viewModel.refresh() ?? .empty()
            }
            .bind(to: dataSource.rx.stopPullRefresh)
            .disposed(by: disposeBag)

        // Handle load more
        dataSource.rx.loadMore
            .flatMapLatest { [weak self] in
                self?.viewModel.loadMore() ?? .empty()
            }
            .bind(to: dataSource.rx.stopLoadMore)
            .disposed(by: disposeBag)

        // Handle selection
        dataSource.rx.itemSelected
            .subscribe(onNext: { [weak self] item in
                self?.showDetail(for: item)
            })
            .disposed(by: disposeBag)
    }
}
```

## Migration from Old API

### Before
```swift
dataSource = TableDynamicDataSource(
    for: tableView,
    cellsType: [MyCell.self],
    sectionsType: [],
    configCell: { item, indexPath, tableView in
        let cell = tableView.dequeue(MyCell.self)
        cell.configure(with: item)
        return cell
    },
    configHeaderFooter: nil,
    itemSelected: { item in
        print("Selected: \(item)")
    },
    heightForCell: nil,
    configuration: .init(
        havePullToRefresh: true,
        textNoData: "No items"
    )
)
```

### After (Recommended)
```swift
dataSource = TableDataSourceBuilder<MyModel>(for: tableView)
    .cells(MyCell.self)
    .configureCell(MyCell.self) { cell, item in
        cell.configure(with: item)
    }
    .onItemSelected { item in
        print("Selected: \(item)")
    }
    .enablePullToRefresh()
    .emptyStateText("No items")
    .build()
```

## Best Practices

1. **Use Builder Pattern**: More readable and maintainable
2. **Leverage Reactive Bindings**: Cleaner code with RxSwift
3. **Type-Safe Cell Configuration**: Use `configureCell(_:with:)` for type safety
4. **Resource Management**: Always use `disposeBag` for subscriptions
5. **Empty States**: Always provide meaningful empty state messages
6. **Loading Indicators**: Use `stopLoading` to stop all loaders at once

## Performance Tips

1. Use `animated: false` for initial data load
2. Use `reloadItems` instead of full reload for partial updates
3. Implement proper cell reuse in configuration closures
4. Use `cellHeight(_:)` with fixed values when possible
5. Avoid heavy computations in cell configuration closures
