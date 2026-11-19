# `import Quickshell.WindowManager` (Quickshell 0.3.2)

## ScreenProjection : WindowsetProjection

## WindowManager : QtObject
*singleton*
- `windowsets: list<Windowset>` (readonly)
- `windowsetProjections: list<WindowsetProjection>` (readonly)
- `screenProjection(screen: ShellScreen): ScreenProjection`

## Windowset : QtObject
- `id: string` (readonly)
- `name: string` (readonly)
- `coordinates: list<int>` (readonly)
- `active: bool` (readonly)
- `projection: WindowsetProjection` (readonly)
- `shouldDisplay: bool` (readonly)
- `urgent: bool` (readonly)
- `canActivate: bool` (readonly)
- `canDeactivate: bool` (readonly)
- `canRemove: bool` (readonly)
- `canSetProjection: bool` (readonly)
- `activate()`
- `deactivate()`
- `remove()`
- `setProjection(projection: WindowsetProjection)`

## WindowsetProjection : QtObject
- `screens: list<ShellScreen>` (readonly)
- `windowsets: list<Windowset>` (readonly)
