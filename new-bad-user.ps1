[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$domain,
    [Parameter(Mandatory=$true)]
    [string]$givenName,
    [Parameter(Mandatory=$true)]
    [string]$surName
)

# Error action
$ErrorActionPreference = "Stop"

class USR {
    # User
    [string]$domain
    [string]$surName
    [string]$givenName
    [int]$uniqueDigits
    [string]$displayName
    [string]$userName
    [string]$email
    [string]$sAMA
    [string]$upn
    [string]$pw

    USR([string]$domain, [string]$givenName, [string]$surName)
    {
        $this.domain = $domain           # Set
        $this.surName = $surName         # Set
        $this.givenName = $givenName     # Set
        $this.uniqueDigits = (100..999) | Get-Random
        $this.displayName = $this.surName+', '+$this.givenName
        $this.userName = $this.givenName.Substring(0,2).ToLower()+$this.surName.Substring(0,2).ToLower()+$this.uniqueDigits
        $this.email = $this.givenName+$this.surName+"@"+$this.domain
        $this.sAMA = $this.userName
        $this.upn = $this.userName+'@'+$this.domain
        $this.pw = 'Winter!'+$this.uniqueDigits
    }
}

# USR 
$usr =[USR]::new($domain, $givenName, $surName)

# Set Password
$pass = ConvertTo-SecureString $usr.pw -AsPlainText -Force

# New AD-User
New-AdUser `
    -server localhost `
    -givenName $usr.givenName `
    -surName $usr.surName `
    -DisplayName $usr.displayName `
    -sAMAccountName $usr.sAMA `
    -name $usr.userName `
    -EmailAddress $usr.email `
    -UserPrincipalName $usr.upn `
    -AccountPassword $pass `
    -HomeDrive $letter `
    -HomeDirectory $dirPath `
    -Enabled 1 `
    -PassThru # To see info in console

# Share
$letter = "Z:"     # SKRIV VILKEN BOKSTAV DISKEN SKA VA MAPPAD PÅ
$dirPath = 'C:\Users\'+$usr.userName  # BYT UT 'C:\Users\' MOT RÄTT SERVER

# Create Share
$homeDir = New-Item -path $dirPath -ItemType Directory -force

# Directory ACL
$acl = Get-Acl $dirPath

# Directory permissions
$fsRights = [System.Security.AccessControl.FileSystemRights]"Modify"
$aclType = [System.Security.AccessControl.AccessControlType]::Allow
$Inheritance = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
$Propagation = [System.Security.AccessControl.PropagationFlags]"InheritOnly"

# Directory rules 
$aclRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($usr.upn, $fsRights, $Inheritance, $Propagation, $aclType)
$acl.AddAccessRule($aclRule)

# Apply permission
Set-Acl -Path $dirPath -AclObject $acl 

# Export information
$usr | export-csv .\new-users.csv -Encoding UTF8 -Delimiter ";" -NoTypeInformation -Append -Force
