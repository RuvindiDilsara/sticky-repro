import ballerina/test;

@test:Config {}
function smokeTest() {
    string ts = nowUtc();
    test:assertTrue(ts.length() > 0, "timestamp should not be empty");
}
