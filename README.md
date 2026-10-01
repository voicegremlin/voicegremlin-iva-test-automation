# VoiceGremlin CI Scripts

CI/CD testing for AI voice agents. Drop one of these scripts into your pipeline and get pass/fail on your voice agent's behavior.

## Usage

**Bash (Linux/macOS/GitHub Actions):**

```bash
curl -sSf https://raw.githubusercontent.com/voicegremlin/voicegremlin-iva-test-automation/main/voicegremlin-ci.sh -o voicegremlin-ci.sh && chmod +x voicegremlin-ci.sh && VGM_KEY="vg_live_xxx" ./voicegremlin-ci.sh "My Company" "+10010010001" "Verify that the agent discloses its AI status and audio recording on the first message"
```

**PowerShell (Windows):**

```powershell
irm https://raw.githubusercontent.com/voicegremlin/voicegremlin-iva-test-automation/main/ci.ps1 | Invoke-Expression
# Set $env:VGM_KEY, $env:TARGET, $env:TESTS before running
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `VGM_KEY` | Yes | Your VoiceGremlin API key |
| `TARGET` | Yes | Phone number of your voice agent |
| `TESTS` | Yes | JSON array of test goals (1-20 strings) |
| `TARGET_NAME` | No | Your business name (improves test persona) |
| `RUN_ID` | No | Custom identifier for this test batch |
| `TIMEOUT` | No | Poll timeout in seconds (default: 300) |

## Exit Codes

- `0` — All tests passed
- `1` — One or more tests failed
- `2` — API/polling error (timeout, auth, etc.)

## Learn More

- **Docs & API Reference:** https://voicegremlin.com/docs.html
- **Quick Start:** https://voicegremlin.com/quick-start.html
- **Pricing:** https://voicegremlin.com/pricing.html
- **LLM-readable product spec:** [llms.txt](./llms.txt)
