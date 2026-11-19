# `import Quickshell.Services.SystemTray` (Quickshell 0.3.2)

## Category
- enum `Enum`: Hardware, SystemServices, ApplicationStatus, Communications

## Status
- enum `Enum`: Passive, Active, NeedsAttention

## SystemTray : QtObject
*singleton*
- `items: ObjectModel` (readonly)
- `onItemRegistered(item: SystemTrayItem)`
- `onItemUnregistered(item: SystemTrayItem)`

## SystemTrayItem : QtObject
- `id: string` (readonly)
- `title: string` (readonly)
- `status: Status` (readonly)
- `category: Category` (readonly)
- `icon: string` (readonly)
- `tooltipTitle: string` (readonly)
- `tooltipDescription: string` (readonly)
- `hasMenu: bool` (readonly)
- `menu: DBusMenuHandle` (readonly)
- `onlyMenu: bool` (readonly)
- signal `ready()`
- `onGetAllFinished()`
- `onGetAllFailed()`
- `activate()`
- `secondaryActivate()`
- `scroll(delta: int, horizontal: bool)`
- `display(parentWindow: QtObject, relativeX: int, relativeY: int)`
