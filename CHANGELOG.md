## Unreleased

### Changed
- Added better logging, with colors and better spacing.
- Added checking for retries before shutting down server

## 0.4.2 - 2016-10-23

### Changed
- Added forgotten assets in [0.4.1](#041---2016-10-24)

## 0.4.1 - 2016-10-24

**DEPRECIATED** Contains outdated assets.  Use [0.4.2](#042---2016-10-24) instead.

### Added
- `ModuleTest#chrome` logs the URL if debug mode is on, in case the window doesn't automatically open.

### Changed
- `ModuleTest#startPhantom` now uses `page.on` instead of `page.property` for listening, allowing other scripts to also
  listen.

## 0.4.0 - 2016-10-06

### Breaking Changes
- Using layers of routing (`express.Router`) to increase performance.  To do so,
  [`ModuleServer#finalize()`](https://codelenny.github.io/module-server/doc/#https://codelenny.github.io/module-server/doc/class/ModuleServer.html#finalize-dynamic)
  was added as a necessary method, to be put after all `.load()` calls.
  ModuleServer will break on systems that lack `#finalize()`.
