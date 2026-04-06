import { Gtk } from "ags/gtk4"
import Pango from "gi://Pango"
import { execAsync } from "ags/process"
import { interval } from "ags/time"
import { createState, For } from "ags"
import PopupWindow from "./PopupWindow"

// Required env: ~/.dotfiles/environment/github.env
//   GITHUB_ORG - GitHub organization to search PRs in

const VERTICAL = Gtk.Orientation.VERTICAL

interface PullRequest {
  repository: { nameWithOwner: string }
  title: string
  url: string
}

const PR_CMD = [
  "bash", "-c",
  'source "$HOME/.dotfiles/environment/github.env" 2>/dev/null;'
  + ' timeout 10 gh search prs'
  + ' --review-requested @me'
  + ' --owner "$GITHUB_ORG"'
  + ' --state open'
  + ' --json repository,title,url 2>/dev/null || echo "[]"',
]

function parsePrs(output: string): PullRequest[] {
  try {
    return JSON.parse(output.trim())
  } catch {
    return []
  }
}

function repoShortName(fullName: string): string {
  // Strip org prefix if present (e.g. "libroreserve/repo" -> "repo")
  const slash = fullName.indexOf("/")
  return slash >= 0 ? fullName.slice(slash + 1) : fullName
}

function PrRow({ pr }: { pr: PullRequest }) {
  const repo = repoShortName(pr.repository.nameWithOwner)

  return (
    <button
      class="popup-row"
      onClicked={() => execAsync(["xdg-open", pr.url])}
    >
      <box orientation={VERTICAL}>
        <box class="row-top">
          <label class="pr-repo" label={repo} xalign={0} />
          <label class="badge badge-review" label="Review" />
        </box>
        <label
          class="pr-title"
          label={pr.title}
          xalign={0}
          ellipsize={Pango.EllipsizeMode.END}
          maxWidthChars={48}
        />
      </box>
    </button>
  )
}

export default function PrReviewsPopup() {
  const [prs, setPrs] = createState<PullRequest[]>([])

  function fetchData() {
    execAsync(PR_CMD)
      .then((out) => setPrs(parsePrs(out)))
      .catch(() => setPrs([]))
  }

  fetchData()
  interval(900_000, fetchData)

  return PopupWindow({
    name: "pr-reviews-popup",
    marginRight: 540,
    child: (
      <box orientation={VERTICAL} class="popup-content">
        <label class="popup-header" label="PR REVIEWS" xalign={0} />
        <box orientation={VERTICAL} class="popup-list">
          <label
            class="popup-empty"
            label="No PRs to review"
            visible={prs((l: PullRequest[]) => l.length === 0)}
          />
          <For each={prs}>
            {(pr: PullRequest) => <PrRow pr={pr} />}
          </For>
        </box>
      </box>
    ),
  })
}
