Function Test-Command-Exists() {
  Param([string]$command)
  try {
    Get-Command $command -ErrorAction "Stop" > $null
    return $True
  } catch {
    return $False
  }
}

& {
  Update-Help
}