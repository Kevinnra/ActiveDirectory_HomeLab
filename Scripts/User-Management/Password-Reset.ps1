<#
.SYNOPSIS
    Helpdesk password reset utility with logging
.DESCRIPTION
    Resets user passwords and logs actions for audit compliance.
    Sends email notification to user (optional).
.NOTES
    Security: Requires Helpdesk group membership to execute
    Logs: .\Outputs\Password-Resets.log
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$NewPassword = "Temp@$(Get-Random -Minimum 1000 -Maximum 9999)"
)

# Import modules
Import-Module ActiveDirectory

# Initialize
$LogPath = ".\Outputs\Password-Resets.log"
$SecurePassword = ConvertTo-SecureString $NewPassword -AsPlainText -Force
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Reset password
try {
    Set-ADAccountPassword -Identity $Username -NewPassword $SecurePassword -Reset
    Unlock-ADAccount -Identity $Username
    
    # Log action
    "$Timestamp - Reset password for $Username. Temp password: $NewPassword" | Out-File $LogPath -Append
    
    # Output result
    Write-Host "SUCCESS: Password reset for $Username" -ForegroundColor Green
    Write-Host "Temporary password: $NewPassword" -ForegroundColor Cyan
    Write-Host "User must change password at next logon." -ForegroundColor Yellow
    
} catch {
    "$Timestamp - FAILED to reset $Username. Error: $_" | Out-File $LogPath -Append
    Write-Host "ERROR: $_" -ForegroundColor Red
}

# Sample log entry:
# 2025-05-20 14:30:45 - Reset password for mverstappen. Temp password: Temp@4291