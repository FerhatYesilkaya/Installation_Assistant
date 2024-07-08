# Installation Assistant

## Prerequisites

1. **Check Setup Filenames in Configurables**
   - Ensure that the entries `MirthAdministratorSetupFileName` and `MirthConnectSetupFileName` in `configurables.ini` have the correct values. These should be the filenames of the Mirth Connect and Mirth Administrator setup files.

2. **Check JDBC Driver Filenames in Configurables**
   - Verify that the entries `intersystemsjdbcName` and `mirthConnectServiceName` in `configurables.ini` are set correctly. These should be the filenames of the JDBC drivers.
   - Note: The installation assistant uses the JDBC driver located in the "Intersystems Driver" folder, not the "Intersystems Drivers" folder. Although both folders contain the same files, the assistant references the one in the singular "Driver" folder.

## How-to-use

1. Start `installation_assistant.exe`.
2. Choose whether you want to update or perform a new installation.
3. Fill in all the input fields.
4. Press the `Start` button.

Enjoy a seamless installation process!
