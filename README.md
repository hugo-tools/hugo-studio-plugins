# hugo-studio-plugins

The community plugin marketplace for
[Hugo Studio](https://github.com/hugo-tools/hugo-studio) — itself a
Hugo site, so adding a plugin is just another piece of content.

The site builds to `public/` and emits two surfaces:

- a human-readable index at `/plugins/` and per-plugin detail pages,
- a machine-readable feed at `/plugins/index.json` that the editor
  fetches when the user opens the "Browse" tab in Hugo Studio.

## Add a plugin

```bash
hugo new --kind plugin plugins/<your-plugin-name>
```

That scaffolds `content/plugins/<your-plugin-name>/index.md` from the
archetype with all the front-matter fields the JSON feed expects.
Drop screenshots into the same directory and reference them from
`screenshots: [...]`.

### Front-matter reference

| Key                | Required | Description                                                       |
| ------------------ | -------- | ----------------------------------------------------------------- |
| `title`            | yes      | Human-readable name shown in the editor.                          |
| `name`             | yes      | Machine name; must match the directory and is the install dir.    |
| `version`          | yes      | Semver (`1.0.0`).                                                 |
| `author`           | yes      | Author or maintainer name.                                        |
| `authorUrl`        | no       | Author homepage / GitHub profile.                                 |
| `repo`             | yes      | Source repository URL.                                            |
| `installUrl`       | yes      | Direct download URL for the plugin tarball / zip.                 |
| `extensionPoints`  | yes      | List of slots the plugin uses: `panel`, `fieldRenderer`, `dataFormat`, `shortcode`. |
| `minStudioVersion` | yes      | Minimum Hugo Studio version (semver) the plugin works with.       |
| `screenshots`      | no       | List of relative paths to images inside the plugin's bundle.      |

The page's body (markdown after the front-matter delimiter) becomes
the long-form description on the detail page.

## Run the site locally

```bash
# in this directory
hugo server -D
```

Open <http://localhost:1313/plugins/> for the index and
<http://localhost:1313/plugins/index.json> for the feed.

## Submit a plugin

Open a PR adding `content/plugins/<your-plugin-name>/` with the
required front-matter and at least one screenshot. We review for
basic safety (no obvious malware, the install URL resolves, the
extension points listed match what the plugin actually does) and
merge.

## License

MIT for the marketplace site itself; each plugin entry links to its
own repo, which picks its own license.
