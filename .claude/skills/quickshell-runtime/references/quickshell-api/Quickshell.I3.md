# `import Quickshell.I3` (Quickshell 0.3.2)

## I3 : QtObject
*singleton*
- `socketPath: string` (readonly)
- `focusedWorkspace: I3Workspace` (readonly)
- `focusedMonitor: I3Monitor` (readonly)
- `monitors: ObjectModel` (readonly)
- `workspaces: ObjectModel` (readonly)
- signal `rawEvent(event: I3IpcEvent)`
- signal `connected()`
- `dispatch(request: string)`
- `refreshMonitors()`
- `refreshWorkspaces()`
- `findWorkspaceByName(name: string): I3Workspace`
- `findMonitorByName(name: string): I3Monitor`
- `monitorFor(screen: ShellScreen): I3Monitor`

## I3Event : QtObject
- `type: string` (readonly)
- `data: string` (readonly)

## I3IpcListener : PostReloadHook
- `subscriptions: list<string>`
- signal `ipcEvent(event: I3IpcEvent)`

## I3Monitor : QtObject
- `id: int` (readonly)
- `name: string` (readonly)
- `power: bool` (readonly)
- `activeWorkspace: I3Workspace` (readonly)
- `focusedWorkspace: I3Workspace` (readonly)
- `x: int` (readonly)
- `y: int` (readonly)
- `width: int` (readonly)
- `height: int` (readonly)
- `scale: real` (readonly)
- `focused: bool` (readonly)
- `lastIpcObject: object` (readonly)
- `onActiveWorkspaceDestroyed()`

## I3Workspace : QtObject
- `id: int` (readonly)
- `name: string` (readonly)
- `number: int` (readonly)
- `num: int` (readonly)
- `urgent: bool` (readonly)
- `active: bool` (readonly)
- `focused: bool` (readonly)
- `monitor: I3Monitor` (readonly)
- `lastIpcObject: object` (readonly)
- `onMonitorDestroyed()`
- `activate()`
