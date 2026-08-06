---
name: luarocks-test
description: Test luarocks packaging end-to-end without publishing. Use when writing or changing a rockspec, or before uploading a rock.
---

# Test a rockspec locally, no publish

Worked example: ezr-lua/ezr-3.0-1.rockspec.

    luarocks lint NAME-V.rockspec
    luarocks --tree ./lr-test make NAME-V.rockspec
    eval "$(luarocks --tree ./lr-test path)"
    export PATH=$PWD/lr-test/bin:$PATH
    cd /tmp        # CRITICAL: leave the repo dir
    lua -e 'print(require"NAME")'
    NAME --all     # installed bin scripts

Running from /tmp is the whole point: it proves require
wiring and data paths work without the repo accidentally
supplying files.

## Facts learned the hard way

- Module names may contain hyphens: `["ezr-lib"] =
  "ezr-lib.lua"` in build.modules; `require"ezr-lib"`
  works. A flat dir with hyphenated names is fine; no
  package subdir needed.
- Never publish a rock owning a generic module name like
  `lib` — namespace collision with everything.
- Generation/version goes in the rock version (ezr 3.0-1),
  not the package name.
- Bin scripts: luarocks wrappers keep arg[0] pointing
  inside the rock tree (<rock>/bin/script). So
  `copy_directories = {"data"}` lands at <rock>/data,
  which IS `../data/` relative to the script dir. A
  script-dir-relative data path with a `../` fallback
  works both in-repo and installed (see ezr-lib
  pathname()).
- `luarocks make` builds from cwd and ignores source.url;
  the url is only exercised by `luarocks build` /
  `install`, which need a pushed tag.
- Final packaging: `luarocks pack`, install the .src.rock
  into a second fresh tree. Publish: `luarocks upload`
  (needs API key). Check name is free first:
  luarocks.org/search.
