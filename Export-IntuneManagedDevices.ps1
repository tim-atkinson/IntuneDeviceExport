<#
.SYNOPSIS
    Connects to Microsoft Intune via Microsoft Graph API to retrieve managed device information and export it in JSON and CSV formats.

.DESCRIPTION
    This PowerShell script follows best practice standards for connecting to Microsoft Intune via the Microsoft Graph API. 
    It retrieves managed device information and exports it in both JSON and CSV formats for further processing and analysis. 
    The script supports both interactive user login and service principal (client credentials) authentication for flexibility. 
    Logging is implemented for transparency and troubleshooting.

.PARAMETER ClientId
    The Client ID of the Azure AD application used for authentication.

.PARAMETER TenantId
    The Tenant ID of the Azure AD application.

.PARAMETER ClientSecret
    The Client Secret of the Azure AD application used for authentication.

.PARAMETER UseInteractiveLogin
    A switch parameter to use interactive login for authentication instead of client credentials.

.PARAMETER LogPath
    The file path where logs should be written. Default is "$PSScriptRoot\IntuneManagedDevices.log".

.PARAMETER OutputDirectory
    Directory where output files (JSON and CSV) should be saved. Default is the script's root directory.

.EXAMPLE
    .\Export-IntuneManagedDevices.ps1 -ClientId "<YourClientId>" -TenantId "<YourTenantId>" -ClientSecret "<YourClientSecret>"
    Connects to Microsoft Graph using client credentials and exports the managed devices to JSON and CSV.

.EXAMPLE
    .\Export-IntuneManagedDevices.ps1 -UseInteractiveLogin
    Connects to Microsoft Graph using interactive login and exports the managed devices to JSON and CSV.
#>

param (
    [string]$ClientId,
    [string]$TenantId,
    [string]$ClientSecret,
    [switch]$UseInteractiveLogin,
    [string]$LogPath = "$PSScriptRoot\IntuneManagedDevices.log",
    [string]$OutputDirectory = $PSScriptRoot
)

# Initialize log messages storage
$LogMessages = @()

# Function to write logs
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] - $Message"
    # Output the log entry to the console
    Write-Output $logEntry
    # Append the log entry to the log file using Out-File for better performance
    $logEntry | Out-File -FilePath $LogPath -Append -Encoding utf8
    # Store the log entry in the global variable for use elsewhere if needed
    $global:LogMessages += $logEntry
}

# Function to start a new log session
function Start-LogSession {
    # Start a new log session by adding a header to indicate the beginning of the session
    $sessionHeader = "`n`n==== Log Session Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ====`n"
    # Add the session header to the log file using Out-File for better performance
    $sessionHeader | Out-File -FilePath $LogPath -Append -Encoding utf8
    # Store the session header in the global log messages
    $global:LogMessages += $sessionHeader
}

# Function to connect to Microsoft Graph
function Connect-MSGraph {
    try {
        # Check if there is an active session before attempting to disconnect
        $mgContext = Get-MgContext
        if ($mgContext) {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
            Write-Log -Message "A previous MgGraph session was found and has been disconnected."
        }

        # Use interactive login if the switch is specified
        if ($UseInteractiveLogin) {
            Write-Log -Message "Attempting interactive login..."
            Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All" -NoWelcome
        }
        # Use client credentials if ClientId, TenantId, and ClientSecret are provided
        elseif ($ClientId -and $TenantId -and $ClientSecret) {
            Write-Log -Message "Attempting client credentials authentication with Client ID: $ClientId"
            
            # Convert the Client Secret to a Secure String for secure handling
            $SecureClientSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
            # Create a PSCredential Object Using the Client ID and Secure Client Secret
            $ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $SecureClientSecret
            # Connect to Microsoft Graph Using the Tenant ID and Client Secret Credential
            Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome
        }
        # Throw an error if no valid authentication method is provided
        else {
            throw "No valid authentication method provided. Please use -UseInteractiveLogin or provide ClientId, TenantId, and ClientSecret."
        }
        Write-Log -Message "Successfully authenticated with Microsoft Graph. New session initiated."
    }
    catch {
        # Log any authentication errors and rethrow the exception
        Write-Log -Message "Authentication failed: $($_.Exception.Message)" -Level "ERROR"
        Write-Log -Message "Full Exception Details: $($_ | Out-String)" -Level "ERROR"
        throw $_
    }
}

# Function to retrieve Intune devices
function Get-IntuneDevices {
    try {
        Write-Log -Message "Retrieving device data from Microsoft Intune..."
        # Retrieve all managed devices from Microsoft Intune
        $Devices = Get-MgDeviceManagementManagedDevice -All
        Write-Log -Message "Retrieved $($Devices.Count) devices from Microsoft Intune."
        # Filter out any devices without a device name
        return $Devices
    }
    catch {
        # Log any errors that occur during the device retrieval process
        Write-Log -Message "Error retrieving device data: $($_.Exception.Message)" -Level "ERROR"
        Write-Log -Message "Full Exception Details: $($_ | Out-String)" -Level "ERROR"
        throw $_
    }
}

# Function to export devices to JSON
function Export-DevicesToJson {
    param (
        [array]$Devices
    )
    try {
        # Define the path for the JSON output file
        $JsonPath = Join-Path -Path $OutputDirectory -ChildPath "DevicePayload.json"
        # Filter devices and select necessary properties, then convert to JSON and save to file
        $Devices | Select-Object deviceName, id, model, lastSyncDateTime | ConvertTo-Json -Depth 4 | Set-Content -Path $JsonPath -Encoding utf8
        Write-Log -Message "Device data successfully exported to JSON: $JsonPath"
    }
    catch {
        # Log any errors that occur during the export to JSON process
        Write-Log -Message "Error exporting devices to JSON: $($_.Exception.Message)" -Level "ERROR"
        Write-Log -Message "Full Exception Details: $($_ | Out-String)" -Level "ERROR"
        throw $_
    }
}

# Function to export devices to CSV
function Export-DevicesToCsv {
    param (
        [array]$Devices
    )
    try {
        # Define the path for the CSV output file
        $CsvPath = Join-Path -Path $OutputDirectory -ChildPath "DevicePayload.csv"
        # Filter devices and select necessary properties, then export to CSV
        $Devices | Where-Object { $null -ne $_.deviceName } | Select-Object deviceName, id, model, lastSyncDateTime | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding utf8
        Write-Log -Message "Device data successfully exported to CSV: $CsvPath"
    }
    catch {
        # Log any errors that occur during the export to CSV process
        Write-Log -Message "Error exporting devices to CSV: $($_.Exception.Message)" -Level "ERROR"
        Write-Log -Message "Full Exception Details: $($_ | Out-String)" -Level "ERROR"
        throw $_
    }
}

# Main Script Execution
try {
    # Start a new log session to track the beginning of script execution
    Start-LogSession

    # Connect to Microsoft Graph
    Connect-MSGraph

    # Get Intune Devices
    $Devices = Get-IntuneDevices

    # Export Devices to JSON and CSV if any devices were retrieved
    if ($Devices) {
        Export-DevicesToJson -Devices $Devices
        Export-DevicesToCsv -Devices $Devices
    }
    else {
        Write-Log -Message "No devices were retrieved from Intune." -Level "ERROR"
    }
}
catch {
    # Log any errors that occur during the main script execution
    Write-Log -Message "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Log -Message "Full Exception Details: $($_ | Out-String)" -Level "ERROR"
}
finally {
    # Ensure to disconnect the session after the script completes
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    Write-Log -Message "Microsoft Graph session disconnected."
}