# Devant dependency-locking reproducer (build vs unit-test)

Minimal Ballerina component that demonstrates: the **build** phase honors the committed
`Dependencies.toml` (`bal build --sticky`) while the **unit-test** phase ignores it
(`bal test --sticky=false`, in `choreo-unit-test-runner/.../ballerina/test.sh`), so the two
phases resolve **different** dependency versions for the same commit.

## What is pinned
- `ballerina/time` is locked to **2.8.0** in the committed `Dependencies.toml`
  (a newer patch, **2.8.1**, exists on Ballerina Central for distribution 2201.13.x).
- `Ballerina.toml` has `[build-options] sticky = true` — i.e. the developer explicitly asked
  for reproducible builds. The unit-test runner's `--sticky=false` overrides even this.

## How to reproduce in Devant
1. Push this package to a repo and create a Ballerina component from it.
2. Make sure `Dependencies.toml` is committed (it is here) and **`time` stays at `2.8.0`**.
3. Trigger a **Build** and a **Unit Test** (or a build with unit tests enabled).
4. Compare the dependency resolution in the two logs:
   - **Build log** → `ballerina/time:2.8.0 pulled ...` and Final graph shows `time:2.8.0`  ✅ honors the lock
   - **Unit-test log** → `ballerina/time:2.8.1 pulled ...` and Final graph shows `time:2.8.1`  ❌ ignores the lock

That difference is the bug: with `sticky = true` committed and `time` locked to `2.8.0`,
the unit-test runner still upgrades it to the latest patch.

## Verified locally (Ballerina 2201.13.3, against live Central)
| command (committed lock = time 2.8.0) | resolved `time` |
| --- | --- |
| `bal build --sticky`            (== buildpack `bin/build`)     | **2.8.0** (held) |
| `bal test --test-report --sticky=false` (== runner `test.sh:187`) | **2.8.1** (drifted) |

## Notes / tuning
- The point is *drift*, not a crash: the smoke test passes; you observe the version
  difference in the logs. (The real customer case additionally hit a breaking change that
  `commons.util_lib 0.6.9` shipped in a patch release, turning the drift into a compile error.)
- If `time` later gets a newer patch (e.g. 2.8.2), the unit-test phase will resolve that and the
  build will still resolve 2.8.0 — the drift still shows. Keep the committed lock at least one
  patch behind the latest **compatible** version for the distribution in `Ballerina.toml`.
- Keep `distribution` in `Ballerina.toml` at a value where a newer `time` patch is compatible
  (2201.13.2+). It is set to `2201.13.3` here.
