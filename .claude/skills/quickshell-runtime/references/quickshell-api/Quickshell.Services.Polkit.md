# `import Quickshell.Services.Polkit` (Quickshell 0.3.2)

## AuthFlow : QtObject
- `message: string` (readonly)
- `iconName: string` (readonly)
- `actionId: string` (readonly)
- `cookie: string` (readonly)
- `identities: list<Identity>` (readonly)
- `selectedIdentity: Identity`
- `isResponseRequired: bool` (readonly)
- `inputPrompt: string` (readonly)
- `responseVisible: bool` (readonly)
- `supplementaryMessage: string` (readonly)
- `supplementaryIsError: bool` (readonly)
- `isCompleted: bool` (readonly)
- `isSuccessful: bool` (readonly)
- `isCancelled: bool` (readonly)
- `failed: bool` (readonly)
- signal `authenticationSucceeded()`
- signal `authenticationFailed()`
- signal `authenticationRequestCancelled()`
- `request(message: string, echo: bool)`
- `completed(gainedAuthorization: bool)`
- `showError(message: string)`
- `showInfo(message: string)`
- `submit(value: string)`
- `cancelAuthenticationRequest()`

## PolkitAgent : QtObject
- `path: string`
- `isRegistered: bool` (readonly)
- `isActive: bool` (readonly)
- `flow: AuthFlow` (readonly)
- signal `authenticationRequestStarted()`
