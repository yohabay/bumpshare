Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$res = Join-Path $root 'android\app\src\main\res'
$branding = Join-Path $root 'assets\branding'
New-Item -ItemType Directory -Force -Path $branding | Out-Null

function Draw-Glyph($g, [float]$size) {
    $scale = $size / 512.0
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $wavePen = [System.Drawing.Pen]::new([System.Drawing.Color]::White, [float](20 * $scale))
    $wavePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $wavePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $wavePen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round

    # Three NFC waves opening to the right.
    foreach ($r in 68, 108, 148) {
        $d = [float](2 * $r * $scale)
        $x = [float](70 * $scale)
        $y = [float](256 * $scale) - $d / 2
        $g.DrawArc($wavePen, $x, $y, $d, $d, 315, 90)
    }

    # Contact card.
    $cx = [float](232 * $scale); $cy = [float](172 * $scale)
    $cw = [float](196 * $scale); $ch = [float](168 * $scale)
    $rad = [float](26 * $scale)
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $path.AddArc($cx, $cy, $rad, $rad, 180, 90)
    $path.AddArc($cx + $cw - $rad, $cy, $rad, $rad, 270, 90)
    $path.AddArc($cx + $cw - $rad, $cy + $ch - $rad, $rad, $rad, 0, 90)
    $path.AddArc($cx, $cy + $ch - $rad, $rad, $rad, 90, 90)
    $path.CloseFigure()
    $g.DrawPath($wavePen, $path)

    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
    $g.FillEllipse($brush, [float]($cx + 32 * $scale), [float]($cy + 30 * $scale),
        [float](38 * $scale), [float](38 * $scale))

    $linePen = [System.Drawing.Pen]::new([System.Drawing.Color]::White, [float](13 * $scale))
    $linePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $linePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $g.DrawLine($linePen, [float]($cx + 30 * $scale), [float]($cy + 98 * $scale),
        [float]($cx + 158 * $scale), [float]($cy + 98 * $scale))
    $g.DrawLine($linePen, [float]($cx + 30 * $scale), [float]($cy + 128 * $scale),
        [float]($cx + 124 * $scale), [float]($cy + 128 * $scale))
}

function Save-Bitmap($bmp, [string]$path) {
    $dir = Split-Path -Parent $path
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
}

function Resize-Image([string]$src, [string]$dst, [int]$size) {
    $img = [System.Drawing.Image]::FromFile($src)
    $out = [System.Drawing.Bitmap]::new($size, $size)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.DrawImage($img, 0, 0, $size, $size)
    Save-Bitmap $out $dst
    $g.Dispose(); $out.Dispose(); $img.Dispose()
}

# Transparent adaptive foreground + purple composite for legacy launchers.
$fg = [System.Drawing.Bitmap]::new(512, 512)
$g = [System.Drawing.Graphics]::FromImage($fg)
$g.Clear([System.Drawing.Color]::Transparent)
Draw-Glyph $g 512
$g.Dispose()
$fgMaster = Join-Path $branding 'ic_launcher_foreground_master.png'
Save-Bitmap $fg $fgMaster

$legacy = [System.Drawing.Bitmap]::new(512, 512)
$g = [System.Drawing.Graphics]::FromImage($legacy)
$rect = [System.Drawing.Rectangle]::new(0, 0, 512, 512)
$grad = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    $rect,
    [System.Drawing.Color]::FromArgb(255, 124, 58, 237),
    [System.Drawing.Color]::FromArgb(255, 91, 33, 182),
    [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
$g.FillRectangle($grad, $rect)
Draw-Glyph $g 512
$g.Dispose()
$legacyMaster = Join-Path $branding 'ic_launcher_master.png'
Save-Bitmap $legacy $legacyMaster

$sizes = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
foreach ($density in $sizes.Keys) {
    $size = $sizes[$density]
    Resize-Image $legacyMaster (Join-Path $res "mipmap-$density\ic_launcher.png") $size
    Resize-Image $fgMaster (Join-Path $res "mipmap-$density\ic_launcher_foreground.png") ([int]($size * 2.25))
}

$fg.Dispose(); $legacy.Dispose()
Write-Output 'Launcher icons generated.'
