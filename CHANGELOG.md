## Unreleased

### Added

- Modularized the before/after hook timeout added in [0.5.1](#051---2016-11-16).  See `ModuleTest#_hook_timeout`.
- Added hook retry option (`ModuleTest#_hook_retries`), defaults to 1 retry allowed.

### Modified

- Fixed `cake test` to return Mocha exit status
- Increased default hook timeout to 8000ms (before)/6000ms (after).

## 0.5.1 - 2016-11-16

### Modified
- Added timeouts to before/after hooks in `ModuleTest#run`

## 0.5.0 - 2016-11-14

### Added
- `ModuleTest#run` takes `clean` option, using beforeEach/afterEach instead of before/after calls, recreating the environment for each `onit` statement.

### Modified
- `ModuleTest#run` takes an object of options instead of a single parameter (non-breaking, uses single param if given).
- `ModuleTest#run` uses before/after instead of internal promises to start tests

## 0.4.4 - 2016-11-09
Re-publish as 0.4.3 didn't take.

## 0.4.3 - 2016-11-09
**ERROR** publishing.  See [0.4.4](#043---2016-11-09).

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
