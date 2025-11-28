# Migration Guide: TableDynamicDataSource Refactoring

## Overview

This guide helps you migrate from the old `TableDynamicDataSource` API to the new, improved version with better maintainability and usability.

## What's New

### ✨ New Features
- **Builder Pattern**: Fluent, chainable API for creating data sources
- **Convenience Initializers**: Simplified creation for common use cases
- **Improved Empty State**: Configurable with images, custom views, and styling
- **Loading State Management**: Better handling of loading states
- **Reactive Coordinator**: Enhanced RxSwift integration with Relays
- **Type Safety**: Stronger compile-time guarantees
- **Better Documentation**: Comprehensive usage examples

### 🔄 Changes
- Configuration is now immutable (use Builder pattern)
- Empty state management extracted to separate component
- Loading state management improved with state machine
- Reactive extensions use Relays instead of Subjects

### ⚠️ Deprecations
- Old `Configuration` initializer (use Builder instead)
- Direct modification of configuration properties
- Some legacy initialization patterns

## Migration Steps

### Step 1: Update Imports

No changes needed - same module.

```swift
import MyLibrary
import RxSwift
```

### Step 2: Replace Old Initializers

#### Before (Old API)
```swift
dataSource = TableDynamicDataSource(
    for: tableView,
    cellsType: [MyCell.self],
    sectionsType: [],
    configCell: { item, indexPath, tableView in
        let cell = tableView.dequeue(MyCell.self)
        cell.titleLabel.text = item.title
        return cell
    },
    configHeaderFooter: nil,
    itemSelected: { item in
        self.handleSelection(item)
    },
    heightForCell: nil,
    configuration: .init(
        havePullToRefresh: true,
        leadingSwipeActionsConfiguration: { item, indexPath in
            // ...
        },
        trailingSwipeActionsConfiguration: { item, indexPath in
            // ...
        },
        textNoData: "No items found"
    )
)
```

#### After (New API - Option 1: Builder)
```swift
dataSource = TableDataSourceBuilder<MyModel>(for: tableView)
    .cells(MyCell.self)
    .configureCell(MyCell.self) { cell, item in
        cell.titleLabel.text = item.title
    }
    .onItemSelected { [weak self] item in
        self?.handleSelection(item)
    }
    .enablePullToRefresh()
    .leadingSwipeActions { item, indexPath in
        // ...
    }
    .trailingSwipeActions { item, indexPath in
        // ...
    }
    .emptyStateText("No items found")
    .build()
```

#### After (New API - Option 2: Convenience Init)
```swift
dataSource = TableDynamicDataSource(
    tableView: tableView,
    cellType: MyCell.self,
    configure: { cell, item in
        cell.titleLabel.text = item.title
    },
    onSelect: { [weak self] item in
        self?.handleSelection(item)
    }
)
```

### Step 3: Update Configuration

#### Before
```swift
let config = TableDynamicDataSource<Item>.Configuration(
    havePullToRefresh: true,
    textNoData: "No items"
)
```

#### After
```swift
let config = TableDataSourceConfiguration<Item>.Builder()
    .enablePullToRefresh()
    .emptyStateText("No items")
    .build()
```

### Step 4: Update Empty State

#### Before
```swift
configuration: .init(
    textNoData: "No items",
    viewNoData: customView
)
```

#### After (Text)
```swift
.emptyStateText("No items")
```

#### After (Custom View)
```swift
.emptyState(
    EmptyStateConfiguration(customView: customView)
)
```

#### After (Advanced)
```swift
.emptyState(
    EmptyStateConfiguration.Builder()
        .text("No items found")
        .image(UIImage(systemName: "tray"))
        .textColor(.gray)
        .font(.systemFont(ofSize: 18, weight: .medium))
        .verticalOffset(-50)
        .build()
)
```

### Step 5: Update Reactive Bindings

#### No Changes Required (Backward Compatible)
```swift
// These continue to work
viewModel.items
    .bind(to: dataSource.rx.items)
    .disposed(by: disposeBag)

dataSource.rx.itemSelected
    .subscribe(onNext: { item in
        // Handle selection
    })
    .disposed(by: disposeBag)
```

#### New: Using Reactive Coordinator
```swift
let coordinator = dataSource.createReactiveCoordinator()

// Better memory management with Relays
coordinator.itemSelected
    .subscribe(onNext: { item in
        // Handle selection
    })
    .disposed(by: disposeBag)

// Access loading state
coordinator.loadingState
    .subscribe(onNext: { state in
        updateUI(for: state)
    })
    .disposed(by: disposeBag)
```

### Step 6: Update Manual Data Updates

#### Before (Still Works)
```swift
dataSource.updateItems(items, to: 0, animated: true)
dataSource.appendItems(items: newItems, to: 0)
dataSource.finishPullToRefresh()
dataSource.finishLoadMore()
```

#### After (Reactive - Recommended)
```swift
// Update items
Observable.just(items)
    .bind(to: dataSource.rx.items)
    .disposed(by: disposeBag)

// Append items
Observable.just(newItems)
    .bind(to: dataSource.rx.appendItems())
    .disposed(by: disposeBag)

// Stop loading
Observable.just(())
    .bind(to: dataSource.rx.stopLoading)
    .disposed(by: disposeBag)
```

## Common Migration Patterns

### Pattern 1: Simple List

#### Before
```swift
dataSource = TableDynamicDataSource(
    for: tableView,
    cellsType: [MyCell.self],
    sectionsType: [],
    configCell: { item, _, tableView in
        let cell = tableView.dequeue(MyCell.self)
        cell.configure(with: item)
        return cell
    }
)
```

#### After
```swift
dataSource = TableDynamicDataSource(
    tableView: tableView,
    cellType: MyCell.self,
    configure: { cell, item in
        cell.configure(with: item)
    }
)
```

### Pattern 2: List with Pull-to-Refresh

#### Before
```swift
dataSource = TableDynamicDataSource(
    for: tableView,
    cellsType: [MyCell.self],
    sectionsType: [],
    configCell: configClosure,
    configuration: .init(havePullToRefresh: true)
)

dataSource.scrollViewDelegating = { config in
    if case .pullToRefresh = config {
        self.viewModel.refresh()
    }
}
```

#### After
```swift
dataSource = TableDataSourceBuilder<Item>(for: tableView)
    .cells(MyCell.self)
    .configure(cell: configClosure)
    .enablePullToRefresh()
    .build()

dataSource.rx.pullToRefresh
    .flatMapLatest { [weak self] in
        self?.viewModel.refresh() ?? .empty()
    }
    .bind(to: dataSource.rx.stopPullRefresh)
    .disposed(by: disposeBag)
```

### Pattern 3: List with Multiple Cell Types

#### Before
```swift
dataSource = TableDynamicDataSource(
    for: tableView,
    cellsType: [TextCell.self, ImageCell.self],
    sectionsType: [],
    configCell: { item, indexPath, tableView in
        if item.hasImage {
            return tableView.dequeue(ImageCell.self)
        } else {
            return tableView.dequeue(TextCell.self)
        }
    }
)
```

#### After
```swift
dataSource = TableDataSourceBuilder<Item>(for: tableView)
    .cells(TextCell.self, ImageCell.self)
    .configure { item, indexPath, tableView in
        if item.hasImage {
            let cell = tableView.dequeue(ImageCell.self)
            cell.configure(with: item)
            return cell
        } else {
            let cell = tableView.dequeue(TextCell.self)
            cell.configure(with: item)
            return cell
        }
    }
    .build()
```

## Troubleshooting

### Issue: Configuration properties not accessible

**Problem:**
```swift
dataSource.configuration.textNoData = "New text" // Error!
```

**Solution:**
Configuration is now immutable. Create a new data source with updated configuration:
```swift
dataSource = TableDataSourceBuilder<Item>(for: tableView)
    .emptyStateText("New text")
    .build()
```

### Issue: Subjects causing memory issues

**Problem:**
Old reactive extensions used Subjects which could cause memory leaks.

**Solution:**
Use the new Reactive Coordinator with Relays:
```swift
let coordinator = dataSource.createReactiveCoordinator()
// Relays handle memory automatically
```

### Issue: Complex initialization

**Problem:**
Too many parameters in old initializer.

**Solution:**
Use Builder pattern or convenience initializers:
```swift
// For simple cases
TableDynamicDataSource(tableView: tableView, cellType: MyCell.self, configure: ...)

// For complex cases
TableDataSourceBuilder<Item>(for: tableView)
    .cells(...)
    .configure(...)
    .build()
```

## Backward Compatibility

The old API is still supported but deprecated. You'll see warnings:

```swift
⚠️ 'init(for:cellsType:sectionsType:configCell:configHeaderFooter:itemSelected:heightForCell:configuration:)'
is deprecated: Use TableDataSourceBuilder or convenience initializers instead
```

These warnings won't break your code, but it's recommended to migrate to the new API for better maintainability.

## Testing Your Migration

1. **Build the project** - Ensure no compilation errors
2. **Run existing tests** - Verify behavior hasn't changed
3. **Test empty states** - Check empty state displays correctly
4. **Test pull-to-refresh** - Verify loading indicators work
5. **Test selections** - Ensure item selection still works
6. **Check memory** - Use Instruments to verify no leaks

## Timeline

- **Phase 1** (Current): Old and new APIs coexist
- **Phase 2** (3 months): Old API marked as deprecated
- **Phase 3** (6 months): Old API removed (major version bump)

## Getting Help

- Check [USAGE_GUIDE.md](./USAGE_GUIDE.md) for detailed examples
- Review refactoring plan in documentation
- Contact the team for specific migration issues

## Summary

| Aspect | Old API | New API |
|--------|---------|---------|
| Initialization | Complex, many parameters | Builder pattern or convenience init |
| Configuration | Mutable | Immutable with Builder |
| Empty State | Text or view only | Rich configuration with images, styling |
| Reactive | Subjects (memory issues) | Relays (safe) |
| Type Safety | Weak | Strong |
| Documentation | Limited | Comprehensive |

The new API provides better maintainability, type safety, and developer experience while maintaining backward compatibility.
