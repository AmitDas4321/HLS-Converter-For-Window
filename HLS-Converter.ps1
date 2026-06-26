Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


$form = New-Object System.Windows.Forms.Form
$form.Text = "HLS Converter"
$form.Size = New-Object System.Drawing.Size(700,330)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI",10)



# Input File

$fileBox = New-Object System.Windows.Forms.TextBox
$fileBox.Location = New-Object System.Drawing.Point(20,40)
$fileBox.Size = New-Object System.Drawing.Size(400,25)
$form.Controls.Add($fileBox)


$browse = New-Object System.Windows.Forms.Button
$browse.Text = "Browse"
$browse.Location = New-Object System.Drawing.Point(450,40)
$browse.Size = New-Object System.Drawing.Size(100,25)

$browse.Add_Click({

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Video Files|*.mkv;*.mp4;*.mov;*.avi;*.webm"

    if($dialog.ShowDialog() -eq "OK"){
        $fileBox.Text = $dialog.FileName
    }

})

$form.Controls.Add($browse)



# Output Folder

$label = New-Object System.Windows.Forms.Label
$label.Text = "Output Folder Name"
$label.Location = New-Object System.Drawing.Point(20,90)
$form.Controls.Add($label)



$folderBox = New-Object System.Windows.Forms.TextBox
$folderBox.Location = New-Object System.Drawing.Point(20,120)
$folderBox.Size = New-Object System.Drawing.Size(400,25)
$form.Controls.Add($folderBox)




# Quality Section

$qualityGroup = New-Object System.Windows.Forms.GroupBox
$qualityGroup.Text = "Select Qualities"
$qualityGroup.Location = New-Object System.Drawing.Point(470,90)
$qualityGroup.Size = New-Object System.Drawing.Size(190,170)

$form.Controls.Add($qualityGroup)



$cb1080 = New-Object System.Windows.Forms.CheckBox
$cb1080.Text = "1080p"
$cb1080.Checked = $true
$cb1080.AutoSize = $true
$cb1080.Location = New-Object System.Drawing.Point(20,30)
$qualityGroup.Controls.Add($cb1080)



$cb720 = New-Object System.Windows.Forms.CheckBox
$cb720.Text = "720p"
$cb720.Checked = $true
$cb720.AutoSize = $true
$cb720.Location = New-Object System.Drawing.Point(20,60)
$qualityGroup.Controls.Add($cb720)



$cb480 = New-Object System.Windows.Forms.CheckBox
$cb480.Text = "480p"
$cb480.Checked = $true
$cb480.AutoSize = $true
$cb480.Location = New-Object System.Drawing.Point(20,90)
$qualityGroup.Controls.Add($cb480)



$cb360 = New-Object System.Windows.Forms.CheckBox
$cb360.Text = "360p"
$cb360.Checked = $true
$cb360.AutoSize = $true
$cb360.Location = New-Object System.Drawing.Point(100,30)
$qualityGroup.Controls.Add($cb360)



$cb240 = New-Object System.Windows.Forms.CheckBox
$cb240.Text = "240p"
$cb240.Checked = $true
$cb240.AutoSize = $true
$cb240.Location = New-Object System.Drawing.Point(100,60)
$qualityGroup.Controls.Add($cb240)





# Start Button

$start = New-Object System.Windows.Forms.Button
$start.Text = "Start Convert"
$start.Location = New-Object System.Drawing.Point(20,200)
$start.Size = New-Object System.Drawing.Size(150,40)



$start.Add_Click({


$inputFile = $fileBox.Text


if(-not $inputFile){

[System.Windows.Forms.MessageBox]::Show(
"Please select video file"
)

return

}



if($folderBox.Text){

$folderName = $folderBox.Text

}

else{

$folderName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
$folderName = $folderName -replace '[^a-zA-Z0-9\-]','-'

}



$basePath = Split-Path $inputFile

$out = Join-Path $basePath $folderName


New-Item -ItemType Directory -Force $out | Out-Null





$presets = @(

@{name="1080p";scale="1920:1080";bitrate="5000k"}

@{name="720p";scale="1280:720";bitrate="2500k"}

@{name="480p";scale="854:480";bitrate="1200k"}

@{name="360p";scale="640:360";bitrate="700k"}

@{name="240p";scale="426:240";bitrate="400k"}

)



$selected=@()



if($cb1080.Checked){$selected += $presets[0]}
if($cb720.Checked){$selected += $presets[1]}
if($cb480.Checked){$selected += $presets[2]}
if($cb360.Checked){$selected += $presets[3]}
if($cb240.Checked){$selected += $presets[4]}



if($selected.Count -eq 0){

[System.Windows.Forms.MessageBox]::Show(
"Select at least one quality"
)

return

}




$count=$selected.Count



if($count -eq 1){

$filter="[0:v]scale=$($selected[0].scale)[v0]"

}

else{


$split=""

for($i=0;$i -lt $count;$i++){

$split+="[s$i]"

}


$filter="[0:v]split=$count$split;"


for($i=0;$i -lt $count;$i++){

$filter+="[s$i]scale=$($selected[$i].scale)[v$i];"

}


$filter=$filter.TrimEnd(";")

}





$args=@()

$args += "-y"
$args += "-i"
$args += $inputFile


$args += "-filter_complex"
$args += $filter



$map=""



for($i=0;$i -lt $count;$i++){


$args += "-map"
$args += "[v$i]"


$args += "-map"
$args += "0:a"


$args += "-b:v:$i"
$args += $selected[$i].bitrate


$map+="v:$i,a:$i,name:$($selected[$i].name) "

}



$args += "-c:v"
$args += "libx264"


$args += "-preset"
$args += "medium"


$args += "-profile:v"
$args += "main"


$args += "-pix_fmt"
$args += "yuv420p"


$args += "-c:a"
$args += "aac"


$args += "-b:a"
$args += "128k"


$args += "-f"
$args += "hls"


$args += "-hls_time"
$args += "6"


$args += "-hls_playlist_type"
$args += "vod"


$args += "-master_pl_name"
$args += "master.m3u8"


$args += "-var_stream_map"
$args += $map.Trim()



$args += "-hls_segment_filename"
$args += (Join-Path $out "%v\segment_%05d.ts")


$args += (Join-Path $out "%v\playlist.m3u8")



$form.Hide()


ffmpeg @args



[System.Windows.Forms.MessageBox]::Show(
"HLS Conversion Complete"
)



$form.Close()



})



$form.Controls.Add($start)



[void]$form.ShowDialog()