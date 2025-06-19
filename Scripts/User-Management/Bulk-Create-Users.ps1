<#
.SYNOPSIS
    Creates multiple AD users from CSV input for lab testing
.DESCRIPTION
    Imports users from a CSV file and creates enabled AD accounts with:
    - Standardized password (change at first logon)
    - Department-specific OU placement
    - Email alias generation
.NOTES
    Author: Kevinn Ramirez
    Lab: AD & Helpdesk Simulation
    Required Modules: ActiveDirectory
#>

# Import module
Import-Module ActiveDirectory

# Define variables
$CSVPath = ".\Inputs\New-Hires.csv"
$DefaultPassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
$Domain = "@lab.local"

# Import CSV and create users
Import-Csv $CSVPath | ForEach-Object {
    $Username = ($_.FirstName[0] + $_.LastName).ToLower()
    $OU = "OU=$($_.Department),OU=Departments,DC=lab,DC=local"
    
    New-ADUser -Name "$($_.FirstName) $($_.LastName)" `
               -GivenName $_.FirstName `
               -Surname $_.LastName `
               -SamAccountName $Username `
               -UserPrincipalName "$Username$Domain" `
               -Path $OU `
               -AccountPassword $DefaultPassword `
               -ChangePasswordAtLogon $true `
               -Enabled $true `
               -Department $_.Department `
               -Title $_.Position `
               -PassThru | Out-Null
    
    Write-Host "Created user: $Username in $($_.Department) department"
}

Write-Host "User creation complete. Verify in ADUC." -ForegroundColor Green