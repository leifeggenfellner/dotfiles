# `import Quickshell.Io` (Quickshell 0.3.2)

## DataStream : QtObject
- `parser: DataStreamParser`
- signal `readerChanged()`
- `onBytesAvailable()`
- `onReaderDestroyed()`

## DataStreamParser : QtObject
- signal `read(data: string)`

## FileViewAdapter : QtObject
- signal `adapterUpdated()`
- `onDataChanged()`

## FileViewError : QtObject
*singleton*
- `toString(value: FileViewError): string`
- enum `Enum`: Success, Unknown, FileNotFound, PermissionDenied, NotAFile

## FileViewInternal : QtObject
default property: `adapter`
- `blockWrites: bool`
- `atomicWrites: bool`
- `watchChanges: bool`
- `adapter: FileViewAdapter`
- `__path: string`
- `__text: string` (readonly)
- `__data: QByteArray` (readonly)
- `__preload: bool`
- `loaded: bool` (readonly)
- `__blockLoading: bool`
- `__blockAllReads: bool`
- `__printErrors: bool`
- signal `loaded()`
- signal `loadFailed(error: FileViewError)`
- signal `saved()`
- signal `saveFailed(error: FileViewError)`
- signal `fileChanged()`
- signal `adapterUpdated()`
- signal `pathChanged()`
- signal `internalTextChanged()`
- signal `internalDataChanged()`
- signal `textChanged()`
- signal `dataChanged()`
- signal `preloadChanged()`
- signal `loadedOrAsyncChanged()`
- signal `blockLoadingChanged()`
- signal `blockAllReadsChanged()`
- signal `printErrorsChanged()`
- `operationFinished()`
- `onAdapterDestroyed()`
- `waitForJob(): bool`
- `reload()`
- `writeAdapter()`
- `setData(data: QByteArray)`
- `setText(text: string)`

## IpcHandler : PostReloadHook
- `enabled: bool`
- `target: string`
- `onSignalTriggered(signal: string, value: string)`

## JsonAdapter : FileViewAdapter
- `onPropertyChanged()`

## JsonObject : QtObject

## Process : PostReloadHook
- `running: bool`
- `processId: var` (readonly)
- `command: list<string>`
- `workingDirectory: string`
- `environment: QVariantHash`
- `clearEnvironment: bool`
- `stdout: DataStreamParser`
- `stderr: DataStreamParser`
- `stdinEnabled: bool`
- signal `started()`
- signal `exited(exitCode: int, exitStatus: ExitStatus)`
- signal `environmentClearChanged()`
- signal `stdoutParserChanged()`
- signal `stderrParserChanged()`
- `onStarted()`
- `onFinished(exitCode: int, exitStatus: ExitStatus)`
- `onErrorOccurred(error: ProcessError)`
- `onStdoutReadyRead()`
- `onStderrReadyRead()`
- `onStdoutParserDestroyed()`
- `onStderrParserDestroyed()`
- `onGlobalWorkingDirectoryChanged()`
- `exec(command: list<string>)`
- `exec(context: processContext)`
- `signal(signal: int)`
- `write(data: string)`
- `startDetached()`

## processContext
- `command: list<string>`
- `environment: QVariantHash`
- `clearEnvironment: bool`
- `workingDirectory: string`
- `unbindStdout: bool`

## Socket : DataStream
- `connected: bool`
- `path: string`
- signal `error(error: LocalSocketError)`
- signal `connectionStateChanged()`
- `onSocketConnected()`
- `onSocketDisconnected()`
- `onSocketError(error: LocalSocketError)`
- `write(data: string)`
- `flush()`

## SocketServer : Reloadable
- `active: bool`
- `path: string`
- `handler: Component`
- signal `activeStatusChanged()`
- `onNewConnection()`

## SplitParser : DataStreamParser
- `splitMarker: string`

## StdioCollector : DataStreamParser
- `text: string` (readonly)
- `data: QByteArray` (readonly)
- `waitForEnd: bool`
- signal `streamFinished()`
