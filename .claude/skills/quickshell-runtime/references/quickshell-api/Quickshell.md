# `import Quickshell` (Quickshell 0.3.2)

## BoundComponent : Item
default property: `data`
- `item: QtObject` (readonly)
- `sourceComponent: Component`
- `source: string`
- `bindValues: bool`
- `implicitWidth: real` (readonly)
- `implicitHeight: real` (readonly)
- signal `loaded()`
- `onComponentDestroyed()`
- `onIncubationCompleted()`
- `onIncubationFailed()`
- `updateSize()`
- `updateImplicitSize()`

## box
- `x: int`
- `y: int`
- `w: int`
- `h: int`
- `width: int`
- `height: int`
- `Box(rect: rect)`
- `Box(rect: point)`
- `Box(rect: rect)`
- `Box(rect: point)`

## ColorQuantizer : QtObject
- `colors: list<color>` (readonly)
- `source: url`
- `depth: real`
- `imageRect: rect`
- `rescaleSize: real`
- `operationFinished(result: list<color>)`

## DesktopAction : QtObject
- `id: string`
- `name: string`
- `icon: string`
- `execString: string`
- `command: list<string>`
- `execute()`

## DesktopEntries : QtObject
*singleton*
- `applications: ObjectModel` (readonly)
- `byId(id: string): DesktopEntry`
- `heuristicLookup(name: string): DesktopEntry`

## DesktopEntry : QtObject
- `id: string`
- `name: string`
- `genericName: string`
- `startupClass: string`
- `noDisplay: bool`
- `comment: string`
- `icon: string`
- `execString: string`
- `command: list<string>`
- `workingDirectory: string`
- `runInTerminal: bool`
- `categories: list<string>`
- `keywords: list<string>`
- `actions: list<DesktopAction>` (readonly)
- `execute()`

## EasingCurve : QtObject
- `curve: QEasingCurve`
- `valueAt(x: real): real`
- `interpolate(x: real, a: real, b: real): real`
- `interpolate(x: real, a: point, b: point): point`
- `interpolate(x: real, a: rect, b: rect): rect`

## Edges
- enum `Enum`: None, Top, Left, Right, Bottom

## ElapsedTimer : QtObject
- `elapsed(): real`
- `restart(): real`
- `elapsedMs(): qlonglong`
- `restartMs(): qlonglong`
- `elapsedNs(): qlonglong`
- `restartNs(): qlonglong`

## ExclusionMode
- enum `Enum`: Normal, Ignore, Auto

## FloatingWindow : QsWindow
default property: `data`
- `title: string`
- `minimumSize: size`
- `maximumSize: size`
- `minimized: bool`
- `maximized: bool`
- `fullscreen: bool`
- `parentWindow: QtObject`
- `onWindowConnected()`
- `onWindowStateChanged()`
- `startSystemMove(): bool`
- `startSystemResize(edges: Edges): bool`

## Intersection
- enum `Enum`: Combine, Subtract, Intersect, Xor

## LazyLoader : Reloadable
default property: `component`
- `item: QtObject` (readonly)
- `loading: bool`
- `active: bool`
- `activeAsync: bool`
- `component: Component`
- `source: string`
- `onIncubationCompleted()`
- `onIncubationFailed()`
- `onComponentDestroyed()`

## margins
- `left: int`
- `right: int`
- `top: int`
- `bottom: int`

## ObjectComparison
- enum `Enum`: Identity, Structure

## ObjectModel : QAbstractListModel
- `values: QObjectList` (readonly)
- signal `objectInsertedPre(object: QtObject, index: qsizetype)`
- signal `objectInsertedPost(object: QtObject, index: qsizetype)`
- signal `objectRemovedPre(object: QtObject, index: qsizetype)`
- signal `objectRemovedPost(object: QtObject, index: qsizetype)`
- `indexOf(object: QtObject): qsizetype`

## panelAnchors
- `left: bool`
- `right: bool`
- `top: bool`
- `bottom: bool`

## PanelWindow : QsWindow
default property: `data`
- `anchors: panelAnchors`
- `margins: margins`
- `exclusiveZone: int`
- `exclusionMode: ExclusionMode`
- `aboveWindows: bool`
- `focusable: bool`

## PersistentProperties : Reloadable
- signal `loaded()`
- signal `reloaded()`

## PopupAdjustment
- enum `Enum`: None, SlideX, SlideY, Slide, FlipX, FlipY, Flip, ResizeX, ResizeY, Resize, All

## PopupAnchor : QtObject
- `window: QtObject`
- `item: Item`
- `rect: box`
- `margins: margins`
- `edges: Flags`
- `gravity: Flags`
- `adjustment: Flags`
- signal `anchoring()`
- signal `backingWindowVisibilityChanged()`
- signal `windowRectChanged()`
- `onWindowDestroyed()`
- `onItemDestroyed()`
- `onItemWindowChanged()`
- `updateAnchor()`

## PopupWindow : ProxyWindowBase
default property: `data`
- `parentWindow: QtObject`
- `relativeX: int`
- `relativeY: int`
- `anchor: PopupAnchor` (readonly)
- `grabFocus: bool`
- `onParentWindowChanged()`
- `onClosed()`
- `reposition()`

## QsMenuAnchor : QtObject
- `anchor: PopupAnchor` (readonly)
- `menu: QsMenuHandle`
- `visible: bool` (readonly)
- signal `opened()`
- signal `closed()`
- `onMenuChanged()`
- `onMenuDestroyed()`
- `open()`
- `close()`

## QsMenuButtonType : QtObject
*singleton*
- `toString(value: QsMenuButtonType): string`
- enum `Enum`: None, CheckBox, RadioButton

## QsMenuEntry : QsMenuHandle
- `isSeparator: bool` (readonly)
- `enabled: bool` (readonly)
- `text: string` (readonly)
- `icon: string` (readonly)
- `buttonType: QsMenuButtonType` (readonly)
- `checkState: CheckState` (readonly)
- `hasChildren: bool` (readonly)
- signal `triggered()`
- signal `opened()`
- signal `closed()`
- `display(parentWindow: QtObject, relativeX: int, relativeY: int)`

## QsMenuHandle : QtObject
- signal `menuChanged()`

## QsMenuOpener : QtObject
- `menu: QsMenuHandle`
- `children: ObjectModel` (readonly)
- `onMenuDestroyed()`

## QsWindow : Reloadable
*attached: QsWindowAttached*
default property: `data`
- `contentItem: Item` (readonly)
- `visible: bool`
- `backingWindowVisible: bool` (readonly)
- `implicitWidth: int`
- `implicitHeight: int`
- `width: int`
- `height: int`
- `devicePixelRatio: real` (readonly)
- `screen: ShellScreen`
- `windowTransform: QtObject` (readonly)
- `color: color`
- `mask: Region`
- `surfaceFormat: surfaceFormat`
- `updatesEnabled: bool`
- `data: list<QtObject>` (readonly)
- signal `closed()`
- signal `resourcesLost()`
- signal `windowConnected()`
- `itemPosition(item: Item): point`
- `itemRect(item: Item): rect`
- `mapFromItem(item: Item, point: point): point`
- `mapFromItem(item: Item, x: real, y: real): point`
- `mapFromItem(item: Item, rect: rect): rect`
- `mapFromItem(item: Item, x: real, y: real, width: real, height: real): rect`

## Quickshell : QtObject
*singleton*
- `processId: int` (readonly)
- `instanceId: string` (readonly)
- `shellId: string` (readonly)
- `appId: string` (readonly)
- `launchTime: date` (readonly)
- `screens: list<ShellScreen>` (readonly)
- `shellDir: string` (readonly)
- `configDir: string` (readonly)
- `shellRoot: string` (readonly)
- `workingDirectory: string`
- `watchFiles: bool`
- `clipboardText: string`
- `dataDir: string` (readonly)
- `stateDir: string` (readonly)
- `cacheDir: string` (readonly)
- signal `lastWindowClosed()`
- signal `reloadCompleted()`
- signal `reloadFailed(errorString: string)`
- `onClipboardChanged(mode: Mode)`
- `reload(hard: bool)`
- `env(variable: string): var`
- `execDetached(command: list<string>)`
- `execDetached(context: processContext)`
- `iconPath(icon: string): string`
- `iconPath(icon: string, check: bool): string`
- `iconPath(icon: string, fallback: string): string`
- `hasThemeIcon(icon: string): bool`
- `shellPath(path: string): string`
- `configPath(path: string): string`
- `dataPath(path: string): string`
- `statePath(path: string): string`
- `cachePath(path: string): string`
- `inhibitReloadPopup()`
- `hasVersion(major: int, minor: int, features: list<string>): bool`
- `hasVersion(major: int, minor: int): bool`
- `hasQtVersion(major: int, minor: int): bool`

## QuickshellSettings : QtObject
- `workingDirectory: string`
- `watchFiles: bool`
- signal `lastWindowClosed()`

## Region : QtObject
default property: `regions`
- `shape: RegionShape`
- `intersection: Intersection`
- `item: Item`
- `x: int`
- `y: int`
- `width: int`
- `height: int`
- `radius: int`
- `topLeftRadius: int`
- `topRightRadius: int`
- `bottomLeftRadius: int`
- `bottomRightRadius: int`
- `regions: list<Region>` (readonly)
- signal `childrenChanged()`
- signal `changed()`
- `onItemDestroyed()`
- `onChildDestroyed()`

## RegionShape
- enum `Enum`: Rect, Ellipse

## Reloadable : QtObject
- `reloadableId: string`
- `onReloadFinished()`
- `onGenerationDestroyed()`

## Retainable : QtObject
*attached: Retainable*
- `retained: bool` (readonly)
- signal `dropped()`
- signal `aboutToDestroy()`
- `lock()`
- `unlock()`
- `forceUnlock()`

## RetainableLock : QtObject
- `object: QtObject`
- `locked: bool`
- `retained: bool` (readonly)
- signal `dropped()`
- signal `aboutToDestroy()`
- `onObjectDestroyed()`

## Scope : Reloadable
default property: `children`
- `children: list<QtObject>` (readonly)

## ScriptModel : QAbstractListModel
- `values: list<var>`
- `objectProp: string`
- `comparisonMode: ObjectComparison`

## ShellRoot : Scope
default property: `children`
- `settings: QuickshellSettings` (readonly)

## ShellScreen : QtObject
- `name: string` (readonly)
- `model: string` (readonly)
- `serialNumber: string` (readonly)
- `x: int` (readonly)
- `y: int` (readonly)
- `width: int` (readonly)
- `height: int` (readonly)
- `physicalPixelDensity: real` (readonly)
- `logicalPixelDensity: real` (readonly)
- `devicePixelRatio: real` (readonly)
- `orientation: ScreenOrientation` (readonly)
- `primaryOrientation: ScreenOrientation` (readonly)
- signal `geometryChanged()`
- `screenDestroyed()`
- `toString(): string`

## Singleton : Scope
default property: `children`

## surfaceFormat
- `opaque: bool`

## SystemClock : QtObject
- `enabled: bool`
- `precision: SystemClock`
- `date: date` (readonly)
- `hours: int` (readonly)
- `minutes: int` (readonly)
- `seconds: int` (readonly)
- `onTimeout()`
- enum `Enum`: Hours, Minutes, Seconds

## TransformWatcher : QtObject
- `a: Item`
- `b: Item`
- `commonParent: Item`
- `transform: QtObject` (readonly)
- `recalcChains()`
- `itemDestroyed()`
- `aDestroyed()`
- `bDestroyed()`

## Variants : Reloadable
default property: `delegate`
- `delegate: Component`
- `model: var`
- `instances: list<QtObject>` (readonly)
