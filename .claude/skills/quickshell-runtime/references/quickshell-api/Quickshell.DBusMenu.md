# `import Quickshell.DBusMenu` (Quickshell 0.3.2)

## DBusMenuHandle : QtObject
- `menu: DBusMenuItem` (readonly)
- signal `iconThemePathChanged()`
- `onLayoutUpdated(revision: int, parent: int)`
- `onItemPropertiesUpdated(updatedProps: DBusMenuItemPropertiesList, removedProps: DBusMenuItemPropertyNamesList)`

## DBusMenuItem : QsMenuEntry
- `menuHandle: DBusMenuHandle` (readonly)
- signal `layoutUpdated()`
- `sendOpened()`
- `sendClosed()`
- `sendTriggered()`
- `updateLayout()`
