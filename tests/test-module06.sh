#!/bin/sh

PASS=0
FAIL=0

pass() {
    echo "[PASS] $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "[FAIL] $1"
    FAIL=$((FAIL + 1))
}

echo "======================================="
echo " CustomIoT Linux - Module 06 Tests"
echo "======================================="

# Test 1: Root mounted read-only
if awk '
    $2 == "/" {
        n = split($4, opts, ",")
        for (i = 1; i <= n; i++)
            if (opts[i] == "ro")
                found = 1
    }
    END { exit !found }
' /proc/mounts; then
    pass "Root filesystem read-only"
else
    fail "Root filesystem read-only"
fi

# Test 2: Root write protection
if touch /etc/customiot/module06-write-test \
    2>/dev/null; then

    rm -f /etc/customiot/module06-write-test
    fail "Root write protection"
else
    pass "Root write protection"
fi

# Test 3: OverlayFS mounted
if awk '
    $2 == "/var/lib/customiot" && $3 == "overlay" {
        found = 1
    }
    END { exit !found }
' /proc/mounts; then
    pass "Application OverlayFS"
else
    fail "Application OverlayFS"
fi

# Test 4: Overlay writable
if echo "module06" \
    > /var/lib/customiot/test-module06.txt; then

    pass "Writable application state"
else
    fail "Writable application state"
fi

# Test 5: Lower layer available
if [ -f \
    /var/lib/customiot/factory-info.txt ]; then

    pass "Read-only lower layer"
else
    fail "Read-only lower layer"
fi

# Test 6: Service account exists
if id customiot >/dev/null 2>&1; then
    pass "Dedicated service account"
else
    fail "Dedicated service account"
fi

# Test 7: UART restricted
if [ -c /dev/ttyS1 ] &&
   ls -l /dev/ttyS1 | awk '
       $1 == "crw-rw----" &&
       $3 == "root" &&
       $4 == "customiot" {
           valid = 1
       }
       END {
           exit !valid
       }
   '
then
    pass "Restricted UART permissions"
else
    fail "Restricted UART permissions"
fi

# Test 8: Gateway running
if /etc/init.d/S95customiot status \
    >/dev/null 2>&1; then

    pass "Gateway service running"
else
    fail "Gateway service running"
fi

# Test 9: Gateway runs as customiot
PID="$(pidof gateway-supervisor 2>/dev/null | awk '{print $1}')"

if [ -n "$PID" ] &&
   [ "$(awk '/^Uid:/ {print $2}' /proc/"$PID"/status)" = "450" ]; then

    pass "Gateway running without root"
else
    fail "Gateway running without root"
fi

# Test 10: Application configuration exists
if [ -f /etc/customiot/customiot.conf ]; then
    pass "Application configuration"
else
    fail "Application configuration"
fi

echo
echo "======================================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "======================================="

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

echo "Module 06 security tests passed"
