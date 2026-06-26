Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


$form = New-Object System.Windows.Forms.Form
$form.Text = "HLS Converter"
$form.Size = New-Object System.Drawing.Size(550,300)
$form.StartPosition = "CenterScreen"




$fileBox = New-Object System.Windows.Forms.TextBox
$fileBox.Location = New-Object System.Drawing.Point(20,40)
$fileBox.Size = New-Object System.Drawing.Size(360,25)
$form.Controls.Add($fileBox)



$browse = New-Object System.Windows.Forms.Button
$browse.Text = "Browse"
$browse.Location = New-Object System.Drawing.Point(400,40)
$browse.Size = New-Object System.Drawing.Size(100,25)


$browse.Add_Click({

$dialog = New-Object System.Windows.Forms.OpenFileDialog

$dialog.Filter = "Video Files|*.mkv;*.mp4;*.mov;*.avi;*.webm"


if($dialog.ShowDialog() -eq "OK"){

$fileBox.Text = $dialog.FileName

}

})


$form.Controls.Add($browse)



$label = New-Object System.Windows.Forms.Label
$label.Text="Output Folder Name"
$label.Location=New-Object System.Drawing.Point(20,90)
$form.Controls.Add($label)



$folderBox = New-Object System.Windows.Forms.TextBox
$folderBox.Location=New-Object System.Drawing.Point(20,120)
$folderBox.Size=New-Object System.Drawing.Size(360,25)
$form.Controls.Add($folderBox)




$start = New-Object System.Windows.Forms.Button
$start.Text="Start Convert"
$start.Location=New-Object System.Drawing.Point(20,180)
$start.Size=New-Object System.Drawing.Size(120,35)



$start.Add_Click({


$inputFile=$fileBox.Text


if(!$inputFile){

return

}



if($folderBox.Text){

$folderName=$folderBox.Text

}
else{

$folderName=[System.IO.Path]::GetFileNameWithoutExtension($inputFile)

$folderName=$folderName -replace '[^a-zA-Z0-9\-]','-'

}



$basePath = Split-Path $inputFile


$out = Join-Path $basePath $folderName



New-Item -ItemType Directory -Force $out | Out-Null



$form.Dispose()

Start-Sleep -Milliseconds 500



Write-Host ""
Write-Host "======================"
Write-Host "HLS CONVERSION START"
Write-Host $out
Write-Host "======================"
Write-Host ""





$args = @(

"-y",

"-i",
$inputFile,


"-filter_complex",
"[0:v]split=5[v1][v2][v3][v4][v5];[v1]scale=1920:1080[v1080];[v2]scale=1280:720[v720];[v3]scale=854:480[v480];[v4]scale=640:360[v360];[v5]scale=426:240[v240]",



"-map","[v1080]",
"-map","0:a",

"-map","[v720]",
"-map","0:a",

"-map","[v480]",
"-map","0:a",

"-map","[v360]",
"-map","0:a",

"-map","[v240]",
"-map","0:a",



"-c:v",
"libx264",

"-preset",
"medium",

"-profile:v",
"main",

"-pix_fmt",
"yuv420p",



"-b:v:0",
"5000k",

"-b:v:1",
"2500k",

"-b:v:2",
"1200k",

"-b:v:3",
"700k",

"-b:v:4",
"400k",



"-c:a",
"aac",

"-b:a",
"128k",



"-f",
"hls",

"-hls_time",
"6",

"-hls_playlist_type",
"vod",

"-hls_flags",
"independent_segments",



"-master_pl_name",
"master.m3u8",



"-var_stream_map",
"v:0,a:0,name:1080p v:1,a:1,name:720p v:2,a:2,name:480p v:3,a:3,name:360p v:4,a:4,name:240p",



"-hls_segment_filename",
"$out\%v\segment_%05d.ts",



"$out\%v\playlist.m3u8"

)



& ffmpeg @args





Write-Host ""
Write-Host "======================"
Write-Host "HLS DONE"
Write-Host "$out\master.m3u8"
Write-Host "======================"
Write-Host ""



Read-Host "Press ENTER to close terminal"



})



$form.Controls.Add($start)



[void]$form.ShowDialog()
