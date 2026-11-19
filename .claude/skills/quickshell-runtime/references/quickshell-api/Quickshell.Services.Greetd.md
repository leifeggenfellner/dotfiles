# `import Quickshell.Services.Greetd` (Quickshell 0.3.2)

## Greetd : QtObject
*singleton*
- `available: bool` (readonly)
- `state: GreetdState` (readonly)
- `user: string` (readonly)
- signal `authMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool)`
- signal `authFailure(message: string)`
- signal `readyToLaunch()`
- signal `launched()`
- signal `error(error: string)`
- `createSession(user: string)`
- `cancelSession()`
- `respond(response: string)`
- `launch(command: list<string>)`
- `launch(command: list<string>, environment: list<string>)`
- `launch(command: list<string>, environment: list<string>, quit: bool)`

## GreetdState : QtObject
*singleton*
- `toString(value: GreetdState): string`
- enum `Enum`: Inactive, Authenticating, ReadyToLaunch, Launching, Launched
