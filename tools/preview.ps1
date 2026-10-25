param([switch]$NoOpen)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$ui = Join-Path $repo 'usb/ui'
$manifests = @{}
Get-ChildItem (Join-Path $repo 'usb/tweaks') -Directory | ForEach-Object {
    $manifest = Join-Path $_.FullName 'manifest.conf'
    if (Test-Path -LiteralPath $manifest) {
        $manifests[$_.Name] = [System.IO.File]::ReadAllText($manifest)
    }
}
# Embed the real UI and manifests in a disposable, offline browser preview.
$json = ConvertTo-Json -InputObject $manifests -Compress
$json = $json.Replace('<', '\u003c')
$html = [System.IO.File]::ReadAllText((Join-Path $ui 'index-template.html'))
$css = [System.IO.File]::ReadAllText((Join-Path $ui 'style.css'))
$app = [System.IO.File]::ReadAllText((Join-Path $ui 'app.js'))
$mock = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'preview-bridge.js'))
$html = $html.Replace('<link rel="stylesheet" href="style.css">', "<style>$css</style>")
$html = $html.Replace('@ORIGIN@', 'preview').Replace('@TOKEN@', 'preview')
$html = $html.Replace('<script src="app.js"></script>', "<script>window.previewManifests=$json;</script><script>$mock</script><script>$app</script>")
$html = $html.Replace('<title>CMU Tweaks</title>', '<title>CMU Tweaks - OFFLINE PREVIEW</title>')
$previewPath = Join-Path ([System.IO.Path]::GetTempPath()) 'cmu-tweaks-preview.html'
[System.IO.File]::WriteAllText($previewPath, $html, (New-Object System.Text.UTF8Encoding($false)))
Write-Output $previewPath
if (-not $NoOpen) { Start-Process -FilePath $previewPath }
