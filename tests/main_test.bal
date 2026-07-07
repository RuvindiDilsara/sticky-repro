import ballerina/test;

// Smoke test — confirms the package runs.
@test:Config {}
function smokeTest() {
    string ts = nowUtc();
    test:assertTrue(ts.length() > 0, "timestamp should not be empty");
}

// Intentionally-failing test, ONLY to force the unit-test phase to exit non-zero
// so Devant surfaces the unit-test runner logs. Look at the dependency resolution
// printed ABOVE this in the unit-test log: `ballerina/time` resolves to the LATEST
// patch (e.g. 2.8.1) here, even though the committed Dependencies.toml locks 2.8.0
// and Ballerina.toml has `sticky = true`. The build log resolves 2.8.0.
// Remove this test once you've captured the logs.
@test:Config {}
function forceFailToSurfaceRunnerLogs() {
    test:assertFail("INTENTIONAL FAIL: inspect the dependency resolution above — " +
        "ballerina/time drifted to the latest patch in the unit-test runner " +
        "(committed lock = 2.8.0). This proves the runner ignores the lock.");
}
