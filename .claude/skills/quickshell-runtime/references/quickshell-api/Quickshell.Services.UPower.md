# `import Quickshell.Services.UPower` (Quickshell 0.3.2)

## PerformanceDegradationReason : QtObject
*singleton*
- `toString(reason: PerformanceDegradationReason): string`
- enum `Enum`: None, LapDetected, HighTemperature

## PowerProfile : QtObject
*singleton*
- `toString(profile: PowerProfile): string`
- enum `Enum`: PowerSaver, Balanced, Performance

## powerProfileHold
- `profile: PowerProfile`
- `applicationId: string`
- `reason: string`

## PowerProfiles : QtObject
*singleton*
- `profile: PowerProfile`
- `hasPerformanceProfile: bool` (readonly)
- `degradationReason: PerformanceDegradationReason` (readonly)
- `holds: list<powerProfileHold>` (readonly)

## UPower : QtObject
*singleton*
- `displayDevice: UPowerDevice` (readonly)
- `devices: ObjectModel` (readonly)
- `onBattery: bool` (readonly)

## UPowerDevice : QtObject
- `type: UPowerDeviceType` (readonly)
- `powerSupply: bool` (readonly)
- `energy: real` (readonly)
- `energyCapacity: real` (readonly)
- `changeRate: real` (readonly)
- `timeToEmpty: real` (readonly)
- `timeToFull: real` (readonly)
- `percentage: real` (readonly)
- `isPresent: bool` (readonly)
- `state: UPowerDeviceState` (readonly)
- `healthPercentage: real` (readonly)
- `healthSupported: bool` (readonly)
- `iconName: string` (readonly)
- `isLaptopBattery: bool` (readonly)
- `nativePath: string` (readonly)
- `model: string` (readonly)
- `ready: bool` (readonly)
- `onGetAllFinished()`

## UPowerDeviceState : QtObject
*singleton*
- `toString(status: UPowerDeviceState): string`
- enum `Enum`: Unknown, Charging, Discharging, Empty, FullyCharged, PendingCharge, PendingDischarge

## UPowerDeviceType : QtObject
*singleton*
- `toString(type: UPowerDeviceType): string`
- enum `Enum`: Unknown, LinePower, Battery, Ups, Monitor, Mouse, Keyboard, Pda, Phone, MediaPlayer, Tablet, Computer, GamingInput, Pen, Touchpad, Modem, Network, Headset, Speakers, Headphones, Video, OtherAudio, RemoteControl, Printer, Scanner, Camera, Wearable, Toy, BluetoothGeneric
