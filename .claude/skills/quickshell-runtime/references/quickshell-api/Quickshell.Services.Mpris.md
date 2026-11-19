# `import Quickshell.Services.Mpris` (Quickshell 0.3.2)

## Mpris : QtObject
*singleton*
- `players: ObjectModel` (readonly)

## MprisLoopState : QtObject
*singleton*
- `toString(status: MprisLoopState): string`
- enum `Enum`: None, Track, Playlist

## MprisPlaybackState : QtObject
*singleton*
- `toString(status: MprisPlaybackState): string`
- enum `Enum`: Stopped, Playing, Paused

## MprisPlayer : QtObject
- `canControl: bool` (readonly)
- `canPlay: bool` (readonly)
- `canPause: bool` (readonly)
- `canTogglePlaying: bool` (readonly)
- `canSeek: bool` (readonly)
- `canGoNext: bool` (readonly)
- `canGoPrevious: bool` (readonly)
- `canQuit: bool` (readonly)
- `canRaise: bool` (readonly)
- `canSetFullscreen: bool` (readonly)
- `identity: string` (readonly)
- `desktopEntry: string` (readonly)
- `dbusName: string` (readonly)
- `position: real`
- `positionSupported: bool` (readonly)
- `length: real` (readonly)
- `lengthSupported: bool` (readonly)
- `volume: real`
- `volumeSupported: bool` (readonly)
- `metadata: object` (readonly)
- `uniqueId: int` (readonly)
- `trackTitle: string` (readonly)
- `trackArtist: string` (readonly)
- `trackArtists: string` (readonly)
- `trackAlbum: string` (readonly)
- `trackAlbumArtist: string` (readonly)
- `trackArtUrl: string` (readonly)
- `playbackState: MprisPlaybackState`
- `isPlaying: bool`
- `loopState: MprisLoopState`
- `loopSupported: bool` (readonly)
- `rate: real`
- `minRate: real` (readonly)
- `maxRate: real` (readonly)
- `shuffle: bool`
- `shuffleSupported: bool` (readonly)
- `fullscreen: bool`
- `supportedUriSchemes: list<string>` (readonly)
- `supportedMimeTypes: list<string>` (readonly)
- signal `trackChanged()`
- signal `postTrackChanged()`
- signal `ready()`
- `onGetAllFinished()`
- `onExportedPositionChanged()`
- `onSeek(time: qlonglong)`
- `raise()`
- `quit()`
- `openUri(uri: string)`
- `next()`
- `previous()`
- `seek(offset: real)`
- `play()`
- `pause()`
- `stop()`
- `togglePlaying()`
