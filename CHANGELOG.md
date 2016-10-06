## 0.4.0 - 2016-10-06

### Breaking Changes
- Using layers of routing (`express.Router`) to increase performance.  To do so,
  [`ModuleServer#finalize()`](https://codelenny.github.io/module-server/doc/#https://codelenny.github.io/module-server/doc/class/ModuleServer.html#finalize-dynamic)
  was added as a necessary method, to be put after all `.load()` calls.
  ModuleServer will break on systems that lack `#finalize()`.
