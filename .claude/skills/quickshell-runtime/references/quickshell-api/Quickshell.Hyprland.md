# `import Quickshell.Hyprland` (Quickshell 0.3.2)

## GlobalShortcut : PostReloadHook
- `pressed: bool` (readonly)
- `appid: string`
- `name: string`
- `description: string`
- `triggerDescription: string`
- signal `pressed()`
- signal `released()`
- `onPressed()`
- `onReleased()`

## Hyprland : QtObject
*singleton*
- `usingLua: bool` (readonly)
- `requestSocketPath: string` (readonly)
- `eventSocketPath: string` (readonly)
- `focusedMonitor: HyprlandMonitor` (readonly)
- `focusedWorkspace: HyprlandWorkspace` (readonly)
- `activeToplevel: HyprlandToplevel` (readonly)
- `monitors: ObjectModel` (readonly)
- `workspaces: ObjectModel` (readonly)
- `toplevels: ObjectModel` (readonly)
- signal `rawEvent(event: HyprlandEvent)`
- `dispatch(request: string)`
- `monitorFor(screen: ShellScreen): HyprlandMonitor`
- `refreshMonitors()`
- `refreshWorkspaces()`
- `refreshToplevels()`

## HyprlandEvent : QtObject
- `name: string` (readonly)
- `data: string` (readonly)
- `parse(argumentCount: int): list<string>`

## HyprlandFocusGrab : QtObject
- `active: bool`
- `windows: QObjectList`
- signal `cleared()`
- `onGrabActivated()`
- `onGrabCleared()`
- `onProxyConnected()`
- `onObjectDestroyed(object: QtObject)`

## HyprlandMonitor : QtObject
- `id: int` (readonly)
- `name: string` (readonly)
- `description: string` (readonly)
- `x: int` (readonly)
- `y: int` (readonly)
- `width: int` (readonly)
- `height: int` (readonly)
- `scale: real` (readonly)
- `lastIpcObject: object` (readonly)
- `activeWorkspace: HyprlandWorkspace` (readonly)
- `focused: bool` (readonly)
- `onActiveWorkspaceDestroyed()`

## HyprlandToplevel : QtObject
*attached: HyprlandToplevel*
- `address: string` (readonly)
- `handle: HyprlandToplevel` (readonly)
- `wayland: Toplevel` (readonly)
- `title: string` (readonly)
- `activated: bool` (readonly)
- `urgent: bool` (readonly)
- `lastIpcObject: object` (readonly)
- `workspace: HyprlandWorkspace` (readonly)
- `monitor: HyprlandMonitor` (readonly)
- signal `waylandHandleChanged()`
- signal `hyprlandHandleChanged()`
- `onActivatedChanged()`

## HyprlandWindow : QtObject
*attached: HyprlandWindow*
- `opacity: real`
- `visibleMask: Region`
- `onWindowConnected()`
- `onWindowVisibleChanged()`
- `onWaylandWindowDestroyed()`
- `onWaylandSurfaceCreated()`
- `onWaylandSurfaceDestroyed()`
- `onProxyWindowDestroyed()`
- `onVisibleMaskDestroyed()`
- `onWindowPolished()`
- `updateVisibleMask()`

## HyprlandWorkspace : QtObject
- `address: string` (readonly)
- `id: int` (readonly)
- `name: string` (readonly)
- `active: bool` (readonly)
- `focused: bool` (readonly)
- `urgent: bool` (readonly)
- `hasFullscreen: bool` (readonly)
- `lastIpcObject: object` (readonly)
- `monitor: HyprlandMonitor` (readonly)
- `toplevels: ObjectModel` (readonly)
- signal `typeChanged()`
- `onMonitorDestroyed()`
- `updateUrgent()`
- `activate()`

## PostReloadHook : QtObject
*base type, not importable*
- `postReload()`
