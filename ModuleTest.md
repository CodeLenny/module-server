# Testing Modules with [ModuleTest](../class/ModuleTest.html)


[ModuleTest](../class/ModuleTest.html) can setup a testing environment for modules, enabling
them to be tested with a minimal standalone server.

Testing is based on Express and [Mocha](https://mochajs.org/).

## Test Structure

Testing is still run via the standard Mocha command.  In a folder run by Mocha, use your
standard setup.  Our example uses Chai and should.

Once the testing environment is ready, include the [ModuleTest](../class/ModuleTest.html)
class to setup a testing environment.

```js

var chai = require("chai");
var should = chai.should();

var ModuleTest = require("@codelenny/module-server");
// ModuleTest.DEBUG = yes

```

Various methods inside ModuleTest configure the test definition.
All methods mentioned in this document chain (like jQuery).

The idea is that we will create a test description section in the constructor,
then load a module in a virtual browser.
Once client-side, we will initialize the module and collect data that we can test back on
the server, to collect all data in a single Mocha run.

### Constructor  (**Required**)

The [constructor](../class/ModuleTest.html#constructor-dynamic) takes in a name to pass to
Mocha's `describe` function.

```js
var test = new ModuleTest("My Module");
```

### Load (**Required**)

[test.load()](../class/ModuleTest.html#load-dynamic) loads modules via
[ModuleServer.load()](../class/ModuleServer.html#load-dynamic).  You must load your own module,
which will also include modules listed in `package.json`.

```js
test.load("MyModule", "../");
```

### Page Body (**Optional**)

A generic webpage will be created, including the RequireJS script to load your test.
To specify additional contents to include in the body before the script tag, you can include
raw HTML via [test.html()](../class/ModuleTest.html#html-dynamic), or preprocessed code.
Blade code can be added via [test.blade()](../class/ModuleTest.html#blade-dynamic).

```js
test.html('<div id="module-target"></div>');
```

```js
test.blade("#module-target");
```

### Test Running (**Required**)

You can load [RequireJS](http://requirejs.org/)-based code to run on the webpage to fetch
data that should be tested.  Paths loaded via `test.load()` will already be initialized.
Code can be provided as raw JavaScript via [test.js()](../class/ModuleTest.html#js-dynamic)
or as CoffeeScript via [test.coffee()](../class/ModuleTest.html#coffee-dynamic).

To take advantage of test response features, require the `TestResponse` module, which is
available by default.

Your test can be written in JavaScript, but this example uses CoffeeScript to take advantage
of multi-line strings.

```coffee
test.js("""
  require(["MyModule", "TestResponse"], function(MyModule, TestResponse){
    // ...
  });
  """);
```

```coffee
test.coffee """
  require ["MyModule", "TestResponse"], (MyModule, TestResponse) ->
    # ...
"""
```

### Test Response (**Suggested**)

Inside the client-side code, the [TestResponse](../class/TestResponse.html) class
provides methods to send data to tests (discussed next).

Use the class method [TestResponse.emit()](../class/TestResponse.html#emit-static) to send
data to the tests.  `emit` takes a handler (discussed below), followed by one or more data
parameters to send to the client.

```js
TestResponse.emit("divCount", $("#module-target").length);
TestResponse.emit("module", typeof MyModule, typeof MyModule.INIT);
```

### Test Definition (**Suggested**)

Test data generated from your module client side via
[test.onit()](../class/ModuleTest.html#onit-dynamic), which defines a Mocha `it` block.

Provide a name to call the `it` block by, a URL segment (handler) to identify client side
data by, an optional timeout, and a callback to run testing with.

Each `onit` definition needs one and only one `emit` from the client side.
After the first value to `emit`, all subsequent values `emit`ed to the same handler are ignored.

```js
test.onit("has one target div", "divCount", function(count) {
  count.should.equal(1);
});
```

Example using timeouts, written in CoffeeScript.

```coffee
test.onit "loads MyModule", "module", 50000, (MyModule, INIT) ->
  should.exist MyModule
  MyModule.should.equal "function"
  should.exist INIT
  INIT.should.equal "function"
```

### Runs (**Required**)

Once all test definitions and responses have been written,
call [test.run()](../class/ModuleTest.html#run-dynamic) to run the test.

Run takes an optional integer to define the number of times the test should be executed,
to ensure that all tests are stable.

If only run once, a `describe` block is created with the name given to the constructor.
Otherwise, a describe block is created for each run, with ` (run x/y)` appended to the name.

```js
test.run(5);
```

You can optionally use an environment variable to determine if a larger number of runs should
be triggered, to shorten testing incremental changes, but occasionally fully testing components.

CoffeeScript included for compactness.

```coffee
test.run (if process.env.FULLTEST then 20 else 2)
```

### Manual Debugging (**Optional**)

If tests are failing, [test.chrome()](../class/ModuleTest.html#chrome-dynamic) will start a
copy of the testing server in parellel to the tests being run, and open a new `chrome-browser`
tab with the same HTML and JavaScript content defined as specified the test.

At the same time as running a chrome test, the normal execution of tests can still occur.
Comment out `test.run` or set the value to 0 to prevent the tests from running
in the background.

```js
test.run(0);
test.chrome();
```
