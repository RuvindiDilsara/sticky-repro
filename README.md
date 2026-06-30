# Devant dependency-locking reproducer (build vs unit-test)

Demonstrates: the **build** phase honors the pinned/locked dependency (`bal build --sticky`)
while the **unit-test** phase ignores it (`bal test --sticky=false`, in
`choreo-unit-test-runner/.../ballerina/test.sh`), so the two phases resolve **different**
versions of the same dependency for the same commit.

## What is pinned
- `ballerina/time` is pinned to **2.8.0** in BOTH `Ballerina.toml` (`[[dependency]]`) **and**
  the committed `Dependencies.toml`. A newer patch (**2.8.1**) exists on Central for 2201.13.x.
- The `[[dependency]]` pin is the important bit: it makes the **build** hold 2.8.0 *even if
  `Dependencies.toml` does not reach the build workspace*. (We observed a Devant build drift
  when only the lockfile pinned the version — the lockfile wasn't effective at the path `bal`
  ran in. The `[[dependency]]` pin removes that dependence.)

## How to reproduce in Devant
1. Push this package to a repo, create a Ballerina component from it. Ensure the whole package
   directory (incl. `Ballerina.toml` and `Dependencies.toml`) is committed in the SAME folder.
2. Trigger a **Build** and a **Unit Test** (or a build with unit tests enabled).
3. Compare dependency resolution in the two logs:
   - **Build log** → `ballerina/time:2.8.0 pulled ...`, Final graph `time:2.8.0`  ✅ honors the pin
   - **Unit-test log** → `ballerina/time:2.8.1 pulled ...`, Final graph `time:2.8.1`  ❌ ignores it

The `tests/main_test.bal` includes an intentionally-failing test so the unit-test phase exits
non-zero (code 126) and Devant **surfaces the unit-test runner logs** where the drift is visible.
Remove it once you've captured the logs.

## Verified locally (Ballerina 2201.13.3, live Central)
| scenario | resolved `time` |
| --- | --- |
| `bal build --sticky`, lockfile present | **2.8.0** (held) |
| `bal build --sticky`, lockfile ABSENT  | **2.8.0** (held via `[[dependency]]` pin) |
| `bal test --test-report --sticky=false` | **2.8.1** (drifted) |

## Notes
- This shows the *drift*, not a crash. The real customer case (BISUB-52) additionally hit a
  breaking change shipped in a patch (`commons.util_lib 0.6.5 -> 0.6.9`), turning the drift into
  a compile error in the unit-test phase only.
- Keep `distribution` at 2201.13.2+ (so `time 2.8.1` is in range) and keep the pin at least one
  patch behind the latest compatible version.
