# Split Windows.iso into multiple single layer ISOs

## About
A script made to split a Windows ISO into two ISOs that are small enough to be burnt to a singel layer DVD (the normal ones people use).

These ISOs are currently just UEFI compatible and no hardware checks are removed.

## How to use
1. Download the RUN.bat and SplitWindowsISO.ps1 files
2. Copy the Windows ISO into the same folder as the files above
3. Rename the ISO file to "Windows.iso"
4. Run the "RUN.bat" file (double click it)
5. It will ask for Administartor privelidges which it needs.
6. When finished, the script will have produced 2 new ISO files named: "Windows_DVD1_UEFI.iso" and "Windows_DVD2_UEFI.iso".
7. Burn these to DVDs and boot from the first DVD. It will ask for the second DVD during the setup.

## Test status
Currently just tested in Windows 11 with Windows 11 ISOs.

VirtualBox was used for test booting the ISOs.

## How to

### Setting up a Local account on Windows 11
1. Start Windows setup without internet connected (Disconnect ethernet cable or don't login to Wifi)
2. Follow the Windows 11 installation until 'choose the country' screen.
3. Press: Shift + F10
4. Run the command: OOBE\BYPASSNRO
5. The PC will now reboot and the setup restart
6. When you reach the 'Let's connect you to a network', select 'I don't have internet' and 'Continue with limited setup'.
7. Follow the screens and finish the installation.

## TODO
- Skip hardware checks etc
- Legacy BIOS compatible ISOs