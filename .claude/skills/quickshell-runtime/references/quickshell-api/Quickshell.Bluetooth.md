# `import Quickshell.Bluetooth` (Quickshell 0.3.2)

## Bluetooth : QtObject
*singleton*
- `defaultAdapter: BluetoothAdapter` (readonly)
- `adapters: ObjectModel` (readonly)
- `devices: ObjectModel` (readonly)

## BluetoothAdapter : QtObject
- `name: string` (readonly)
- `enabled: bool`
- `state: BluetoothAdapterState` (readonly)
- `discoverable: bool`
- `discoverableTimeout: int`
- `discovering: bool`
- `pairable: bool`
- `pairableTimeout: int`
- `devices: ObjectModel` (readonly)
- `adapterId: string` (readonly)
- `dbusPath: string` (readonly)

## BluetoothAdapterState : QtObject
*singleton*
- `toString(state: BluetoothAdapterState): string`
- enum `Enum`: Disabled, Enabled, Enabling, Disabling, Blocked

## BluetoothDevice : QtObject
- `address: string` (readonly)
- `name: string`
- `deviceName: string` (readonly)
- `icon: string` (readonly)
- `state: BluetoothDeviceState` (readonly)
- `connected: bool`
- `paired: bool` (readonly)
- `bonded: bool` (readonly)
- `pairing: bool` (readonly)
- `trusted: bool`
- `blocked: bool`
- `wakeAllowed: bool`
- `batteryAvailable: bool` (readonly)
- `battery: real` (readonly)
- `adapter: BluetoothAdapter` (readonly)
- `dbusPath: string` (readonly)
- `connect()`
- `disconnect()`
- `pair()`
- `cancelPair()`
- `forget()`

## BluetoothDeviceState : QtObject
*singleton*
- `toString(state: BluetoothDeviceState): string`
- enum `Enum`: Disconnected, Connected, Disconnecting, Connecting
