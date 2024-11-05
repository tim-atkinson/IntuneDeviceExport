# Export-IntuneManagedDevices

![PSScriptAnalyzer](https://github.com/tim-atkinson/IntuneDeviceExport/actions/workflows/ci-workflow-psscriptanalyzer.yml/badge.svg)

## Overview
This script connects to Microsoft Intune using the Microsoft Graph API to retrieve managed device information and export it in both JSON and CSV formats. The script is designed for IT professionals managing Intune environments, providing an easy way to automate device data retrieval.

## Features
- Connects to Microsoft Intune via Microsoft Graph API.
- Supports both **interactive user login** and **service principal** (client credentials) authentication.
- Retrieves detailed information about managed devices in your Intune environment.
- Exports device data to **JSON** and **CSV** formats for further processing and analysis.
- Includes logging for transparency and troubleshooting.

## Requirements
- **Microsoft Graph SDK Installation**: Install the Microsoft Graph SDK by using the following command:
  ```powershell
  Install-Module Microsoft.Graph -Scope CurrentUser
  ```
  This will provide the necessary cmdlets to interact with Microsoft Graph.
- **Azure AD Application Setup**:
  1. **Create an App Registration**: In Azure Portal, navigate to **Azure Active Directory > App registrations > New registration**. Register a new application with an appropriate name.
  2. **API Permissions**: After registering the application, navigate to **API Permissions**.
     - Click on **Add a permission**.
     - Select **Microsoft Graph**.
     - Choose **Application permissions** (not delegated).
     - Search for and add the **DeviceManagementManagedDevices.Read.All** permission.
  3. **Grant Admin Consent**: Ensure to click **Grant admin consent for [your organization]** so that the app can run without requiring individual user consent.
  4. **Create a Client Secret**: Go to **Certificates & secrets** and create a new client secret. This secret will be used in the script for authentication.
- **PowerShell** version 5.1 or later.
- **Microsoft Graph PowerShell Module**: Ensure the module is installed. You can install it with:
  ```powershell
  Install-Module Microsoft.Graph -Scope CurrentUser
  ```
- **Azure AD Application**: If using service principal authentication, ensure you have an Azure AD application with permissions to access Intune data (DeviceManagementManagedDevices.Read.All).

## Parameters
- `-ClientId`: The Client ID of the Azure AD application used for authentication.
- `-TenantId`: The Tenant ID of the Azure AD application.
- `-ClientSecret`: The Client Secret of the Azure AD application used for authentication.
- `-UseInteractiveLogin`: Use this switch for interactive user login instead of client credentials.
- `-LogPath`: The file path where logs should be written. Default is `IntuneDeviceSync.log` in the script's root directory.
- `-OutputDirectory`: Directory where output files (JSON and CSV) will be saved. Default is the script's root directory.

## Usage

### Example 1: Using Service Principal Authentication
```powershell
.\Export-IntuneManagedDevices.ps1 -ClientId "<YourClientId>" -TenantId "<YourTenantId>" -ClientSecret "<YourClientSecret>"
```
This command will use the specified Client ID, Tenant ID, and Client Secret to authenticate and retrieve device information, exporting it to JSON and CSV.

### Example 2: Using Interactive User Login
```powershell
.\Export-IntuneManagedDevices.ps1 -UseInteractiveLogin
```
This command will prompt you to log in interactively using your user credentials.

## Script Details
- **Logging**: The script logs all activities, including authentication attempts, data retrieval, and export status, in a log file (`IntuneDeviceSync.log`). This helps in auditing and troubleshooting issues.
- **Data Filtering**: The script filters out devices that do not have a `deviceName` property set.
- **Export**: The retrieved data is exported in two formats:
  - **JSON**: Contains device details such as `deviceName`, `id`, `model`, and `lastSyncDateTime`.
  - **CSV**: Contains similar information to the JSON output for easy viewing and processing.

## Error Handling
- The script includes comprehensive error handling. Errors during authentication, data retrieval, or export are logged with details, including the full exception information for troubleshooting purposes.

## Important Notes
- Ensure that the Azure AD application has the appropriate API permissions (`DeviceManagementManagedDevices.Read.All`) and that admin consent is granted.
- The `ClientSecret` must remain secure. Do not log or expose this value unnecessarily.
- The script attempts to disconnect from any previous Microsoft Graph session before initiating a new connection to ensure proper session management.
