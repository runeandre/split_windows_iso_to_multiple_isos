# Split Windows.iso (Windows 11 for now) into multiple single layer ISOs

## About
A script made to split a modern Windows ISO into two ISOs that are small enough to be burnt to a singel layer DVD (the normal ones people use).

You can also remove hardware checks and just setup a local account during setup.
<br>There is also an option to create these modifications as a single ISO.

Windows 11 ISOs works.

## How to use
1. [Download the files from this GIT repo](https://github.com/runeandre/split_windows_iso_to_multiple_isos/archive/refs/heads/main.zip) and unzip them into a folder.
2. Copy the Windows ISO into the same folder as the files above.
3. Rename the ISO file to "Windows.iso".
4. Execute the "CREATE_ISO" file (double click it).
<br>"CREATE_ISO.bat" = Creates ISOs with local accounts and no hardware checks.
<br>"CREATE_ISO_NOSPLIT.bat" = The same as "CREATE_ISO", just without splitting the ISO.
<br>"CREATE_ISO_ORIGINAL.bat" = Creates "original" ISOs (no alterations except splitting the ISO).
5. It will ask for Administartor privelidges if missing.
6. "adksetup.exe" will be installed if "oscdimg" is not installed.
7. When finished, the script will have produced 2 new ISO files named: "WindowsXX_DVD1.iso" and "WindowsXX_DVD2.iso" (XX = Windows Version number).
8. Burn these to DVDs and boot from the first DVD. It will ask for the second DVD during the setup.

## Test status
Currently just tested in Windows 11 with Windows 11 ISOs.
<br>VirtualBox was used for test booting the ISOs on a Windows 11 VM.

Windows 10 ISOs boots, but fails when reading DVD2 (missing files or something).
<br>It's included as a work in progress feature for now.

## How to

### Setting up a Local account on Windows 11
Only useful with the 'original' DVD where online accounts haven't been disabled.

1. Start Windows setup without internet connected (Disconnect ethernet cable or don't login to Wifi)
2. Follow the Windows 11 installation until 'choose the country' screen.
3. Press: Shift + F10
4. Run the command: OOBE\BYPASSNRO
5. The PC will now reboot and the setup restart
6. When you reach the 'Let's connect you to a network', select 'I don't have internet' and 'Continue with limited setup'.
7. Follow the screens and finish the installation.
