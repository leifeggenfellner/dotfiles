# `import Quickshell.Services.Pipewire` (Quickshell 0.3.2)

## Pipewire : QtObject
*singleton*
- `nodes: ObjectModel` (readonly)
- `links: ObjectModel` (readonly)
- `linkGroups: ObjectModel` (readonly)
- `defaultAudioSink: PwNode` (readonly)
- `defaultAudioSource: PwNode` (readonly)
- `preferredDefaultAudioSink: PwNode`
- `preferredDefaultAudioSource: PwNode`
- `ready: bool` (readonly)
- signal `defaultConfiguredAudioSinkChanged()`
- signal `defaultConfiguredAudioSourceChanged()`
- `onNodeAdded(node: PwNode)`
- `onNodeRemoved(object: QtObject)`
- `onLinkAdded(link: PwLink)`
- `onLinkRemoved(object: QtObject)`
- `onLinkGroupAdded(group: PwLinkGroup)`
- `onLinkGroupRemoved(object: QtObject)`

## PwAudioChannel : QtObject
*singleton*
- `toString(value: PwAudioChannel): string`
- enum `Enum`: Unknown, NA, Mono, FrontCenter, FrontLeft, FrontRight, FrontLeftCenter, FrontRightCenter, FrontLeftWide, FrontRightWide, FrontCenterHigh, FrontLeftHigh, FrontRightHigh, LowFrequencyEffects, LowFrequencyEffects2, LowFrequencyEffectsLeft, LowFrequencyEffectsRight, SideLeft, SideRight, RearCenter, RearLeft, RearRight, RearLeftCenter, RearRightCenter, TopCenter, TopFrontCenter, TopFrontLeft, TopFrontRight, TopFrontLeftCenter, TopFrontRightCenter, TopSideLeft, TopSideRight, TopRearCenter, TopRearLeft, TopRearRight, BottomCenter, BottomLeftCenter, BottomRightCenter, AuxRangeStart, AuxRangeEnd, CustomRangeStart

## PwLink : PwObjectIface
- `id: int` (readonly)
- `target: PwNode` (readonly)
- `source: PwNode` (readonly)
- `state: PwLinkState` (readonly)

## PwLinkGroup : QtObject
- `target: PwNode` (readonly)
- `source: PwNode` (readonly)
- `state: PwLinkState` (readonly)

## PwLinkState : QtObject
*singleton*
- `toString(value: PwLinkState): string`
- enum `Enum`: Error, Unlinked, Init, Negotiating, Allocating, Paused, Active

## PwNode : PwObjectIface
- `id: int` (readonly)
- `name: string` (readonly)
- `description: string` (readonly)
- `nickname: string` (readonly)
- `isSink: bool` (readonly)
- `isStream: bool` (readonly)
- `type: Flags` (readonly)
- `properties: object` (readonly)
- `audio: PwNodeAudio` (readonly)
- `ready: bool` (readonly)

## PwNodeAudio : QtObject
- `muted: bool`
- `volume: real`
- `channels: list<PwAudioChannel>` (readonly)
- `volumes: list<real>`

## PwNodeLinkTracker : QtObject
- `node: PwNode`
- `linkGroups: list<PwLinkGroup>` (readonly)
- `onNodeDestroyed()`
- `onLinkGroupCreated(linkGroup: PwLinkGroup)`
- `onLinkGroupDestroyed(object: QtObject)`

## PwNodePeakMonitor : QtObject
- `node: PwNode`
- `enabled: bool`
- `peaks: list<real>` (readonly)
- `peak: real` (readonly)
- `channels: list<PwAudioChannel>` (readonly)
- `onNodeDestroyed()`

## PwNodeType : QtObject
*singleton*
- `toString(type: Flags): string`
- enum `Flag`: Untracked, Audio, Video, Stream, Source, Sink, AudioSink, AudioSource, AudioDuplex, AudioOutStream, AudioInStream, VideoSource, VideoSink

## PwObjectIface : QtObject
*base type, not importable*
- `onObjectDestroying()`

## PwObjectTracker : QtObject
- `objects: QObjectList`
- `objectDestroyed(object: QtObject)`
