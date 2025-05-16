# Active Directory & Helpdesk Simulation Lab  

## **Lab Overview**  
- **Objective**: Simulate an enterprise IT environment with AD, helpdesk workflows, and ticketing.  
- **Tools Used**: VirtualBox, Windows Server 2022, Windows 10,  Freshdesk.  

## **Step 1: Setting Up the Lab**  
### **1.1 Install Windows Server 2022 on VirtualBox**  
- Download ISO from [Microsoft Evaluation Center](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022).  
- Create a new VM in VirtualBox (4GB RAM, 50GB HDD).  
- Install **Windows Server 2022 (Desktop Experience)**.  

📸 **Screenshot**: VirtualBox VM settings.  
![](/Screenshots/VirtualBoxConfig.jpg)

💡 **Pro Tip**: Disable the virtual network adapter in VirtualBox during Windows Server installation to prevent internet connectivity. Re-enable it after setup is complete. *`This bypasses initial license verification while keeping your lab compliant.`*.

### **1.2 Configure your Server:**  
#### **Network Configuration**
- Assign a **static IP** (e.g., `192.168.1.100`). 
- Set the server's primary DNS to `127.0.0.1` (for AD functionality)
-  Set secondary DNS to a public resolver like `8.8.8.8` (for internet access)
-  Disable IPv6 *`(To keep things simple)`*

#### Time Settings
- Set `[Your DC's Time Zone]` to match your physical location before promoting it.
- Ensures proper time sync for domain authentication

### **1.3 Promote Server to Domain Controller**  
+ ### Method 1: Powerhell
    
    1. Install **Active Directory Domain Services (AD DS)** via Server Manager.  
    2. Run:  
        ```powershell
        #Install AD DS role
        Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

        
        # Promote server to DC in new forest (will reboot automatically)
        Install-ADDSForest `
        -DomainName "mylab.local" `  #Set mine as "x.local"
        -DomainNetbiosName "MYLAB" `  #Set mine as "X"
        -ForestMode "WinThreshold" `
        -DomainMode "WinThreshold" `
        -InstallDNS:$true `
        -NoRebootOnCompletion:$false `
        -Force:$true 

        # Verify
        Get-ADDomainController
        ```
    📸   If installation was successful you will see something like this:

    ![i](Screenshots/InstalledDomainController.png)

+ ### Method 2: GUI
    #### Install AD DS Role

    1. Open Server Manager
    2. Click Add roles and features
    3. Select Role-based installation → Click Next
    4. Choose your server from the pool → Click Next
    5. Check Active Directory Domain Services
    6. Click Add Features when prompted
    7. Click Next through remaining screens
    8. Click Install
    
    #### Promote to Domain Controller

    1. In Server Manager, click the flag notification icon
    2. Select Promote this server to a domain controller
    3. Choose deployment configuration:
        - Add a new forest
        - Enter root domain name `(e.g., mylab.local)`
    4. Set Directory Services Restore Mode (DSRM) password
    5. Click Next through remaining options (defaults are fine)
    6. Review prerequisites → Click Install
    7. Server will automatically reboot

    📸    AD DS role successfully installed in Server Manager:
    ![](Screenshots/ServerManagerDashboard.png)
    ![](Screenshots/ServerManagerLocalServer.png)
    

### **1.4 Join a client to the Domain:**
#### Prerequisites

- Windows 10 VM installed in VirtualBox/VMware
- Domain Controller (DC) fully configured
- Network connectivity between DC and Win10 VM (both in NAT/Host-Only or Bridged mode)

#### Method 1: GUI 

##### 1 Configure Network Settings:
- Set Win10 DNS to ***point to your DC's IP*** ⚠️ (e.g., `192.168.1.100`)
- **Control Panel** > **Network and Sharing Center** > **Change adapter settings**
- Right-click Ethernet → Properties → IPv4 → **Preferred DNS:** `192.168.1.100`
##### 2 Join Domain:
- Press `Win + R`, type `sysdm.cpl` → Enter
- Go to **Computer Name** tab → Click **Change**...
- Select **Domain** → Enter `myLab.local` (your domain name)
- Enter DC admin credentials when prompted (e.g., `x.local\Administrator`)
- Restart when prompted

##### Verification:
1. **Access System Properties**:
   - Press `Win + R`, type `sysdm.cpl`, then press Enter

2. **Authenticate**:
   - When prompted, enter domain administrator credentials in this format:  
     `x.local\Administrator`  
     *(Replace "x.local" with your actual domain name)*

3. **Confirm Domain Membership**:
   - Under the **Computer Name** tab, verify:  
     - "Domain:" shows your domain name (e.g., `x.local`)  
     - The "Full computer name" includes your domain suffix  

📸 screenshot:
![](Screenshots/systemPropertiesDomain.png)
___
#### Method 2: PowerShell:
```Powershell 
    # Set DNS to DC's IP
    Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).ifIndex -ServerAddresses "192.168.1.100"

    # Join domain
    Add-Computer -DomainName "x.local" -Credential (Get-Credential) -Restart -Force

    # Verify domain join
    Test-ComputerSecureChannel -Verbose # image: 'A'
    
```
📝 Notes:

- Run Powershell as Administrator
- When prompted for credentials, use: `x.local\Administrator` (your domain admin credentials)
- Last command should return `True` if successful.  (*image: 'A'*)

#### Verification Steps

1. After reboot:
- Log in with domain credentials (e.g., x.local\Administrator)
- Open Command Prompt and run:
```cmd
    systeminfo | find "Domain"
```
- should reference your domain (x.local) (image: 'B')




📸 screenshots:
##### A:
![](/Screenshots/shellSecureChannel.png)
##### B:
![](/Screenshots/cmdSysteminfoDomain.png)

## 2. Active Directory Post-Installation Configuration

### **2.1 Create Organizational Units (OUs)**

**Purpose**: Structure your Active Directory with logical containers for users, computers, and groups.

#### **Method 1: GUI (ADUC)**

1. **Open Active Directory Users and Computers (ADUC)**
- Press `Win + R` → type `dsa.msc` → Enter
- Alternatively:

    Start Menu → Windows Administrative Tools → Active Directory Users and Computers

2. **Create Parent OU**
- Right-click your domain (e.g., x.local)
- Select **New** → **Organizational Unit**
- Name: `Your_Parent_OU` (Set mine as 'Employees')
- You can **Uncheck** "Protect container from accidental deletion" (for lab simplicity)
- Click **OK**
3. **Create Child OUs**:
- Right-click `Your_Parent_OU` OU → **New** → **Organizational Unit**
- Create `your_child_OU`:
    - IT 
    - HR 
- Repeat for other OUs.

📸 screenshots:
![](/Screenshots/creation_OU_GUI.png)
![](/Screenshots/OU_childOU_created.png)
[[[[[fix last screenshot]]]]]

#### **Method 2: Command Line (PowerShell)**

Run PowerShell as Administrator:
```Powershell
# Import AD module (if not loaded)
Import-Module ActiveDirectory

# Create parent OU, change "x" for yourDomain name
New-ADOrganizationalUnit -Name "Departments" -Path "DC=x,DC=local" -ProtectedFromAccidentalDeletion $false

# Create child OUs
"IT", "HR", "Finance" | ForEach-Object {
    New-ADOrganizationalUnit -Name $_ -Path "OU=Departments,DC=x,DC=local" -ProtectedFromAccidentalDeletion $false
}

# Verify creation
Get-ADOrganizationalUnit -Filter * | Format-Table Name, DistinguishedName -AutoSize
```
Expected output:
```Powershell
Name       DistinguishedName
----       -----------------
IT         OU=IT,OU=Departments,DC=x,DC=local
HR         OU=HR,OU=Departments,DC=x,DC=local
Finance    OU=Finance,OU=Departments,DC=x,DC=local
```
xxxScreenshotsXXX[[[[[[[[[[[]]]]]]]]]]]

##### **Why OUs Matter ?**
- Enables granular Group Policy application  
- Simplifies user/computer management  
- Mirrors real-world AD structures (e.g., HR gets different policies than IT)  


### **2.2 Create Test Users**
**Purpose**: Populate your Active Directory with sample accounts for testing permissions, policies, and helpdesk workflows.

#### Method 1: GUI (AD Users and Computers)

1. **Open ADUC**
- Press `Win + R` → type `dsa.msc` → Enter
- Navigate to your **target OU** (e.g., `IT` under `Departments` )

2. **Create Single User**
- Right-click the OU → **New** → **User**
- Complete fields:
    - First name: `Max`
    - Last name: `Verstappen`
    - User logon name: `max.v` (automatically appends `@yourDomain.local`)
- Click **Next**
3. **Set Password**
- Password: `P@ssw0rd123` (meets complexity requirements)
- Check:
    - ☑ User must change password at next logon (uncheck for lab accounts)
    - ☑ Password never expires (recommended for lab)
4. **Finalize**
- Click **Finish**
- Repeat for additional users (e.g., `lando.norris`, `charles.leclerc`)

**Screenshots**:
#### Method 2: PowerShell (Bulk Creation)

*Run PowerShell as Administrator in your Domain Controller:*
```Powershell
# Import AD module
Import-Module ActiveDirectory

# Define user template
$Password = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force
$OU = "OU=IT,OU=Departments,DC=yourDomain,DC=local"

# Create 5 test users
1..5 | ForEach-Object {
    $FirstName = "User"
    $LastName = "$_"
    $Username = "$FirstName$LastName".ToLower()
    
    New-ADUser -Name "$FirstName $LastName" `
               -GivenName $FirstName `
               -Surname $LastName `
               -SamAccountName $Username `
               -UserPrincipalName "$Username@yourDomain.local" `
               -Path $OU `
               -AccountPassword $Password `
               -Enabled $true `
               -PasswordNeverExpires $true ` # Only for Lab
               -ChangePasswordAtLogon $false # Only for Lab
}

# Verify creation
Get-ADUser -Filter * -SearchBase $OU | Select Name, SamAccountName
```
Expected Output:
```
Name         SamAccountName
----         -------------
User 1       user1
User 2       user2
User 3       user3
user 4       user4
user 5       user5
```

Screenhot[[[[[[]]]]]]

**Best Practices for User Creation and Tips💡:** 

1. **Naming Conventions**:
    - Usernames: `firstname.lastname` (e.g., lewis.hamilton)
    - Email addresses: Match User Principal Name - UPN (`lewis.hamilton@x.local`)
2. **Password Policy**:
    - Lab: Use `PasswordNeverExpires` to avoid lockouts
    - Production: Enforce periodic password changes
3. **Attributes to Set**:
    - Department, title, office/location and manager (for advanced GPO filtering:
    
    ```Powershell
    # Set comprehensive attributes during user creation
    New-ADUser -Name "Alexander Albon" -GivenName "Alexander" -Surname "Albon"
    -SamAccountName "a.albon" -UserPrincipalName "a.albon@x.local"
    -Department "Accounting" -Title "Senior Financial Analyst" 
    -Office "Williams-London" -Manager "sr.williams@x.local"
    ```

4. **For Production**:

    - Generate random passwords:
    ```Powershell
    $Password = "Pr@" + (Get-Random -Minimum 1000 -Maximum 9999) + (Get-Random -InputObject ('!','#','$'))
    # Example output: Pr@8842$
    ```

    - **Automation Readiness** PowerShell Template for Production:
    ```Powershell
    # Import CSV with new hires
    $Users = Import-Csv -Path "C:\Onboarding\NewHires_Q2.csv"

    $Users | ForEach-Object {
        New-ADUser -Name "$($_.FirstName) $($_.LastName)" `
                -GivenName $_.FirstName `
                -Surname $_.LastName `
                -SamAccountName $_.Username `
                -UserPrincipalName "$($_.Username)@x.local" `
                -Department $_.Dept `
                -Path "OU=$($_.Dept),OU=Departments,DC=x,DC=local" `
                -AccountPassword (ConvertTo-SecureString $_.TempPassword -AsPlainText -Force)
    }
    ```

    **Why This Matters in Production ?**  
    - Automated user onboarding saves 10+ minutes per employee  
    - Consistent naming conventions simplify troubleshooting  
    - Bulk operations are essential during mergers/acquisitions  

screenshot:[[[[[[]]]]]]













## **3. Group Policy Configuration**
**Purpose**: Centrally manage security settings and workstation configurations across your domain.

### **3.1 Enforce NIST-Compliant Password Policy**
**Business Need**: Meet security compliance requirements (e.g., NIST, ISO 27001).**Why?** 
- Mitigates 81% of brute-force attacks (Verizon DBIR 2023)
- Meets insurance/audit requirements (SOC2, ISO 27001)
- Aligns with Microsoft Security Baseline"

**Implementation**
1. Open Group Policy Management Console (GPMC):
`Win + R` → `gpmc.msc`
2. Navigate to:
`Forest: x.local → Domains → x.local → Group Policy Objects`
3. Edit **Default Domain Policy**:
Right-click → **Edit**
4. Configure password settings:

Path: `Computer Configuration → Policies → Windows Settings → Security Settings → Account Policies → Password Policy`
- **Minimum password length**: 12 characters
- **Password history**: 24 passwords remembered
- **Maximum password age**: 90 days
- **Complexity requirements**: Enabled

5. Enforce for all users:
```powershell
gpupdate /force  # Applies changes immediately to DC
```
[[[[[[[screenshots]]]]]]]


### **3.2 Folder Redirection (example policy)**
**Business Need**: Protect user data from device failures.

**Implementation**:

1. Create GPO named `User Data Protection`
2. Configure:

Path: `User Configuration → Policies → Windows Settings → Folder Redirection`
- **Documents**: Redirect to `\\fileserver\users\%username%\Documents`
- **Applies to**: Authenticated Users
3. Set permissions on file server:
```Powershell
icacls "\\fileserver\users" /grant "Domain Users:(OI)(CI)(M)"
```
### **3.3 Disable USB Storage (example policy)**

**Business Need**: Prevent data exfiltration (common in security-sensitive roles).

**Implementation**:

1. Create new GPO named `Device Restriction Policy`
2. Navigate to:

`Computer Configuration → Policies → Administrative Templates → System → Removable Storage Access`
- **All Removable Storage classes**: **Deny all access**: Enabled
3. Link to all computer OUs

**Impact:**

- Users see "Access Denied" when inserting USB drives
- Logs events in Security log (Event ID 4657)

### **3.4 Deploy Screensaver Lock Policy (example policy)**

**Business Need**: Enforce workstation security for idle devices.

**Implementation**:

1. Create new GPO:
- Right-click **Group Policy Objects** → New
- Name: `Workstation Security Baseline`
2. Configure:


Path: `User Configuration → Policies → Administrative Templates → Control Panel → Personalization`
- **Enable screen saver**: Enabled
- **Screen saver timeout**: 900 seconds (15 minutes)
- **Password protect the screen saver**: Enabled
3. Link to **Workstations OU**:
- Right-click OU → **Link an Existing GPO** → Select policy
📸 Screenshot:
Screensaver GPO

**Verification**:

- Log into test workstation → Wait 15 minutes → Verify screensaver locks
- Check applied policy:
```powershell
gpresult /r  # On workstation
```


### **Why These Policies Matter ?**  
- Password policy reduces brute-force attack success by more than 80%
- Screensaver locks prevent shoulder-surfing in open offices  
- USB restrictions mitigate malware introduction risks  















## 4. Helpdesk Simulation Workflows

**4.1 Password Reset**


**4.2 Account Lockout Troubleshooting**

## **5. Ticketing System Integration (Freshdesk)**
**5.1 Set Up Freshdesk**

**5.2 Log Mock Tickets**
https://upfion.com/9sRCb