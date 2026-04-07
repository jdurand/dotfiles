import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import style from "./style.scss"
import JiraPopup from "./widget/JiraPopup"
import PrReviewsPopup from "./widget/PrReviewsPopup"
import CalendarPopup from "./widget/CalendarPopup"
import MediaPlayer from "./widget/MediaPlayer"

const windows = new Map<string, Gtk.Window>()

app.start({
  css: style,
  instanceName: "widgets",
  requestHandler(argv: string[], res: (response: any) => void) {
    const cmd = argv[0]
    const name = argv[1]

    if (cmd === "toggle" && name) {
      const win = windows.get(name)
      if (win) {
        win.visible = !win.visible
        return res("ok")
      }
      return res(`no window: ${name}`)
    }

    if (cmd === "list") {
      return res(Array.from(windows.keys()).join("\n"))
    }

    res("unknown command")
  },
  main() {
    windows.set("jira", JiraPopup() as unknown as Gtk.Window)
    windows.set("prs", PrReviewsPopup() as unknown as Gtk.Window)
    windows.set("calendar", CalendarPopup() as unknown as Gtk.Window)
    MediaPlayer({ align: "right" }) // self-managing, auto-shows when music plays
  },
})
