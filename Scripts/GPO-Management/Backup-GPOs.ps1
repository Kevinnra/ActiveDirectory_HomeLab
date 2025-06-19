<#
.SYNOPSIS
    Backs up all Group Policy Objects (GPOs) in a domain
.DESCRIPTION
    Creates timestamped backups of GPOs with XML reports
    Outputs to .\Backups\GPO\ with subfolders per GPO
.NOTES
    Author: Kevinn Ramirez
    Lab: AD & Helpdesk Simulation
    Minimum PowerShell Version: 5.1
#>

# Configuration
$BackupRoot = ".\Backups\GPO"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupPath = "$BackupRoot\$Timestamp"

# Create backup directory
if (-not (Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath | Out-Null
}

# Backup all GPOs
try {
    $BackupReport = Backup-GPO -All -Path $BackupPath -Comment "Lab environment backup $Timestamp"
    
    # Generate summary report
    $BackupReport | Select-Object DisplayName, ID, BackupTime, Comment | 
        Export-Csv "$BackupPath\Backup-Summary.csv" -NoTypeInformation
    
    Write-Host "Successfully backed up $($BackupReport.Count) GPOs to:" -ForegroundColor Green
    Write-Host $BackupPath -ForegroundColor Cyan

} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}

# Verify backups
Get-ChildItem $BackupPath -Recurse -Include *.xml, *.csv | 
    Select-Object FullName, Length, LastWriteTime |
    Format-Table -AutoSize


#Sample Output Structure:
Backups/
└── GPO/
    └── 20231020-143022/
        ├── {GUID}/               # Per-GPO backup
        │   ├── backup.xml        # GPO settings
        │   └── gpreport.xml      # HTML report
        └── Backup-Summary.csv    # Overview
