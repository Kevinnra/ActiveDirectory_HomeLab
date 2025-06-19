<#
.SYNOPSIS
    Disables AD accounts inactive for 90+ days
.DESCRIPTION
    Identifies and disables stale user accounts to maintain security compliance.
    Generates a report of affected users.
.NOTES
    Last Updated: $(Get-Date -Format "yyyy-MM-dd")
    Audit Log: .\Outputs\Disabled-Accounts-$(Get-Date -Format "yyyyMMdd").csv
#>

# Configuration
$DaysInactive = 90
$SearchBase = "OU=Departments,DC=lab,DC=local"
$ReportPath = ".\Outputs\Disabled-Accounts-$(Get-Date -Format "yyyyMMdd").csv"

# Get inactive users
$InactiveUsers = Search-ADAccount -SearchBase $SearchBase -UsersOnly -AccountInactive -TimeSpan (New-TimeSpan -Days $DaysInactive)

# Process accounts
$Results = foreach ($User in $InactiveUsers) {
    Disable-ADAccount -Identity $User -Confirm:$false
    
    [PSCustomObject]@{
        Name = $User.Name
        SamAccount = $User.SamAccountName
        LastLogon = $User.LastLogonDate
        OU = $User.DistinguishedName.Split(',')[1].Replace('OU=','')
        Status = "Disabled"
    }
}

# Export report
$Results | Export-Csv $ReportPath -NoTypeInformation
Write-Host "Disabled $($Results.Count) accounts. Report saved to $ReportPath" -ForegroundColor Yellow


# Sample Output CVS:
# "Name","SamAccount","LastLogon","OU","Status"
# "Old User","ouser","2025-01-15","IT","Disabled"