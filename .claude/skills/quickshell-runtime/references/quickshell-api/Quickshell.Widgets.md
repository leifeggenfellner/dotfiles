# `import Quickshell.Widgets` (Quickshell 0.3.2)

## clippingRectangleBorder
- `color: color`
- `pixelAligned: bool`
- `width: int`

## MarginWrapperManager : WrapperManager
- `margin: real`
- `extraMargin: real`
- `topMargin: real`
- `bottomMargin: real`
- `leftMargin: real`
- `rightMargin: real`
- `resizeChild: bool`
- `implicitWidth: real`
- `implicitHeight: real`
- `onChildImplicitWidthChanged()`
- `onChildImplicitHeightChanged()`
- `setWrapperImplicitWidth()`
- `setWrapperImplicitHeight()`

## WrapperManager : QtObject
- `child: Item`
- `wrapper: Item`
- signal `initializedChildChanged()`
- `onChildDestroyed()`
