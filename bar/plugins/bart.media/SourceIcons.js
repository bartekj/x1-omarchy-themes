// Nerd Font glyph per media source. The key is MediaModel.playerAppLabel()
// lowercased — desktopEntry, else identity, else the stripped D-Bus name.
//
// Browsers deliberately map to the browser, not the site: Chromium exposes a
// single MPRIS interface for every tab (and for omarchy webapps, which join
// the same process) and never emits xesam:url, so YouTube-in-a-tab is not
// distinguishable from any other tab. A browser glyph is always truthful.

.pragma library

var GLYPHS = {
  spotify: "",
  chromium: "",
  chrome: "",
  "google-chrome": "",
  brave: "",
  "brave-browser": "",
  firefox: "",
  librewolf: "",
  zen: "",
  "microsoft-edge": "",
  mpv: "",
  vlc: "󰕼",
  celluloid: "",
  cmus: "",
  ncspot: "",
  spotifyd: ""
}

var FALLBACK = ""

// Mirrors MediaModel.playerAppLabel(): desktopEntry, else identity, else the
// D-Bus name with the MPRIS prefix and .instanceNNNN suffix stripped. Copied
// rather than imported — a relative import would have to escape the plugin
// directory, which the shell's entry-point sandboxing does not allow.
function appLabel(player) {
  if (!player) return ""
  var dbus = String(player.dbusName || "")
  dbus = dbus.replace(/^org\.mpris\.MediaPlayer2\./, "")
  dbus = dbus.replace(/\.instance[0-9]+$/, "")
  return player.desktopEntry || player.identity || dbus
}

function glyphFor(appLabel) {
  var key = String(appLabel || "").toLowerCase().trim()
  if (!key) return FALLBACK
  if (GLYPHS[key]) return GLYPHS[key]
  // Identity strings carry suffixes ("mpv Media Player", "Mozilla Firefox"),
  // so fall back to a substring match before giving up.
  for (var name in GLYPHS) {
    if (key.indexOf(name) !== -1) return GLYPHS[name]
  }
  return FALLBACK
}
