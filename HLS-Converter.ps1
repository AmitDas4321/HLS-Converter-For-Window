Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


$form = New-Object System.Windows.Forms.Form
$form.Text = "HLS Converter"
$form.Size = New-Object System.Drawing.Size(550,300)
$form.StartPosition = "CenterScreen"



# File box

$fileBox = New-Object System.Windows.Forms.TextBox
$fileBox.Location = New-Object System.Drawing.Point(20,40)
$fileBox.Size = New-Object System.Drawing.Size(360,25)
$form.Controls.Add($fileBox)



# Browse

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



# Folder name

$label = New-Object System.Windows.Forms.Label
$label.Text = "Output Folder Name"
$label.Location = New-Object System.Drawing.Point(20,90)
$form.Controls.Add($label)



$folderBox = New-Object System.Windows.Forms.TextBox
$folderBox.Location = New-Object System.Drawing.Point(20,120)
$folderBox.Size = New-Object System.Drawing.Size(360,25)
$form.Controls.Add($folderBox)



# Start

$start = New-Object System.Windows.Forms.Button
$start.Text = "Start Convert"
$start.Location = New-Object System.Drawing.Point(20,180)
$start.Size = New-Object System.Drawing.Size(120,35)



$start.Add_Click({


$inputFile = $fileBox.Text


if(!$inputFile){

[System.Windows.Forms.MessageBox]::Show("Select video")
return

}



if($folderBox.Text){

$folderName = $folderBox.Text

}
else{

$folderName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)

$folderName = $folderName -replace '[^a-zA-Z0-9\-]','-'

}



$base = Split-Path $inputFile


$outputFolder = Join-Path $base $folderName


$segmentFolder = Join-Path $outputFolder "segments"


New-Item -ItemType Directory -Force -Path $segmentFolder | Out-Null



$output = Join-Path $outputFolder "output.m3u8"


$segments = Join-Path $segmentFolder "segment_%05d.ts"



# Close GUI

$form.Close()



# Run FFmpeg in shell

ffmpeg -y `
-i "$inputFile" `
-c:v libx264 `
-preset medium `
-profile:v high `
-level 4.0 `
-pix_fmt yuv420p `
-c:a aac `
-b:a 128k `
-hls_time 6 `
-hls_playlist_type vod `
-hls_flags independent_segments `
-hls_base_url "segments/" `
-hls_segment_type mpegts `
-hls_start_number_source 0 `
-hls_segment_filename "$segments" `
-f hls `
"$output"



Read-Host "Press Enter to close"

})


$form.Controls.Add($start)


$form.ShowDialog()
