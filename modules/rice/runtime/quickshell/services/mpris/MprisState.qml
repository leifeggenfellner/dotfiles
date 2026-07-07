pragma Singleton
import QtQuick
import Quickshell.Services.Mpris

// ── MprisState — REAL ────────────────────────────────────────
// Thin wrapper around Quickshell's MPRIS watcher. The active player
// is the currently playing client when possible, otherwise the first
// known client; widgets never touch native player objects directly.
//
//   state:    available, players[], nowPlaying
//   commands: toggle(), next(), previous(), seekFraction(fraction)

Item {
    id: mpris

    readonly property bool mock: false
    readonly property bool available: true
    readonly property bool busy: false
    readonly property string error: ""

    readonly property var players: _players().map(p => _entry(p))
    readonly property var nowPlaying: {
        const p = _activePlayer();
        return p ? _entry(p) : null;
    }

    function _players() {
        return Mpris.players.values ?? [];
    }

    function _activePlayer() {
        const all = _players();
        if (all.length === 0)
            return null;
        return all.find(p => p.isPlaying) ?? all[0];
    }

    function _entry(p) {
        const title = p.trackTitle && p.trackTitle.length > 0 ? p.trackTitle : "No track title";
        const artist = p.trackArtist && p.trackArtist.length > 0 ? p.trackArtist : p.identity;
        return {
            id: p.uniqueId,
            identity: p.identity,
            desktopEntry: p.desktopEntry,
            title: title,
            artist: artist,
            album: p.trackAlbum,
            artUrl: p.trackArtUrl,
            isPlaying: p.isPlaying,
            position: p.positionSupported ? p.position : 0,
            length: p.lengthSupported ? p.length : 0,
            volume: p.volumeSupported ? p.volume : 0,
            canControl: p.canControl,
            canToggle: p.canTogglePlaying || p.canPlay || p.canPause,
            canNext: p.canGoNext,
            canPrevious: p.canGoPrevious,
            canSeek: p.canSeek && p.lengthSupported && p.length > 0
        };
    }

    function _withActive(fn) {
        const p = _activePlayer();
        if (p)
            fn(p);
    }

    function toggle() {
        _withActive(p => {
            if (p.canTogglePlaying)
                p.togglePlaying();
            else if (p.isPlaying && p.canPause)
                p.pause();
            else if (p.canPlay)
                p.play();
        });
    }

    function next() {
        _withActive(p => { if (p.canGoNext) p.next(); });
    }

    function previous() {
        _withActive(p => { if (p.canGoPrevious) p.previous(); });
    }

    function seekFraction(fraction) {
        _withActive(p => {
            if (!p.canSeek || !p.lengthSupported || p.length <= 0)
                return;
            p.position = Math.max(0, Math.min(1, fraction)) * p.length;
        });
    }
}
