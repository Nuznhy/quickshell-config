pragma Singleton
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(item => item.isPlaying)
        || players.find(item => item.playbackState === MprisPlaybackState.Paused && item.trackTitle.length > 0)
        || null
}
