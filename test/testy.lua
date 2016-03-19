#!/usr/bin/env lua

-- **Testy** is a quick-and-dirty unit testing script for Lua modules
-- that tries to be as unobtrusive as possible. It loads the specified
-- modules and collects test functions from local variables by means
-- of debug hooks. Finally, those test functions are run to collect
-- and print statistics about passed/failed test assertions.
--
-- Nice features about this approach are:
-- *   By storing the test code side-by-side with your regular module
--     code it should be easier to keep those two in sync.
-- *   You can test internal/local functions without messing up your
--     public interface (because the test functions themselves are
--     local functions embedded in the module code as well).
-- *   If you don't load the module via the `testy.lua` script, the
--     local test functions and all test data just goes out of scope
--     and gets garbage-collected very quickly.
--
-- The current implementation consists of a single pure Lua file
-- compatible with Lua 5.1 and up, with no external dependencies.
--
-- The `testy.lua` [source code][1] is available on GitHub, and is
-- released under the [MIT license][2]. You can view [a nice HTML
-- version][3] of this file rendered by [Docco][4] on the GitHub
-- pages.
--
-- Test functions are identified by a `"test_"` prefix and use the
-- standard `assert` function or the new `testy_assert` function for
-- individual test assertions. Both functions just log failure/success
-- and print a visual indicator to the console, but they do *not*
-- terminate the program (of course `assert` still does when used
-- outside of a test function for compatibility).
--
-- Here is an example:
--
--     -- module1.lua
--     local M = {}
--
--     function M.func1()
--       return 1
--     end
--     
--     -- this is a test function for the module function `M.func1()`
--     local function test_func1()
--       assert( M.func1() == 1, "func1() should always return 1" )
--       assert( M.func1() ~= 2, "func1() should never return 2" )
--       assert( type( M.func1() ) == "number" )
--     end
--
--     function M.func2()
--       return 2
--     end
--     
--     -- this is a test function for the module function `M.func2()`
--     local function test_func2()
--       assert( M.func2() == 2 )
--       assert( M.func2() ~= M.func1() )
--     end
--     
--     return M
--
-- Using the `testy.lua` script on this file will get you the
-- following output:
--
--     $ testy.lua module1.lua
--     func1 ('module1.lua')   ...
--     func2 ('module1.lua')   ..
--     5 tests (5 ok, 0 failed, 0 errors)
--
-- **Testy** is a very minimal unit testing framework that lacks lots
-- of features that other unit testing frameworks have, but in return
-- you can start unit testing without a learning curve.
--
--   [1]: http://github.com/siffiejoe/lua-testy
--   [2]: http://opensource.org/licenses/MIT
--   [3]: http://siffiejoe.github.io/lua-testy/
--   [4]: http://jashkenas.github.io/docco/
--
-- ## Implementation
--

-- There are some obviously arbitrary design choices (like e.g. the
-- prefix of the test functions) that one might want to customize.
-- Those variables allow you to do just that:
local prefix = "test_" -- the prefix of test functions to look for
local pass_char, fail_char = ".", "X" -- output for passed/failed tests
local max_line = 72 -- where to wrap test output in the terminal
local gap = " " -- space between caption and first pass/fail_char
local fh = io.stderr -- file handle to print test output to

-- There's also some data that the `testy.lua` script needs to keep
-- track of, like module files, test functions, test failures, etc.:
local files, chunks, do_recursive, do_tap = {}, {}, false, false
local tests, test_functions = {}, {}
local n_tests, n_passed, n_errors = 0, 0, 0
local cursor_pos = 0
local locals = {}
local thischunk = debug.getinfo( 1, "f" ).func
local assert = assert -- we monkey-patch assert, so save the real one


-- During `assert` or `testy_assert` the test statistics are updated
-- and a visual indicator is printed to the console.
local function evaluate_test_assertion( finfo, cinfo, ok, ... )
  n_tests = n_tests + 1
  if do_tap then
    fh:write( ok and "" or "not ", "ok ", n_tests )
    local src, line = finfo.source, cinfo.currentline
    -- The test description is just the file and line number. In
    -- principle the `assert` message could be used here, but it
    -- often describes the error instead of the test case, so this
    -- could be weird.
    fh:write( " ", src, ":", line )
    -- However, if the assertion message starts with "# TODO" or
    -- "# SKIP", those directives are passed through to the TAP
    -- consumer.
    if type( (...) ) == "string" and
       ((...):match( "^#%s*[Tt][Oo][Dd][Oo]" ) or
        (...):match( "^#%s*[Ss][Kk][Ii][Pp]" )) then
      fh:write( " ", (...) )
    end
    -- In case the test failed, an additional diagnostic message is
    -- printed:
    if not ok then
      local msg = (...) ~= nil and tostring( (...) )
                               or "test assertion failed!"
      fh:write( "\n# Failed test (", src, " at line ", line, ": '",
                msg, "')" )
    end
    fh:write( "\n" )
  else
    fh:write( ok and pass_char or fail_char )
    -- For nicer output the visual test indicators are wrapped at a
    -- certain line length (`max_line`).
    cursor_pos = (cursor_pos + 1) % max_line
    if cursor_pos == 0 then
      fh:write( "\n" )
    end
  end
  fh:flush()
  if ok then
    n_passed = n_passed + 1
    return ok, ...
  else
    -- Details of test failures are stored per test function and
    -- printed when all `assert`s in this test function are complete.
    -- This looks nicer on screen. (Another option would be to print
    -- all failure details at the very end.) For the TAP output the
    -- failure details are written out just after the failed test.
    local fail = {
      no = n_tests,
      line = cinfo.currentline,
      reason = (...) ~= nil and tostring( (...) ) or nil
    }
    finfo[ #finfo+1 ] = fail
  end
end


-- **Testy** provides a monkey-patched `assert` function that can be
-- used in test functions without killing the program on an assertion
-- failure. For compatibility, any call of this function outside of
-- test functions just uses the [original `assert` function][5] from
-- Lua's standard library. Usually this is exactly what you want, but
-- there may be certain situations where you want to move an `assert`
-- call to an extra function and still update test statistics (like
-- e.g. assertions in callbacks, or helper functions for assertions).
-- For these cases **Testy** also provides the new global function
-- `testy_assert`.
--
--   [5]: http://www.lua.org/manual/5.1/manual.html#pdf-assert
local function _G_assert( ok, ... )
  -- The `assert` replacement checks the call stack via the `debug`
  -- API to find the calling test function and some extra information
  -- for the test statistics.
  local info = debug.getinfo( 2, "fl" )
  local finfo = test_functions[ info.func or false ]
  if finfo then
    return evaluate_test_assertion( finfo, info, ok, ... )
  else
    return assert( ok, ... )
  end
end


-- `testy_assert` works similar to the `assert` replacement function,
-- but since calls to this function in non-test code are not an issue
-- (it is a new function), `testy_assert` works anywhere and can
-- always be used instead of plain `assert`. In certain situations it
-- *has* to be used to run **Testy** assertions, e.g.:
--
--     local function assert_equal( x, y )
--       testy_assert( x == y )  -- call in helper assertion function
--     end
--
--     local function test_mytest()
--       local function callback( x )
--         testy_assert( x == 1 ) -- call in callback
--       end
--       M.foreachi( { 1, 1, 1 }, callback )
--       assert_equal( 1, 1 )
--     end
--
-- Although the new `testy_assert` function is more general than the
-- monkey-patched `assert` function the latter is still made available
-- because:
--
-- *   Every Lua programmer can see what's going on, and it looks more
--     familiar.
-- *   Converting ad-hoc test code is easier.
-- *   Most test code can be run without using the `testy.lua` program
--     simply by adding a call to one or more test functions in the
--     module code.
-- *   Also `assert` is shorter than `testy_assert`. ;-)
local function _G_testy_assert( ok, ... )
  -- A `testy_assert` call also inspects the call stack to find the
  -- test function it belongs to, but since the restriction that it
  -- has to be called *directly* from the test function could be
  -- lifted, the entire call stack is searched from top to bottom.
  local info, i, finfo = debug.getinfo( 2, "fl" ), 3
  while info do
    if info.func == thischunk then break end
    finfo = test_functions[ info.func or false ]
    if finfo then break end
    info, i = debug.getinfo( i, "fl" ), i+1
  end
  if finfo then
    return evaluate_test_assertion( finfo, info, ok, ... )
  else
    error( "call to 'testy_assert' function outside of tests", 2 )
  end
end


-- The local test functions are collected via debug hooks from main
-- chunks only. This function checks that a debug hook belongs to
-- a main chunk.
local function main_chunk( lvl )
  lvl = lvl+1 -- skip stack level of this function
  local info, i = debug.getinfo( lvl, "Sf" ), lvl+2
  if not info or info.what ~= "main" or info.func == thischunk then
    return false
  end
  -- If the `-r` flag is in effect, any main chunk may contain test
  -- functions that will be collected. If `-r` is *not* in effect,
  -- only the main chunk executed directly by the `testy.lua` script
  -- will be scanned.
  if not do_recursive then
    info = debug.getinfo( lvl+1, "Sf" )
    while info and info.func ~= thischunk do
      if info.what == "main" then
        return false
      end
      info, i = debug.getinfo( i, "Sf" ), i+1
    end
  end
  return true
end


-- Usually a return hook would be the perfect place to collect
-- information about local variables because all variables have been
-- defined and contain their final values. Unfortunately all current
-- PUC-Rio Lua versions (5.1.5, 5.2.4, and 5.3.0) clobber the local
-- variables before the return hook is executed. As a consequence,
-- **Testy** saves the current state of the local variables on every
-- line using an additional line hook, and uses that saved information
-- in the return hook to identify test functions. Sadly that can be
-- very inefficient, especially if the code executes a lot of lines
-- (e.g. using a loop), but top level module code normally doesn't do
-- that (it usually contains mostly function definitions). The test
-- functions themselves are executed without debug hooks and thus run
-- at full speed, so if you need to run a lot of code to prepare your
-- test cases, better move that code into the first test function.
local function line_ret_hook( event, no )
  if event ~= "tail_return" and main_chunk( 2 ) then
    local info = debug.getinfo( 2, "Sf" )
    if event == "line" then
      local locs = {}
      local i, name, value = 2, debug.getlocal( 2, 1 )
      while name do
        if #name >= #prefix and
           type( value ) == "function" and
           name:sub( 1, #prefix ) == prefix then
          local caption = name:sub( #prefix+1 ):gsub( "_", " " )
          local tdata = {
            caption = caption,
            name = name,
            func = value,
            source = info.short_src,
          }
          locs[ #locs+1 ] = tdata
        end
        i, name, value = i+1, debug.getlocal( 2, i )
      end
      locals[ info.func ] = locs
    else -- return hook
      for _,tdata in ipairs( locals[ info.func ] or {} ) do
        tests[ #tests+1 ] = tdata
        test_functions[ tdata.func ] = tdata
      end
    end
  end
end


-- When using the line hook to collect local variables, under some
-- circumstances the last local isn't picked up when the definition
-- is the last statement in the chunk. To circumvent that problem
-- this function first tries to load the code with an extra `return`
-- statement appended. Only if that fails (which it will if the code
-- already contains a final `return`), the original code is loaded.
-- Obviously this approach will fail when loading binary chunks, so
-- this is currently unsupported in **Testy** (although it will work
-- in most cases).
local function loadfile_with_extra_return( fname )
  local f, msg = io.open( fname, "rb" )
  if not f then
    return nil, msg
  end
  local s = f:read( "*a" )
  if not s then
    return nil, "input/ouput error"
  end
  -- `loadstring`/`load` won't handle shebang lines like `loadfile`
  -- does, so the shebang line has to be removed.
  s = s:gsub( "^#[^\n]*", "") .. "\nreturn\n"
  local c, msg = (loadstring or load)( s, "@"..fname )
  if c then
    return c
  else
    return loadfile( fname )
  end
end


-- The enhanced/modified Lua searcher below needs the [standard Lua
-- function `package.searchpath`][6] available in Lua 5.2+ to locate
-- Lua files. For Lua 5.1 a backport is provided:
--
--   [6]: http://www.lua.org/manual/5.2/manual.html#pdf-package.searchpath
local searchpath = package.searchpath
if not searchpath then
  local delim = package.config:match( "^(.-)\n" ):gsub( "%%", "%%%%" )

  function searchpath( name, path )
    local pname = name:gsub( "%.", delim ):gsub( "%%", "%%%%" )
    local msg = {}
    for subpath in path:gmatch( "[^;]+" ) do
      local fpath = subpath:gsub( "%?", pname )
      local f = io.open( fpath, "r" )
      if f then
        f:close()
        return fpath
      end
      msg[ #msg+1 ] = "\n\tno file '"..fpath.."'"
    end
    return nil, table.concat( msg )
  end
end


-- The issue about the missing last local definition in chunks also
-- applies to modules in case there is no explicit `return` statement
-- (which could be for a module using the deprecated `module` function
-- or a reimplementation thereof). The following replacement function
-- of the [standard Lua module searcher][7] uses the above mentioned
-- `loadfile_with_extra_return` to fix that.
--
--   [7]: http://www.lua.org/manual/5.2/manual.html#pdf-package.searchers
local function lua_searcher( modname )
  assert( type( modname ) == "string" )
  local fn, msg = searchpath( modname, package.path )
  if not fn then
    return msg
  end
  local mod, msg = loadfile_with_extra_return( fn )
  if not mod then
    error( "error loading module '"..modname.."' from file '"..fn..
           "':\n\t"..msg, 0 )
  end
  return mod, fn
end


-- The command line of `testy.lua` is inspected to collect command
-- line flags (currently only `-r` and `-t`) and all module/test files
-- that should be tested.
for i,a in ipairs( _G.arg ) do
  -- The `-r` command line flag causes **Testy** to collect the local
  -- test functions not only from the loaded files directly, but also
  -- recursively from `require`d modules.
  --
  -- The `-t` command line flag causes **Testy** to write out
  -- [TAP](http://testanything.org/tap-specification.html)-formatted
  -- output to the standard output stream. This way you can use
  -- other reporting tools like e.g. `prove`:
  --
  --     prove --exec "testy.lua -t" module1.lua
  if a == "-r" then
    do_recursive = true
  elseif a == "-t" then
    do_tap = true
    fh = io.stdout
  else
    files[ #files+1 ] = a
  end
  -- The arguments intended for the `testy.lua` script are removed
  -- from the `arg` table in case one of the loaded files also tries
  -- to process command line arguments.
  _G.arg[ i ] = nil
end

-- All collected module/test files are loaded and checked for syntax
-- errors. Errors at this stage are considered fatal and thus
-- terminate the test session.
for i,f in ipairs( files ) do
  chunks[ i ] = assert( loadfile_with_extra_return( f ) )
end

-- If the `-r` command line flag is in effect, the fix to `loadfile`
-- needs to be applied to `require`d modules as well. This is done by
-- replacing the standard Lua searcher function with the fixed
-- version from above.
if do_recursive then
  local searchers = package.searchers or package.loaders
  local off = 0
  if package.loaded[ "luarocks.loader" ] then off = 1 end
  assert( #searchers == 4+off, "package.searchers has been modified" )
  searchers[ 2+off ] = lua_searcher
end

-- Every loaded chunk is executed with a line and return hook enabled.
-- The line/return hook is responsible for collecting the test
-- functions.
for i,c in ipairs( chunks ) do
  -- `arg[0]` is set to the name of the loaded file to pretend as if
  -- the loaded file was executed by the standalone `lua` interpreter.
  -- This probably is unnecessary since usually only modules or
  -- specialized test scripts are tested using **Testy**, but some
  -- script might attempt to parse the `arg` table.
  _G.arg[ 0 ] = files[ i ]
  -- The monky-patched version of `assert` is made available here
  -- already in case the module code stores global functions in
  -- upvalues.
  _G.assert = _G_assert
  debug.sethook( line_ret_hook, "lr" )
  -- The chunk is called as if loaded by the `require` function: A
  -- (fake) module name and the file location are passed as
  -- parameters. Errors during loading of the module code are also
  -- considered fatal and thus terminate the testing session.
  c( "module.test", files[ i ] )
  debug.sethook()
end

-- After all module/test files have been loaded and executed, the debug
-- hooks should have collected all local test functions from the main
-- chunks of the given files. Now those test functions are called to
-- actually run the tests.
for _,t in ipairs( tests ) do
  -- A nice caption for the test function is derived from the function
  -- name by stripping the `test_` prefix and replacing all
  -- underscores with spaces.
  if do_tap then
    fh:write( "# ", t.caption, " ('", t.source, "')\n" )
  else
    local headerlen = #t.caption + #t.source + #gap + 5
    fh:write( t.caption, " ('", t.source, "')" )
    if headerlen >= max_line then
      fh:write( "\n" )
    else
      fh:write( gap )
      cursor_pos = headerlen
    end
  end
  fh:flush()
  -- The modified `assert` function and the new `testy_assert` are
  -- made available to the test functions. This happens before every
  -- test in case some module author messes with them.
  _G.assert = _G_assert
  _G.testy_assert = _G_testy_assert
  -- The test functions are called with `debug.traceback` as error
  -- message handler, so that unhandled errors in test functions can
  -- be reported with stack traces.
  local ok, msg = xpcall( t.func, debug.traceback )
  -- After each test function a new line is started no matter what
  -- output the `assert`s in the test function produced.
  if cursor_pos ~= 0 then
    fh:write( "\n" )
    cursor_pos = 0
  end
  if not ok then
    -- Unhandled errors are reported here, including stack traces.
    -- Unhandled errors are considered bugs and should be fixed as
    -- soon as possible, because they prevent the following test
    -- assertions in the same test function from executing.
    n_errors = n_errors + 1
    if do_tap then
      fh:write( "# [ERROR] test function '", t.name, "' died:\n#  ",
                msg:gsub( "\n", "\n#  " ), "\n" )
    else
      fh:write( "  [ERROR] test function '", t.name, "' died:\n  ",
                msg:gsub( "\n", "\n  " ), "\n" )
    end
  else
    if not do_tap then
      -- In case there were test failures during the execution of this
      -- test function, the details of those failures are written now.
      -- For the TAP output the failure details were printed already.
      for _,f in ipairs( t ) do
        fh:write( "  [FAIL] ", t.source, ":", f.line,
                  ": in function '", t.name, "'\n" )
        if f.reason then
          fh:write( "    reason: \"", f.reason, "\"\n" )
        end
      end
    end
  end
  fh:flush()
end

if do_tap then
  -- For the TAP output the "test plan" is written out. Any unhandled
  -- error during the test run is considered a missing test.
  fh:write( "1..", n_tests+n_errors, "\n" )
else
  -- Finally, the combined test results are printed.
  fh:write( n_tests, " tests (", n_passed, " ok, ", n_tests-n_passed,
            " failed, ", n_errors, " errors)\n" )
end
fh:flush()
-- In case there were test failures or even unhandled errors in the
-- test functions, the `testy.lua` script exits with a non-zero
-- exit status.
if n_tests ~= n_passed or n_errors > 0 then
  os.exit( 1, true )
end

