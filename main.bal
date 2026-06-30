import ballerina/io;
import ballerina/time;

# Returns the current UTC time as a string.
public function nowUtc() returns string {
    time:Utc now = time:utcNow();
    return time:utcToString(now);
}

public function main() {
    io:println(nowUtc());
}
