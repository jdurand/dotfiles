import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"

const VERTICAL = Gtk.Orientation.VERTICAL

interface PopupWindowProps {
  name: string
  marginTop?: number
  marginRight?: number
  child: Gtk.Widget
  onVisibilityChanged?: (visible: boolean) => void
}

export default function PopupWindow({
  name,
  marginTop = 44,
  marginRight = 0,
  child,
  onVisibilityChanged,
}: PopupWindowProps) {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  function hide() {
    const win = app.get_window(name)
    if (win) win.visible = false
  }

  return (
    <window
      name={name}
      namespace={`popup-${name}`}
      application={app}
      layer={Astal.Layer.OVERLAY}
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
      $={(self: Astal.Window) => {
        if (onVisibilityChanged) {
          self.connect("notify::visible", () => {
            onVisibilityChanged(self.visible)
          })
        }
      }}
    >
      <Gtk.EventControllerKey
        onKeyPressed={(_self: Gtk.EventControllerKey, keyval: number) => {
          if (keyval === Gdk.KEY_Escape) hide()
        }}
      />
      <overlay>
        <box hexpand vexpand>
          <Gtk.GestureClick onPressed={() => hide()} />
        </box>
        <box
          $type="overlay"
          halign={Gtk.Align.END}
          valign={Gtk.Align.START}
          css={`margin-top: ${marginTop}px; margin-right: ${marginRight}px;`}
        >
          <box class="popup-container" orientation={VERTICAL}>
            {child}
          </box>
        </box>
      </overlay>
    </window>
  )
}
