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
Write-Host " "


### Settings ###
$oscdimg_32bit = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg\oscdimg.exe"
$oscdimg_64bit = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
$folder_name_tmp = "tmp"
$folder_tmp = "$($PWD)\$($folder_name_tmp)"
$folder_win_dvd1 = "$($folder_tmp)\win_dvd1\"
$folder_win_dvd2 = "$($folder_tmp)\win_dvd2\"
$dvd_source_Windows = "Windows.iso"
$dvd_target_DVD1_UEFI = "Windows_DVD1.iso"
$dvd_target_DVD2_UEFI = "Windows_DVD2.iso"
$installFile = "install."
$autounattend = "$($env:autounattend)"
$splitISO = "$($env:splitISO)"


### Delete old files and folders
Write-Host " "
Write-Host "Delete old files and folders."
Remove-Item "$($folder_tmp)" -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item "$($PWD)\$($dvd_target_DVD1_UEFI)" -Force -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item "$($PWD)\$($dvd_target_DVD2_UEFI)" -Force -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item "$($PWD)\Windows7\" -Force -Confirm:$false -ErrorAction SilentlyContinue

### Install adksetup.exe to C:\ADK\ if oscdimg is missing ###
Write-Host " "
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
    & "$($PWD)\adksetup.exe" /quiet /installpath "C:\Program Files (x86)\Windows Kits\10" /features OptionId.DeploymentTools
}
Write-Host "Location of oscdimg: $($oscdimg)"

### Full path to the ISO file
Write-Host " "
$isoPath = "$($PWD)\$($dvd_source_Windows)"
Write-Host "ISO file: $($isoPath)"

### Unmount the ISO if already mounted
$isoDrive = Get-DiskImage -ImagePath $isoPath
$isoDrive | Dismount-DiskImage | Out-Null

### Mount ISO
$isoDrive = Mount-DiskImage -ImagePath $isoPath -PassThru | Get-Volume

### Get the DriveLetter currently assigned to the drive (a single [char])
$isoLetter = ($isoDrive | Get-Volume).DriveLetter
$isoDriveLetter = "$($isoLetter):\"
Write-Host "ISO drive letter: $($isoDriveLetter)"

### Check for sources\install.esd or wim
$dvd_windows_version = "na"
if ([System.IO.File]::Exists("$($isoDriveLetter)sources\install.esd")) {
	$installFile = "install.esd"
    $dvd_windows_version = Dism /Get-ImageInfo /ImageFile:"$($isoDriveLetter)sources\install.esd" /index:1 | Select-String "Name : Windows"
} elseif ([System.IO.File]::Exists("$($isoDriveLetter)sources\install.wim")) {
	$installFile = "install.wim"
    $dvd_windows_version = Dism /Get-ImageInfo /ImageFile:"$($isoDriveLetter)sources\install.wim" /index:1 | Select-String "Name : Windows"
} else {
    Write-Host " "
	Write-Host " "
	Write-Host "#############"
    Write-Host "### Error ###"
	Write-Host "#############"
    Write-Host " "
    Write-Host "Unable to find install.esd or install.wim in the ISO file $($isoPath) (Mounted to '$($isoDriveLetter)sources\')."
    Write-Host " "
	Write-Host "Have you provided an ISO with both 32-bit and 64-bit on it?"
    Write-Host "Use an ISO with only one architecture on it (32 OR 64-bit) as only this is supported by this script."
    Write-Host " "

	### Unmount ISO
	$isoDrive = Get-DiskImage -ImagePath "$($isoPath)"
	$isoDrive | Dismount-DiskImage | Out-Null

    Exit
}
Write-Host " "
Write-Host $dvd_windows_version

$dvd_version_win10 = "10"
$dvd_version_win10_name = "Windows 10"
$dvd_version_win11 = "11"
$dvd_version_win11_name = "Windows 11"

if ("$($dvd_windows_version)" -like "*$($dvd_version_win10_name)*"){
    $dvd_windows_version = $dvd_version_win10
} elseif ("$($dvd_windows_version)" -like "*$($dvd_version_win11_name)*"){
    $dvd_windows_version = $dvd_version_win11
} else {
	Write-Host " "
	Write-Host "Unsupported Windows version!"
	Write-Host " "
	
	### Unmount ISO
	$isoDrive = Get-DiskImage -ImagePath "$($isoPath)"
	$isoDrive | Dismount-DiskImage | Out-Null
	
	exit
}
Write-Host "Windows DVD version: $($dvd_windows_version)"

### Add DVD Windows version to target ISO names
$dvd_target_DVD1_UEFI = $dvd_target_DVD1_UEFI.replace("Windows","Windows$($dvd_windows_version)")
$dvd_target_DVD2_UEFI = $dvd_target_DVD2_UEFI.replace("Windows","Windows$($dvd_windows_version)")

### Delete old ISOs with the version in the name
Remove-Item "$($PWD)\$($dvd_target_DVD1_UEFI)" -Force -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item "$($PWD)\$($dvd_target_DVD2_UEFI)" -Force -Confirm:$false -ErrorAction SilentlyContinue

### Create tmp and win_dvd1 folders
Write-Host " "
Write-Host "Creating the 'tmp\' and 'tmp\win_dvd1' folders"
mkdir "$($folder_win_dvd1)"

### Copy CD content to the tmp\win_dvd1 folder
Write-Host " "
Write-Host "Copy Windows DVD files from '$($isoDriveLetter)' to '$($folder_win_dvd1)' (This takes a while!)"
Copy-item -Force -Recurse "$($isoDriveLetter)*" -Destination "$($folder_win_dvd1)" #-Verbose

### Unmount ISO
$isoDrive = Get-DiskImage -ImagePath "$($isoPath)"
$isoDrive | Dismount-DiskImage | Out-Null

### Read Write permissions
attrib -r -h "$($folder_tmp)\*.*" /s /d

### Change Windows source files
if ("$($splitISO)" -eq "true") {
	# Move install.esd or wim so we don't count it when checking used space
	mv "$($folder_win_dvd1)sources\$($installFile)" "$($folder_tmp)\$($installFile)"
}

if ("$($autounattend)" -eq "true") {
	# Source: https://gist.github.com/asheroto/c4a9fb4e5e5bdad10bcb831e3a3daee6
	Write-Host " "
	Write-Host "Add autounattend.xml file to the ISO, it disables hardware checks and allows local accounts"
	Copy-item "$($PWD)\autounattend.xml" -Destination "$($folder_win_dvd1)"
}


if ("$($splitISO)" -eq "true") {
	### Find DVD free space, so we know the maximum size of install.swm in order for it fit on a singel layer DVD.
	$dvd1_used_space = (Get-ChildItem -Path $folder_win_dvd1 -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
	$dvd_install_swm_size = 4400 - [Math]::Floor($dvd1_used_space) #Floor rounds the number down to a whole number 
	Write-Host " "
	Write-Host "DVD used space: $($dvd1_used_space)MB"
	Write-Host "Max install.swm size: $($dvd_install_swm_size)MB"

	Write-Host " "

	### Convert install.esd or wim into install.swm files in the DVD1 sources folder
	Write-Host " "
	Write-Host "Creating 'install.swm' files, this takes a while!"
	Dism /Split-Image /ImageFile:"$($folder_tmp)\$($installFile)" /SWMFile:"$($folder_win_dvd1)sources\install.swm" /FileSize:"$($dvd_install_swm_size)"

	### Delete the file tmp\install.esd or wim
	Remove-Item "$($folder_tmp)\$($installFile)" -Force -Confirm:$false -ErrorAction SilentlyContinue

	### Create DVD2 sources and move the second swm file
	Write-Host " "
	Write-Host "Creating the 'tmp\win_dvd2' and 'tmp\win_dvd2\sources' folders"
	mkdir "$($folder_win_dvd2)sources"
	Write-Host "Move install2.swm from 'win_dvd1\sources' to 'win_dvd2\sources'"
	mv "$($folder_win_dvd1)sources\install2.swm" "$($folder_win_dvd2)sources\install2.swm"
}

### Create UEFI ISOs ###
& $oscdimg -m -o -u2 -udfver102 -bootdata:2#p0,e,b"$($folder_win_dvd1)boot\etfsboot.com"#pEF,e,b"$($folder_win_dvd1)efi\microsoft\boot\efisys.bin" "$($folder_win_dvd1)" "$($PWD)\$($dvd_target_DVD1_UEFI)"
if ("$($splitISO)" -eq "true") {
	& $oscdimg -m -o -u2 -udfver102 "$($folder_win_dvd2)" "$($PWD)\$($dvd_target_DVD2_UEFI)"
}

### Finished
Write-Host " "
Write-Host "Finished creating the Windows ISOs!"
Write-Host "Windows DVD1: $($PWD)\$($dvd_target_DVD1_UEFI)"
if ("$($splitISO)" -eq "true") {
	Write-Host "Windows DVD2: $($PWD)\$($dvd_target_DVD2_UEFI)"
}

if ($dvd_windows_version -eq $dvd_version_win11) {
### Tips / How tos
Write-Host "

### HOW TO: Setting up a Local account on Windows 11 ###
Only useful with the 'original' DVD where online accounts haven't been disabled.

1. Start Windows setup without internet connected (Disconnect ethernet cable or don't login to Wifi)
2. Follow the Windows 11 installation until 'choose the country' screen.
3. Press: Shift + F10
4. Run the command: OOBE\BYPASSNRO
5. The PC will now reboot and the setup restart
6. When you reach the 'Let's connect you to a network', select 'I don't have internet' and 'Continue with limited setup'.
7. Follow the screens and finish the installation.
"
} elseif ($dvd_windows_version -eq $dvd_version_win10) {
### Tips / How tos
Write-Host "

### Windows 10 doesn't work in my tests! ###
$($dvd_target_DVD1_UEFI) boots, but when asking for the second DVD and given $($dvd_target_DVD2_UEFI), it fails.
It seems to not find some files, unclear what is missing.

So it's a work in progress feature, hehe
"
}