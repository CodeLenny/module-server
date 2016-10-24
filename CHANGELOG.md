## 0.4.1 - 2016-10-24

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
