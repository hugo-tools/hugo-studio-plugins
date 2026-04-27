# Plugin schema

Two contracts to keep straight:

1. **Marketplace entry** — what authors put in
   `content/plugins/<name>/index.md` and what the JSON feed at
   `/plugins/index.json` exposes.
2. **Install bundle** — what the editor actually downloads from
   `installUrl` and unpacks into the user's site.

Both are versioned. The marketplace feed envelope carries
`feedVersion`; the install bundle's `plugin.json` carries
`manifestVersion`. Bump either when a non-additive change ships;
add fields freely without bumping.

---

## 1. Marketplace entry

Front-matter fields on `content/plugins/<name>/index.md`. Required
fields are non-empty strings unless noted.

| Key                | Required | Type / shape                         | Notes                                                                                |
| ------------------ | -------- | ------------------------------------ | ------------------------------------------------------------------------------------ |
| `title`            | yes      | string                               | Human-readable name shown in the editor.                                             |
| `name`             | yes      | string (slug)                        | Machine name. Must match the bundle directory and the install dir.                   |
| `version`          | yes      | semver                               | `1.0.0`, `0.2.0`, `1.0.0-beta.1`. Validated against `^[0-9]+\.[0-9]+\.[0-9]+(...)?$`. |
| `author`           | yes      | string                               | Author or maintainer name.                                                           |
| `authorUrl`        | no       | URL                                  | Author homepage / GitHub profile.                                                    |
| `repo`             | yes      | URL                                  | Source repository URL.                                                               |
| `installUrl`       | yes      | URL                                  | Direct download for the install bundle (`.zip`).                                     |
| `extensionPoints`  | yes      | non-empty array of known strings     | Subset of `panel`, `fieldRenderer`, `dataFormat`, `shortcode`. See §3 below.         |
| `minStudioVersion` | yes      | semver                               | Editor refuses to install if its own version is lower.                               |
| `description`      | no       | string                               | One-sentence summary. Fallback: page summary.                                        |
| `screenshots`      | no       | list of relative paths               | Files inside the plugin's bundle directory; copied as page resources.                |

The page body (markdown after the front-matter delimiter) is the
long-form description on the detail page.

### What the JSON feed adds

`scripts/validate-feed.sh` runs in CI before deploy. The generated
feed envelope is:

```jsonc
{
  "feedVersion": 1,
  "generatedAt": "2026-04-27T03:29:59Z",
  "marketplace": {
    "name": "Hugo Studio Plugins",
    "url": "https://hugo-tools.github.io/hugo-studio-plugins/",
    "source": "https://github.com/hugo-tools/hugo-studio-plugins"
  },
  "plugins": [
    {
      "name": "word-count",
      "title": "Word Count",
      "version": "0.1.0",
      "author": "...",
      "authorUrl": "...",
      "description": "...",
      "repo": "https://github.com/hugo-tools/hugo-studio-plugin-word-count",
      "installUrl": "https://.../word-count.zip",
      "extensionPoints": ["panel"],
      "minStudioVersion": "1.11.0",
      "detailUrl": "https://hugo-tools.github.io/hugo-studio-plugins/plugins/word-count/",
      "screenshots": ["https://.../1.png", "https://.../2.png"],
      "updatedAt": "2026-04-27T00:00:00Z"
    }
  ]
}
```

`detailUrl`, `screenshots` (absolute), and `updatedAt` are derived
by Hugo at build time — authors don't set them.

---

## 2. Install bundle

Authors publish a `.zip` archive that the editor downloads from
`installUrl` and extracts into:

```
<site>/.hugoeditor/plugins/<name>/
```

`<name>` matches the marketplace entry's `name` field. The archive
must extract **into** that directory (not nested inside another).

### Required layout

```
<name>.zip
├── plugin.json     # manifest (see below)
├── index.js        # ES module entry point (default export)
├── README.md       # optional but encouraged
├── LICENSE         # optional
└── assets/         # optional — anything else the plugin needs at runtime
```

### `plugin.json`

```jsonc
{
  "manifestVersion": 1,
  "name": "word-count",
  "version": "0.1.0",
  "extensionPoints": ["panel"],
  "minStudioVersion": "1.11.0",
  "entry": "index.js"
}
```

The fields mirror the marketplace entry where they overlap; the
editor refuses to load a bundle whose `name` / `version` /
`minStudioVersion` disagree with what the marketplace promised, so
the user can trust the marketplace surface.

### `index.js`

ES module. Default export is an object that names the extension
points the plugin implements:

```js
export default {
  id: "word-count",

  // Optional: register a panel that shows up as a tab.
  panel: {
    label: "Word count",
    // `host` is the editor's plugin API — see the host SDK reference.
    render(host, container) {
      // mount React here, or any other framework, or vanilla DOM.
      // returns a teardown function called when the panel unmounts.
    },
  },

  // Optional: contribute custom field renderers, data formats,
  // shortcode pickers/previews. Each lives under its own key —
  // see §3 below.
};
```

The actual host SDK ships with the editor at v1.11+; this section
is the marketplace-side spec.

---

## 3. Extension points

Allowed values for `extensionPoints` (validator enforces the set):

| Value           | What the plugin contributes                                                                |
| --------------- | ------------------------------------------------------------------------------------------ |
| `panel`         | A new tab in the site shell. Plugin owns the React (or any DOM) subtree inside.            |
| `fieldRenderer` | A custom renderer for one or more front-matter field keys (e.g. `accentColor → ColourPicker`). |
| `dataFormat`    | A handler for an additional file type under `data/` (e.g. `.xlsx`, `.kml`) — parse, serialise, custom editor component. |
| `shortcode`     | Toolbar picker that inserts shortcode invocations + (optionally) a preview node for the Rich editor. |

A plugin can list more than one — e.g. `["panel", "shortcode"]` for
a plugin that adds both a sidebar and a body-editor button.

---

## 4. Versioning policy

- **Add** a field freely, in either contract. Editors and existing
  plugins ignore unknown keys.
- **Remove** or **rename** a field → bump `feedVersion` (marketplace)
  or `manifestVersion` (bundle).
- **Tighten validation** (e.g. make a previously-optional field
  required) → also bumps the relevant version.

The editor refuses any feed/bundle whose declared version is higher
than what it knows how to read, with a clear error pointing the user
at the editor update.
