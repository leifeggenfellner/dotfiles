# `import Quickshell.Services.Pam` (Quickshell 0.3.2)

## PamContext : QtObject
- `active: bool`
- `config: string`
- `configDirectory: string`
- `user: string`
- `message: string` (readonly)
- `messageIsError: bool` (readonly)
- `responseRequired: bool` (readonly)
- `responseVisible: bool` (readonly)
- signal `completed(result: PamResult)`
- signal `error(error: PamError)`
- signal `pamMessage()`
- `onCompleted(result: PamResult)`
- `onError(error: PamError)`
- `onMessage(message: string, isError: bool, responseRequired: bool, responseVisible: bool)`
- `start(): bool`
- `abort()`
- `respond(response: string)`

## PamError : QtObject
*singleton*
- `toString(value: PamError): string`
- enum `Enum`: StartFailed, TryAuthFailed, InternalError

## PamResult : QtObject
*singleton*
- `toString(value: PamResult): string`
- enum `Enum`: Success, Failed, Error, MaxTries
