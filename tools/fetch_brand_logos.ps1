# Downloads the brand marks used by web_profile/index.html and inlines them
# between the /* LOGOS:START */ and /* LOGOS:END */ markers, so the page stays a
# single self-contained file (no CDN call at runtime).
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools/fetch_brand_logos.ps1
Add-Type -AssemblyName System.Web
$root = Split-Path -Parent $PSScriptRoot
$page = Join-Path $root 'web_profile\index.html'
if (-not (Test-Path $page)) { throw "Missing $page" }
# slug => brand hex colour used by simple-icons
$brands = [ordered]@{
    linkedin  = '0A66C2'
    instagram = 'E1306C'
    x         = '111111'
    facebook  = '1877F2'
    github    = '181717'
    tiktok    = '111111'
    youtube   = 'FF0000'
    whatsapp  = '25D366'
    telegram  = '26A5E4'
    threads   = '111111'
    snapchat  = '111111'
}
$lines = @()
foreach ($slug in $brands.Keys) {
    $url = "https://cdn.jsdelivr.net/npm/simple-icons@13/icons/${slug}.svg"
    try {
        $svg = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30).Content
    } catch {
        throw "Could not download $url - $($_.Exception.Message)"
    }
    $svg = ($svg -replace '<title>.*?</title>', '')
    $svg = ($svg -replace '<svg ', "<svg fill=`"#$($brands[$slug])`" ")
    $svg = (($svg -replace '\r?\n', ' ') -replace '\s+', ' ').Trim()
    if ($svg -notmatch '^<svg') { throw "Unexpected response for $slug" }
    # Embed as a single-quoted JS string.
    $escaped = $svg.Replace('\', '\\').Replace("'", "\'")
    $lines += "      ${slug}: '$escaped',"
}
$html = [IO.File]::ReadAllText($page)
$start = '/* LOGOS:START */'
$end = '/* LOGOS:END */'
$i = $html.IndexOf($start)
$j = $html.IndexOf($end)
if ($i -lt 0 -or $j -lt 0 -or $j -lt $i) { throw 'LOGOS markers not found in index.html' }
$before = $html.Substring(0, $i + $start.Length)
$after = $html.Substring($j)
$html = $before + "`r`n" + ($lines -join "`r`n") + "`r`n      " + $after
[IO.File]::WriteAllText($page, $html, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "Inlined $($brands.Count) brand logos into web_profile/index.html"
