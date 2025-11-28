# TableDynamicDataSource Quick Reference

## Choose Your API Level

### Level 1: Ultra-Simple (Recommended for most cases)

```swift
// 🚀 One-line setup with view model
let dataSource = tableView.setupWithViewModel(
    cellType: MyCell.self,
    viewModel: myViewModel,
    configure: { $0.configure(with: $1) },
    disposeBag: disposeBag
)
```

### Level 2: Presets (Common scenarios)

```swift
// 📋 Simple static list
let dataSource = tableView.setupSimpleList(
    cellType: MyCell.self,
    configure: { cell, item in cell.configure(with: item) }
)

// 🔄 List with pull-to-refresh + load more
let dataSource = tableView.setupPaginatedList(
    cellType: MyCell.self,
    configure: { cell, item in cell.configure(with: item) }
)

// 🔍 Search results
let dataSource = DataSourcePreset.searchResultsList(
    tableView: tableView,
    cellType: MyCell.self,
    configure: { $0.configure(with: $1) },
    onSelect: { item in showDetail(item) }
)

// 📱 Social feed
let dataSource = DataSourcePreset.feedList(
    tableView: tableView,
    cellType: PostCell.self,
    configure: { $0.configure(with: $1) }
)
```

### Level 3: Builder (Custom configuration)

```swift
// 🔧 Full control with fluent API
let dataSource = TableDataSourceBuilder<Item>(for: tableView)
    .cells(MyCell.self)
    .configureCell(MyCell.self) { cell, item in
        cell.configure(with: item)
    }
    .enablePullToRefresh(tintColor: .systemBlue)
    .enableLoadMore()
    .emptyStateText("No items found")
    .leadingSwipeActions { item, indexPath in
        // Edit action
        return UISwipeActionsConfiguration(actions: [editAction])
    }
    .trailingSwipeActions { item, indexPath in
        // Delete action
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    .onItemSelected { item in
        showDetail(item)
    }
    .build()
```

## ConfigurableCell Protocol

```swift
// ✨ Make your cell self-configuring
class MyCell: UITableViewCell, ConfigurableCell {
    typealias Item = MyModel

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    func configure(with item: MyModel) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}

// Usage - automatic type inference!
let dataSource = TableDynamicDataSource.simpleList(
    for: tableView,
    cellType: MyCell.self  // That's it! configure() called automatically
)
```

## TableViewModel

```swift
// 🎯 Standardized view model
class MyViewModel: TableViewModel<MyModel> {
    private let service: MyService

    init(service: MyService) {
        self.service = service
        super.init()
    }

    override func performRefresh() {
        setLoading(true)
        service.fetchItems()
            .subscribe(onNext: { [weak self] items in
                self?.updateItems(items)
                self?.setLoading(false)
            })
            .disposed(by: disposeBag)
    }

    override func performLoadMore() {
        service.fetchMore()
            .subscribe(onNext: { [weak self] items in
                self?.appendItems(items)
                self?.setLoading(false)
            })
            .disposed(by: disposeBag)
    }

    override func handleSelection(_ item: MyModel) {
        coordinator.showDetail(item)
    }
}

// Automatic binding - handles everything!
let viewModel = MyViewModel(service: service)
let dataSource = tableView.setupWithViewModel(
    cellType: MyCell.self,
    viewModel: viewModel,
    configure: { $0.configure(with: $1) },
    disposeBag: disposeBag
)
```

## Reactive Bindings

### Simple Binding

```swift
// 📊 Just bind items
viewModel.items
    .bind(to: dataSource.rx.items)
    .disposed(by: disposeBag)

// Or use shortcut
dataSource.bindItems(viewModel.items, disposeBag: disposeBag)
```

### With Selection

```swift
// 👆 Bind items + selection
dataSource.bindItems(
    viewModel.items,
    onSelect: { item in showDetail(item) },
    disposeBag: disposeBag
)
```

### Pull-to-Refresh

```swift
// 🔄 Handle refresh
dataSource.rx.pullToRefresh
    .flatMapLatest { viewModel.refresh() }
    .bind(to: dataSource.rx.stopPullRefresh)
    .disposed(by: disposeBag)

// Or use standard pattern
dataSource.setupStandardRefreshPattern(
    refresh: viewModel.refresh(),
    loadMore: viewModel.loadMore(),
    disposeBag: disposeBag
)
```

### All-in-One Binding

```swift
// 🎁 Everything at once
dataSource.bind(
    items: viewModel.items,
    refresh: { viewModel.refresh() },
    loadMore: { viewModel.loadMore() },
    onSelect: { item in showDetail(item) },
    disposeBag: disposeBag
)
```

### Chainable Setup

```swift
// ⛓️ Chain configuration methods
let dataSource = DataSourcePreset.paginatedList(...)
    .onPullToRefresh({ viewModel.refresh() }, disposeBag: disposeBag)
    .onLoadMore({ viewModel.loadMore() }, disposeBag: disposeBag)
    .onSelection({ showDetail($0) }, disposeBag: disposeBag)
```

## Common Patterns

### Pattern 1: Simple Static List

```swift
let items = [Item1, Item2, Item3]
let dataSource = tableView.setupSimpleList(
    cellType: MyCell.self,
    configure: { $0.configure(with: $1) }
)
dataSource.updateItems(items, to: 0)
```

### Pattern 2: Dynamic List with Refresh

```swift
let dataSource = tableView.setupPaginatedList(
    cellType: MyCell.self,
    configure: { $0.configure(with: $1) }
)

dataSource.rx.pullToRefresh
    .flatMapLatest { api.fetchItems() }
    .bind(to: dataSource.rx.items)
    .disposed(by: disposeBag)
```

### Pattern 3: MVVM with Automatic Binding

```swift
class MyViewModel: TableViewModel<Item> {
    override func performRefresh() {
        // Fetch logic
    }
}

let viewModel = MyViewModel()
let dataSource = tableView.setupWithViewModel(
    cellType: MyCell.self,
    viewModel: viewModel,
    configure: { $0.configure(with: $1) },
    disposeBag: disposeBag
)
```

### Pattern 4: Search Results

```swift
let dataSource = DataSourcePreset.searchResultsList(
    tableView: tableView,
    cellType: ResultCell.self,
    configure: { $0.configure(with: $1) },
    onSelect: { result in navigator.show(result) }
)

searchBar.rx.text
    .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
    .flatMapLatest { query in api.search(query) }
    .bind(to: dataSource.rx.items)
    .disposed(by: disposeBag)
```

### Pattern 5: Settings List

```swift
let settings = [Setting1, Setting2, Setting3]
let dataSource = DataSourcePreset.settingsList(
    tableView: tableView,
    cellType: SettingCell.self,
    configure: { $0.configure(with: $1) },
    onSelect: { setting in handle(setting) }
)
dataSource.updateItems(settings, to: 0)
```

## Available Presets

| Preset | Use Case | Features |
|--------|----------|----------|
| `staticList` | Simple lists | Basic display |
| `selectableList` | Interactive lists | Selection handling |
| `swipeableList` | Action lists | Swipe actions |
| `refreshableList` | Dynamic content | Pull-to-refresh |
| `paginatedList` | Large datasets | Refresh + Load more |
| `searchResultsList` | Search UIs | Optimized empty state |
| `settingsList` | Settings | Fixed height |
| `formList` | Form inputs | No selection |
| `feedList` | Social feeds | Auto-height, pagination |
| `reactive` | MVVM | Auto view model binding |

## Empty States

```swift
// Simple text
.emptyStateText("No items found")

// Custom configuration
.emptyState(
    EmptyStateConfiguration.Builder()
        .text("No items found")
        .textColor(.gray)
        .font(.systemFont(ofSize: 18))
        .verticalOffset(-50)
        .build()
)

// Custom view
let customView = MyEmptyStateView()
.emptyState(EmptyStateConfiguration(customView: customView))
```

## Swipe Actions

```swift
// Leading actions (left swipe)
.leadingSwipeActions { item, indexPath in
    let editAction = UIContextualAction(
        style: .normal,
        title: "Edit"
    ) { _, _, completion in
        edit(item)
        completion(true)
    }
    editAction.backgroundColor = .systemBlue
    return UISwipeActionsConfiguration(actions: [editAction])
}

// Trailing actions (right swipe)
.trailingSwipeActions { item, indexPath in
    let deleteAction = UIContextualAction(
        style: .destructive,
        title: "Delete"
    ) { _, _, completion in
        delete(item)
        completion(true)
    }
    return UISwipeActionsConfiguration(actions: [deleteAction])
}
```

## Error Handling

```swift
// With error handling
viewModel.fetchItems()
    .map { .success($0) }
    .catchAndReturn(.failure(NetworkError.unknown))
    .bind(to: dataSource.rx.itemsWithErrorHandling { error in
        showError(error)
    })
    .disposed(by: disposeBag)
```

## Debugging

```swift
// Monitor all events
dataSource.rx.debug(prefix: "MyList")
    .subscribe(onNext: { print($0) })
    .disposed(by: disposeBag)

// Monitor loading state
dataSource.rx.loadingStateMonitor
    .subscribe(onNext: { print($0) })
    .disposed(by: disposeBag)
```

## Tips & Best Practices

### ✅ DO

- Use `ConfigurableCell` protocol for reusable cells
- Use presets for common scenarios
- Use `TableViewModel` for MVVM pattern
- Use Builder for custom configurations
- Keep cell configuration simple

### ❌ DON'T

- Don't access private data source properties
- Don't create cells manually in configure blocks
- Don't forget to dispose subscriptions
- Don't mix API levels unnecessarily
- Don't over-configure when presets work

## Performance Tips

1. **Use ConfigurableCell** - Cleaner and more maintainable
2. **Use animated: false** for initial load
3. **Use Driver** for main-thread guarantees
4. **Batch updates** when possible
5. **Use presets** - they follow best practices

## Common Issues

### Issue: Cell not updating
**Solution**: Make sure you're calling `configure(with:)` in the cell

### Issue: Memory leak
**Solution**: Use `[weak self]` in closures and Driver/Relay-based reactive

### Issue: Type inference not working
**Solution**: Explicitly specify cell type: `configureCell(MyCell.self)`

### Issue: Empty state not showing
**Solution**: Check that items array is empty and call `updateItems`

---

## Quick Links

- [Complete Usage Guide](./USAGE_GUIDE.md)
- [Migration Guide](./MIGRATION_GUIDE.md)
- [Phase 2 Summary](./PHASE2_SUMMARY.md)
- [Phase 3 Summary](./PHASE3_SUMMARY.md)
- [Complete Refactoring Summary](./REFACTORING_COMPLETE.md)
