# VoiceGremlin CI Check
# Usage: $env:VGM_KEY="vg_xxx"; ./voicegremlin-ci.ps1 -Target "SkyWay Airlines" -Phone "+15551234567" -Tests "Goal 1", "Goal 2"
param(
  [Parameter(Mandatory)][string]$Target,
  [Parameter(Mandatory)][string]$Phone,
  [string[]]$Tests = @("Verify the Agent discloses it is AI"),
  [int]$MaxConcurrency = 1
)

$VGM_KEY = $env:VGM_KEY
if (-not $VGM_KEY) { Write-Error "Set VGM_KEY environment variable"; exit 1 }
$BaseUrl = if ($env:BASE_URL) { $env:BASE_URL } else { "https://voicegremlin.com" }

# ── Queue the test ──────────────────────────────────────────
$body = @{
  target_name = $Target
  phone_number = $Phone
  tests = $Tests
  max_concurrency = $MaxConcurrency
} | ConvertTo-Json

$resp = Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/runs" `
  -Headers @{ Authorization = "Bearer $VGM_KEY" } `
  -ContentType "application/json" `
  -Body $body

$runId = $resp.run_id
Write-Host "Queued: $runId ($($Tests.Count) test(s))"

# ── Poll until complete (timeout: 5 min) ────────────────────
$deadline = (Get-Date).AddMinutes(5)
$result = $null
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 10
  $result = Invoke-RestMethod -Uri "$BaseUrl/api/runs/$runId" `
    -Headers @{ Authorization = "Bearer $VGM_KEY" }
  if ($result.status -eq "complete") { break }
}

if (-not $result -or $result.status -ne "complete") {
  Write-Error "Timeout waiting for run $runId"
  exit 1
}

# ── Report results ──────────────────────────────────────────
Write-Host ""
Write-Host "Results: $($result.passed)/$($result.total) passed"

if ($result.failed -gt 0) {
  Write-Host ""
  Write-Host "❌ $($result.failed) test(s) failed:"
  $result.results | Where-Object { $_.status -eq "failed" } | ForEach-Object {
    Write-Host "  ✗ $($_.test_goal): $($_.reason)"
  }
  exit 1
}

Write-Host "✅ All tests passed"
exit 0
