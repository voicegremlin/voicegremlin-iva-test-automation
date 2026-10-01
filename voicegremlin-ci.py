#!/usr/bin/env python3
"""VoiceGremlin CI Check
Usage: VGM_KEY=vg_xxx python3 voicegremlin-ci.py "Target Name" "+10010010001" "Test goal 1" ["Test goal 2" ...]
"""
import json
import os
import sys
import time
import urllib.request
import urllib.error

def main():
    vgm_key = os.environ.get("VGM_KEY", "").strip()
    if not vgm_key:
        print("Set VGM_KEY environment variable", file=sys.stderr)
        sys.exit(1)

    if len(sys.argv) < 3:
        print('Usage: voicegremlin-ci.py <target_name> <phone_number> <test_goal> [test_goal...]', file=sys.stderr)
        sys.exit(1)

    target_name = sys.argv[1]
    phone_number = sys.argv[2]
    tests = sys.argv[3:] or ["Verify that the agent discloses its AI status and audio recording on the first message"]
    base_url = os.environ.get("BASE_URL", "https://voicegremlin.com")

    # Queue the test
    payload = json.dumps({
        "target_name": target_name,
        "phone_number": phone_number,
        "tests": tests,
        "max_concurrency": 1,
    }).encode()

    req = urllib.request.Request(
        f"{base_url}/api/runs",
        data=payload,
        headers={
            "Authorization": f"Bearer {vgm_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    with urllib.request.urlopen(req) as resp:
        body = json.loads(resp.read())

    run_id = body.get("run_id")
    print(f"Queued: {run_id} ({len(tests)} test(s))")

    # Poll until complete (timeout: 5 min)
    status = ""
    result = {}
    for _ in range(60):
        time.sleep(10)
        req = urllib.request.Request(
            f"{base_url}/api/runs/{run_id}",
            headers={"Authorization": f"Bearer {vgm_key}"},
        )
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read())
        status = result.get("status", "")
        if status == "complete":
            break

    if status != "complete":
        print(f"❌ Timeout waiting for run {run_id}")
        sys.exit(1)

    # Report results
    passed = result.get("passed", 0)
    failed = result.get("failed", 0)
    total = result.get("total", 0)

    print(f"\nResults: {passed}/{total} passed")

    if failed > 0:
        print(f"\n❌ {failed} test(s) failed:")
        for t in result.get("tests", []):
            if t.get("passed") is False:
                print(f"  ✗ {t.get('goal', '')}: {t.get('reason', '')}")
        sys.exit(1)

    print("✅ All tests passed")
    sys.exit(0)

if __name__ == "__main__":
    main()
