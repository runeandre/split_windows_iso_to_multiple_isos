Write-Host "#####################################################"
Write-Host "#                                                   #"
Write-Host "# Split Windows.iso into multiple single layer ISOs #"
Write-Host "#                                                   #"
Write-Host "#####################################################"
Write-Host " "

Write-Host "Current directory: $($PWD)"
Write-Host " "


Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');


### Settings ###
$oscdimg_32bit = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg\oscdimg.exe"
$oscdimg_64bit = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"

$folder_name_tmp = "tmp"
$folder_tmp = "$($PWD)\$($folder_name_tmp)"

$dvd_source_Windows = "Windows.iso"
$dvd_target_DVD1_UEFI = "Windows_DVD1_UEFI.iso"
$dvd_target_DVD2_UEFI = "Windows_DVD2_UEFI.iso"


### Install adksetup.exe to C:\ADK\ if oscdimg is missing ###
# For x86 32-bit systems
$oscdimg = $oscdimg_32bit

# For x86 64-bit systems
if ([Environment]::Is64BitProcess) {
    $oscdimg = $oscdimg_64bit
}

if (![System.IO.File]::Exists($oscdimg)) {
    Write-Host "Install adksetup.exe in order to get oscdimg.exe"

    # Download adksetup.exe
    if (![System.IO.File]::Exists("$($PWD)\adksetup.exe")) {
        Write-Host "Download missing adksetup.exe setup file"
        Invoke-WebRequest https://go.microsoft.com/fwlink/?linkid=2271337 -OutFile adksetup.exe
    }

    # Silent install of adksetup.exe and DeploymentTools
    Write-Host "Silent adksetup.exe install to 'C:\Program Files (x86)\Windows Kits\10\'"
    adksetup.exe /quiet /installpath "C:\Program Files (x86)\Windows Kits\10" /features OptionId.DeploymentTools
}
Write-Host "Location of oscdimg: $($oscdimg)"
Write-Host " "

### Delete old files and folders
Remove-Item "$($folder_tmp)\" -Recurse -Force -Confirm:$false
Remove-Item $dvd_target_DVD1_UEFI -Force -Confirm:$false
Remove-Item $dvd_target_DVD2_UEFI -Force -Confirm:$false


### Full path to the ISO file
$isoPath = "$($PWD)\$($dvd_source_Windows)"
Write-Host "ISO file: $($isoPath)"

### Unmount the ISO if already mounted
$isoDrive = Get-DiskImage -ImagePath $isoPath
$isoDrive | Dismount-DiskImage | Out-Null

### Mount ISO
$isoDrive = Mount-DiskImage -ImagePath $isoPath -PassThru | Get-Volume
Write-Host "ISO drive: $($isoDrive)"

### Get the DriveLetter currently assigned to the drive (a single [char])
$isoLetter = ($isoDrive | Get-Volume).DriveLetter
$isoDriveLetter = "$($isoLetter):\"
Write-Host "ISO drive letter: $($isoDriveLetter)"

### Create an empty tmp folder
mkdir "$($folder_tmp)"

### Copy CD content to the tmp\win_dvd1 folder
$folder_win_dvd1 = "$($folder_tmp)\win_dvd1\"
mkdir "$($folder_win_dvd1)"
Copy-item -Force -Recurse -Verbose "$($isoDriveLetter)*" -Destination "$($folder_win_dvd1)"

### Unmount ISO
$isoDrive = Get-DiskImage -ImagePath "$($isoPath)"
$isoDrive | Dismount-DiskImage | Out-Null

### Read Write permissions
attrib -r -h "$($folder_tmp)\*.*" /s /d

### Change Windows source files
# Move install.esd so we don't count it when checking used space
mv "$($folder_win_dvd1)sources\install.esd" "$($folder_tmp)\install.esd"

### Find DVD free space, so we know the maximum size of install.swm in order for it fit on a singel layer DVD.
$dvd1_used_space = (Get-ChildItem -Path $folder_win_dvd1 -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
$dvd_install_swm_size = 4400 - [Math]::Floor($dvd1_used_space) #Floor rounds the number down to a whole number 

Write-Host " "
Write-Host "DVD used space: $($dvd1_used_space)MB"
Write-Host "Max install.swm size: $($dvd_install_swm_size)MB"
Write-Host " "

### Convert install.esd into install.swm files in the DVD1 sources folder
Write-Host "The DISM ESD to SWM takes a while!"
Dism /Split-Image /ImageFile:"$($folder_tmp)\install.esd" /SWMFile:"$($folder_win_dvd1)sources\install.swm" /FileSize:"$($dvd_install_swm_size)"

### Delete the file tmp\install.esd
Remove-Item "$($folder_tmp)\install.esd" -Force -Confirm:$false

### Create DVD2 and move the second swm file
$folder_win_dvd2 = "$($folder_tmp)\win_dvd2\"
mkdir "$($folder_win_dvd2)sources"
mv "$($folder_win_dvd1)sources\install2.swm" "$($folder_win_dvd2)sources\install2.swm"

### Create UEFI ISOs ###
& $oscdimg -m -o -u2 -udfver102 -bootdata:2#p0,e,b"$($folder_win_dvd1)boot\etfsboot.com"#pEF,e,b"$($folder_win_dvd1)efi\microsoft\boot\efisys.bin" "$($folder_win_dvd1)" "$($PWD)\$dvd_target_DVD1_UEFI"
& $oscdimg -m -o -u2 -udfver102 "$($folder_win_dvd2)" "$($PWD)\$dvd_target_DVD2_UEFI"

### Finished
Write-Host " "
Write-Host "Finished creating the Windows ISOs!"
Write-Host "Windows DVD1 UEFI: $($PWD)\$dvd_target_DVD1_UEFI"
Write-Host "Windows DVD2 UEFI: $($PWD)\$dvd_target_DVD2_UEFI"

### Tips / How tos
Write-Host "

### HOW TO: Setting up a Local account on Windows 11 ###
1. Start Windows setup without internet connected (Disconnect ethernet cable or don't login to Wifi)
2. Follow the Windows 11 installation until 'choose the country' screen.
3. Press: Shift + F10
4. Run the command: OOBE\BYPASSNRO
5. The PC will now reboot and the setup restart
6. When you reach the 'Let's connect you to a network', select 'I don't have internet' and 'Continue with limited setup'.
7. Follow the screens and finish the installation.
"