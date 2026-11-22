# Tiny local web server for the OBD dashboard (no installs needed).
# Web Bluetooth only works on http://localhost or https://, so the page is served here.
param([int]$Port = 8642, [switch]$NoBrowser)
$root = $PSScriptRoot
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "M5 OBD dashboard running at http://localhost:$Port/  (Ctrl+C or close this window to stop)"
if (-not $NoBrowser) { Start-Process "http://localhost:$Port/" }
$types = @{ '.html'='text/html; charset=utf-8'; '.js'='text/javascript'; '.css'='text/css'; '.json'='application/json'; '.png'='image/png'; '.svg'='image/svg+xml'; '.ico'='image/x-icon' }
try {
  while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
    if ($path -eq '') { $path = 'index.html' }
    $file = [IO.Path]::GetFullPath((Join-Path $root $path))
    if ($file.StartsWith($root) -and (Test-Path $file -PathType Leaf)) {
      $bytes = [IO.File]::ReadAllBytes($file)
      $ext = [IO.Path]::GetExtension($file).ToLower()
      $ctx.Response.ContentType = if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' }
      $ctx.Response.Headers.Add('Cache-Control', 'no-store')
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else { $ctx.Response.StatusCode = 404 }
    $ctx.Response.Close()
  }
} finally { $listener.Stop() }
