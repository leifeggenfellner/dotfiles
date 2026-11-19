# `import Quickshell.Wayland` (Quickshell 0.3.2)

## BackgroundEffect : QtObject
*attached: BackgroundEffect*
- `blurRegion: Region`
- `onWindowConnected()`
- `onWindowVisibleChanged()`
- `onWaylandWindowDestroyed()`
- `onWaylandSurfaceCreated()`
- `onWaylandSurfaceDestroyed()`
- `onProxyWindowDestroyed()`
- `onBlurRegionDestroyed()`
- `onWindowPolished()`
- `updateBlurRegion()`

## IdleInhibitor : QtObject
- `enabled: bool`
- `window: QtObject`
- `onWindowDestroyed()`
- `onWindowVisibilityChanged()`
- `onWaylandWindowDestroyed()`
- `onWaylandSurfaceCreated()`
- `onWaylandSurfaceDestroyed()`

## IdleMonitor : PostReloadHook
- `enabled: bool`
- `timeout: real`
- `respectInhibitors: bool`
- `isIdle: bool` (readonly)

## ProxyWindowBase : Reloadable
*base type, not importable*
default property: `data`
- `_backingWindow: Window` (readonly)
- `contentItem: Item` (readonly)
- `visible: bool`
- `implicitWidth: int`
- `implicitHeight: int`
- `width: int`
- `height: int`
- `devicePixelRatio: real` (readonly)
- `screen: ShellScreen`
- `color: color`
- `mask: Region`
- `windowTransform: QtObject` (readonly)
- `backingWindowVisible: bool` (readonly)
- `surfaceFormat: surfaceFormat`
- `updatesEnabled: bool`
- `data: list<QtObject>` (readonly)
- signal `closed()`
- signal `resourcesLost()`
- signal `windowConnected()`
- signal `windowDestroyed()`
- signal `backerVisibilityChanged()`
- signal `xChanged()`
- signal `yChanged()`
- signal `polished()`
- `onWidthChanged()`
- `onHeightChanged()`
- `onPolished()`
- `onSceneGraphError(error: SceneGraphError, message: string)`
- `onVisibleChanged()`
- `onMaskChanged()`
- `onMaskDestroyed()`
- `onScreenDestroyed()`
- `onExposed()`
- `itemPosition(item: Item): point`
- `itemRect(item: Item): rect`
- `mapFromItem(item: Item, point: point): point`
- `mapFromItem(item: Item, x: real, y: real): point`
- `mapFromItem(item: Item, rect: rect): rect`
- `mapFromItem(item: Item, x: real, y: real, width: real, height: real): rect`

## ScreencopyView : Item
default property: `data`
- `captureSource: QtObject`
- `paintCursor: bool`
- `live: bool`
- `hasContent: bool` (readonly)
- `sourceSize: size` (readonly)
- `constraintSize: size`
- signal `stopped()`
- signal `paintCursorsChanged()`
- `onCaptureSourceDestroyed()`
- `onFrameCaptured()`
- `destroyContextWithUpdate()`
- `onBuffersReady()`
- `captureFrame()`

## ShortcutInhibitor : QtObject
- `enabled: bool`
- `window: QtObject`
- `active: bool` (readonly)
- signal `cancelled()`
- `onWindowDestroyed()`
- `onWindowVisibilityChanged()`
- `onWaylandWindowDestroyed()`
- `onWaylandSurfaceCreated()`
- `onWaylandSurfaceDestroyed()`
- `onInhibitorActiveChanged()`

## Toplevel : QtObject
- `appId: string` (readonly)
- `title: string` (readonly)
- `parent: Toplevel` (readonly)
- `activated: bool` (readonly)
- `screens: list<ShellScreen>` (readonly)
- `maximized: bool`
- `minimized: bool`
- `fullscreen: bool`
- signal `closed()`
- `onClosed()`
- `onRectangleProxyConnected()`
- `onRectangleProxyDestroyed()`
- `activate()`
- `close()`
- `fullscreenOn(screen: ShellScreen)`
- `setRectangle(window: QtObject, rect: rect)`
- `unsetRectangle()`

## ToplevelManager : QtObject
*singleton*
- `toplevels: ObjectModel` (readonly)
- `activeToplevel: Toplevel` (readonly)

## WlrKeyboardFocus
- enum `Enum`: None, Exclusive, OnDemand

## WlrLayer
- enum `Enum`: Background, Bottom, Top, Overlay

## WlrLayershell : ProxyWindowBase
*attached: WlrLayershell*
- `layer: WlrLayer`
- `namespace: string`
- `keyboardFocus: WlrKeyboardFocus`
- `anchors: panelAnchors`
- `exclusiveZone: int`
- `exclusionMode: ExclusionMode`
- `margins: margins`
- `aboveWindows: bool`
- `focusable: bool`
- `updateAutoExclusion()`
- `onBridgeDestroyed()`

## WlSessionLock : Reloadable
default property: `surface`
- `locked: bool`
- `secure: bool` (readonly)
- `surface: Component`
- signal `lockStateChanged()`
- signal `secureStateChanged()`
- signal `surfaceComponentChanged()`
- `unlock()`
- `onScreensChanged()`

## WlSessionLockSurface : Reloadable
default property: `data`
- `contentItem: Item` (readonly)
- `visible: bool` (readonly)
- `width: int` (readonly)
- `height: int` (readonly)
- `screen: ShellScreen` (readonly)
- `color: color`
- `data: list<QtObject>` (readonly)
- `onScreenDestroyed()`
- `onWidthChanged()`
- `onHeightChanged()`
