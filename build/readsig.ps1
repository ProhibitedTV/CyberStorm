Add-Type -AssemblyName System.Drawing
$bmp=[System.Drawing.Bitmap]::FromFile('C:\Users\RhythmicCarnage\Desktop\CyberStorm\build\frontend-verify\frontend-verify-title-to-start-pass.png')
function Convert-Vga([int]$v){ [int][Math]::Round(($v*255.0)/63.0) }
$on = @{ R = (Convert-Vga 63); G = (Convert-Vga 63); B = (Convert-Vga 63) }
$off = @{ R = (Convert-Vga 8); G = (Convert-Vga 14); B = (Convert-Vga 22) }
function Dist($c,$r){ $dr=$c.R-$r.R; $dg=$c.G-$r.G; $db=$c.B-$r.B; return ($dr*$dr)+($dg*$dg)+($db*$db) }
function Px([double]$lx,[double]$ly){
  $x=[int][Math]::Floor(((($lx+0.5)*$bmp.Width)/320))
  if($x -lt 0){$x=0}; if($x -ge $bmp.Width){$x=$bmp.Width-1}
  $y=[int][Math]::Floor(((($ly+0.5)*$bmp.Height)/200))
  if($y -lt 0){$y=0}; if($y -ge $bmp.Height){$y=$bmp.Height-1}
  return $bmp.GetPixel($x,$y)
}
function ReadSig([int]$sy){
  $value=0
  for($bit=0;$bit -lt 16;$bit++){
    $sample=Px (92+($bit*6)+2) ($sy+2)
    $isSet=(Dist $sample $on) -lt (Dist $sample $off)
    if($isSet){ $value = $value -bor (0x8000 -shr $bit) }
  }
  return $value
}
$exp = ReadSig 128
$obs = ReadSig 136
Write-Output ('expected=0x{0:X4}' -f $exp)
Write-Output ('observed=0x{0:X4}' -f $obs)
$bmp.Dispose()
