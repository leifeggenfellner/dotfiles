# `import Quickshell.Networking` (Quickshell 0.3.2)

## ConnectionFailReason : QtObject
*singleton*
- `toString(reason: ConnectionFailReason): string`
- enum `Enum`: Unknown, NoSecrets, WifiClientDisconnected, WifiClientFailed, WifiAuthTimeout, WifiNetworkLost

## ConnectionState : QtObject
*singleton*
- `toString(state: ConnectionState): string`
- enum `Enum`: Unknown, Connecting, Connected, Disconnecting, Disconnected

## DeviceType : QtObject
*singleton*
- `toString(type: DeviceType): string`
- enum `Enum`: None, Wifi, Wired

## Network : QtObject
- `name: string` (readonly)
- `device: NetworkDevice` (readonly)
- `nmSettings: list<NMSettings>` (readonly)
- `connected: bool` (readonly)
- `known: bool` (readonly)
- `state: ConnectionState` (readonly)
- `stateChanging: bool` (readonly)
- signal `connectionFailed(reason: ConnectionFailReason)`
- signal `requestConnect()`
- signal `requestConnectWithSettings(settings: NMSettings)`
- signal `requestDisconnect()`
- signal `requestForget()`
- `connect()`
- `connectWithSettings(settings: NMSettings)`
- `disconnect()`
- `forget()`

## NetworkBackendType : QtObject
*singleton*
- `toString(type: NetworkBackendType): string`
- enum `Enum`: None, NetworkManager

## NetworkConnectivity : QtObject
*singleton*
- `toString(conn: NetworkConnectivity): string`
- enum `Enum`: Unknown, None, Portal, Limited, Full

## NetworkDevice : QtObject
- `type: DeviceType` (readonly)
- `name: string` (readonly)
- `networks: ObjectModel` (readonly)
- `address: string` (readonly)
- `connected: bool` (readonly)
- `state: ConnectionState` (readonly)
- `nmManaged: bool`
- `autoconnect: bool`
- signal `requestDisconnect()`
- signal `requestSetAutoconnect(autoconnect: bool)`
- signal `requestSetNmManaged(managed: bool)`
- `disconnect()`

## Networking : QtObject
*singleton*
- `devices: ObjectModel` (readonly)
- `backend: NetworkBackendType` (readonly)
- `wifiEnabled: bool`
- `wifiHardwareEnabled: bool` (readonly)
- `canCheckConnectivity: bool` (readonly)
- `connectivityCheckEnabled: bool`
- `connectivity: NetworkConnectivity` (readonly)
- `checkConnectivity()`

## WifiDevice : NetworkDevice
- `scannerEnabled: bool`
- `mode: WifiDeviceMode` (readonly)

## WifiDeviceMode : QtObject
*singleton*
- `toString(mode: WifiDeviceMode): string`
- enum `Enum`: AdHoc, Station, AccessPoint, Mesh, Unknown

## WifiNetwork : Network
- `signalStrength: real` (readonly)
- `security: WifiSecurityType` (readonly)
- signal `requestConnectWithPsk(psk: string)`
- `connectWithPsk(psk: string)`

## WifiSecurityType : QtObject
*singleton*
- `toString(type: WifiSecurityType): string`
- enum `Enum`: Wpa3SuiteB192, Sae, Wpa2Eap, Wpa2Psk, WpaEap, WpaPsk, StaticWep, DynamicWep, Leap, Owe, Open, Unknown

## WiredDevice : NetworkDevice
- `network: Network` (readonly)
- `linkSpeed: int` (readonly)
- `hasLink: bool` (readonly)
