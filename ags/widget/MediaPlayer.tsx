import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createState } from "ags"
import { execAsync } from "ags/process"
import { interval } from "ags/time"
import AstalMpris from "gi://AstalMpris?version=0.1"

const VERTICAL = Gtk.Orientation.VERTICAL

// --- Helpers ---

function formatTime(seconds: number): string {
  if (!seconds || seconds < 0) return "0:00"
  const m = Math.floor(seconds / 60)
  const s = Math.floor(seconds % 60)
  return `${m}:${s.toString().padStart(2, "0")}`
}

function pickPlayer(mpris: AstalMpris.Mpris): AstalMpris.Player | null {
  const players = mpris.get_players()
  const playing = players.find(
    (p) => p.playbackStatus === AstalMpris.PlaybackStatus.PLAYING
  )
  if (playing) return playing
  const paused = players.find(
    (p) => p.playbackStatus === AstalMpris.PlaybackStatus.PAUSED
  )
  if (paused) return paused
  const spotify = players.find(
    (p) => p.busName.includes("spotify")
  )
  if (spotify) return spotify
  return null
}

// --- Main widget ---

type Align = "left" | "right"

export default function MediaPlayer({ align = "left" as Align } = {}) {
  const isLeft = align === "left"
  const mpris = AstalMpris.get_default()

  // Display state
  const [visible, setVisible] = createState(false)
  const [isHovered, setIsHovered] = createState(false)
  let leaveTimeout: number | null = null
  let windowRef: any = null
  const [title, setTitle] = createState("")
  const [artist, setArtist] = createState("")
  const [album, setAlbum] = createState("")
  const [coverArt, setCoverArt] = createState("")
  const [playIcon, setPlayIcon] = createState("\u{F040A}") // play icon
  const [position, setPosition] = createState(0)
  const [length, setLength] = createState(0)
  const [volume, setVolume] = createState(0)
  const [shuffleActive, setShuffleActive] = createState(false)
  const [loopActive, setLoopActive] = createState(false)
  const [trackUrl, setTrackUrl] = createState("")

  const posLabel = position((p: number) => formatTime(p))
  const lenLabel = length((l: number) => formatTime(l))
  const shuffleClass = shuffleActive((a: boolean) => a ? "mp-toggle mp-toggle-active" : "mp-toggle")
  const loopClass = loopActive((a: boolean) => a ? "mp-toggle mp-toggle-active" : "mp-toggle")

  function openTrack() {
    if (currentPlayer?.can_raise) {
      currentPlayer.raise()
    } else {
      execAsync(["omarchy-launch-or-focus", "spotify"])
    }
  }

  let currentPlayer: AstalMpris.Player | null = null
  let signalIds: number[] = []

  function syncFromPlayer(p: AstalMpris.Player) {
    setTitle(p.title || "")
    setArtist(p.artist || "")
    setAlbum(p.album || "")
    setCoverArt(p.coverArt || "")
    setLength(p.length || 0)
    setVolume(p.volume >= 0 ? p.volume : 0)
    setPlayIcon(
      p.playbackStatus === AstalMpris.PlaybackStatus.PLAYING
        ? "\u{F03E4}" : "\u{F040A}"
    )
    setShuffleActive(p.shuffleStatus === AstalMpris.Shuffle.ON)
    setLoopActive(
      p.loopStatus !== AstalMpris.Loop.NONE &&
      p.loopStatus !== AstalMpris.Loop.UNSUPPORTED
    )
    const url = p.get_meta("xesam:url")
    setTrackUrl(url ? url.get_string()[0] || "" : "")
  }

  function connectPlayer(p: AstalMpris.Player) {
    // Disconnect old signals
    if (currentPlayer) {
      for (const id of signalIds) {
        try { currentPlayer.disconnect(id) } catch {}
      }
    }
    signalIds = []
    currentPlayer = p

    syncFromPlayer(p)

    // Connect to property changes
    const props = [
      "title", "artist", "album", "cover-art",
      "playback-status", "length", "volume",
      "shuffle-status", "loop-status", "metadata",
    ]
    for (const prop of props) {
      const id = p.connect(`notify::${prop}`, () => syncFromPlayer(p))
      signalIds.push(id)
    }
  }

  function updatePlayer() {
    const p = pickPlayer(mpris)
    if (p) {
      connectPlayer(p)
      setVisible(true)
    } else {
      setVisible(false)
    }
  }

  // Watch player list changes
  mpris.connect("player-added", (_self: AstalMpris.Mpris, p: AstalMpris.Player) => {
    p.connect("notify::playback-status", () => updatePlayer())
    updatePlayer()
  })
  mpris.connect("player-closed", () => updatePlayer())

  // Watch existing players
  for (const p of mpris.get_players()) {
    p.connect("notify::playback-status", () => updatePlayer())
  }

  // Position polling (1s)
  interval(1000, () => {
    if (currentPlayer &&
        currentPlayer.playbackStatus === AstalMpris.PlaybackStatus.PLAYING) {
      setPosition(currentPlayer.position)
    }
  })

  updatePlayer()

  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor
  const anchor = isLeft ? TOP | LEFT : TOP | RIGHT

  // Pick the largest monitor
  const display = Gdk.Display.get_default()!
  const monitors = display.get_monitors()
  let mainMonitor: Gdk.Monitor | null = null
  let maxPixels = 0
  for (let i = 0; i < monitors.get_n_items(); i++) {
    const m = monitors.get_item(i) as Gdk.Monitor
    const geo = m.get_geometry()
    const pixels = geo.width * geo.height
    if (pixels > maxPixels) {
      maxPixels = pixels
      mainMonitor = m
    }
  }

  return (
    <window
      name="media-player"
      namespace="media-player"
      application={app}
      layer={Astal.Layer.TOP}
      anchor={anchor}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.NONE}
      gdkmonitor={mainMonitor}
      marginTop={6}
      marginLeft={isLeft ? 10 : 0}
      marginRight={isLeft ? 0 : 10}
      visible={visible}
      $={(self: Gtk.Window) => { windowRef = self }}
    >
      <box orientation={VERTICAL} class="mp-container">
        <Gtk.EventControllerMotion
          onEnter={() => {
            if (leaveTimeout) { clearTimeout(leaveTimeout); leaveTimeout = null }
            setIsHovered(true)
          }}
          onLeave={() => {
            leaveTimeout = setTimeout(() => {
              setIsHovered(false)
              // Force layershell window to shrink back
              if (windowRef) windowRef.set_default_size(1, 1)
            }, 300) as unknown as number
          }}
        />

        {/* Compact bar */}
        <box class="mp-compact">
          {!isLeft && <image
            class="mp-cover-small"
            file={coverArt}
            pixelSize={22}
            margin-end={8}
          />}
          {!isLeft && <box orientation={VERTICAL} class="mp-info" margin-end={8} hexpand>
            <label class="mp-title" label={title} xalign={0} ellipsize={3} maxWidthChars={18} />
            <label class="mp-artist" label={artist} xalign={0} ellipsize={3} maxWidthChars={18} />
          </box>}
          <box class="mp-controls" margin-start={isLeft ? 4 : 8} margin-end={isLeft ? 8 : 0}>
            <button class="mp-btn" onClicked={() => currentPlayer?.previous()}>
              <label label={"\u{F04AE}"} />
            </button>
            <button class="mp-btn mp-btn-play" onClicked={() => currentPlayer?.play_pause()}>
              <label label={playIcon} />
            </button>
            <button class="mp-btn" onClicked={() => currentPlayer?.next()}>
              <label label={"\u{F04AD}"} />
            </button>
          </box>
          {isLeft && <box orientation={VERTICAL} class="mp-info" margin-end={8} hexpand>
            <label class="mp-title" label={title} xalign={1} ellipsize={3} maxWidthChars={18} />
            <label class="mp-artist" label={artist} xalign={1} ellipsize={3} maxWidthChars={18} />
          </box>}
          {isLeft && <image
            class="mp-cover-small"
            file={coverArt}
            pixelSize={22}
            margin-start={8}
          />}
        </box>

        {/* Expanded on hover */}
        <box
          orientation={VERTICAL}
          class="mp-expanded"
          visible={isHovered}
        >
            <box class="mp-expanded-top">
              {isLeft && <image
                class="mp-cover-large"
                file={coverArt}
                pixelSize={120}
                margin-end={12}
              />}
              <box orientation={VERTICAL} class="mp-expanded-info" hexpand>
                <button class="mp-link" onClicked={() => openTrack()}>
                  <label class="mp-title-full" label={title} xalign={isLeft ? 0 : 1} wrap maxWidthChars={28} />
                </button>
                <button class="mp-link" onClicked={() => openTrack()}>
                  <label class="mp-artist-full" label={artist} xalign={isLeft ? 0 : 1} ellipsize={3} maxWidthChars={28} />
                </button>
                <button class="mp-link" onClicked={() => openTrack()}>
                  <label class="mp-album" label={album} xalign={isLeft ? 0 : 1} ellipsize={3} maxWidthChars={28} />
                </button>
              </box>
              {!isLeft && <image
                class="mp-cover-large"
                file={coverArt}
                pixelSize={120}
                margin-start={12}
              />}
            </box>
            {/* Progress */}
            <box class="mp-progress">
              <label class="mp-time" label={posLabel} xalign={1} />
              <slider
                class="mp-progress-slider"
                hexpand
                value={position}
                min={0}
                max={length}
                onChangeValue={({ value }: { value: number }) => {
                  currentPlayer?.set_position(value)
                  setPosition(value)
                }}
              />
              <label class="mp-time" label={lenLabel} xalign={0} />
            </box>
            {/* Volume + toggles */}
            <box class="mp-bottom-row">
              <label class="mp-volume-icon" label={"\u{F057E}"} />
              <slider
                class="mp-volume-slider"
                hexpand
                value={volume}
                min={0}
                max={1}
                onChangeValue={({ value }: { value: number }) => {
                  currentPlayer?.set_volume(value)
                }}
              />
              <box class="mp-toggles">
                <button
                  class={shuffleClass}
                  onClicked={() => currentPlayer?.shuffle()}
                >
                  <label label={"\u{F049D}"} />
                </button>
                <button
                  class={loopClass}
                  onClicked={() => currentPlayer?.loop()}
                >
                  <label label={"\u{F0456}"} />
                </button>
              </box>
            </box>
        </box>
      </box>
    </window>
  )
}
