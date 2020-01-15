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

# Optional 

class USR {
    # User
    hidden [string]$domain
    [string]$surName
    [string]$givenName
    hidden [int]$uniqueDigits
    hidden [string]$displayName
    [string]$userName
    [string]$email
    hidden [string]$sAMA
    hidden [string]$upn
    [string]$pw

    USR([string]$domain, [string]$givenName, [string]$surName)
    {
        $this.domain = $domain           # Set
        $this.surName = $surName         # Set
        $this.givenName = $givenName     # Set
        $this.uniqueDigits = (100..999) | Get-Random
        $this.displayName = $this.surName+', '+$this.givenName
        $this.userName = $this.givenName.Substring(0,2).ToLower()+$this.surName.Substring(0,2).ToLower()+$this.uniqueDigits
        $this.email = '{0}{1}@{2}' -f $this.givenName, $this.surName, $this.domain
        $this.sAMA = $this.userName
        $this.upn = '{0}@{1}' -f $this.userName, $this.domain
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
    -HomeDirectory $homeDir `
    -Enabled 1 `
    -PassThru

# Share
$letter = "Z:"     # SKRIV VILKEN BOKSTAV DISKEN SKA VA MAPPAD PÅ
$homeDir = 'C:\Users\'+$usr.userName  # BYT UT 'C:\Users\' MOT RÄTT SERVER

# Create Share
$homeDir = New-Item -path $homeDir -ItemType Directory -force

# Directory ACL
$acl = Get-Acl $homeDir

# Directory permissions
$fsRights = [System.Security.AccessControl.FileSystemRights]"Modify"
$aclType = [System.Security.AccessControl.AccessControlType]::Allow
$Inheritance = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
$Propagation = [System.Security.AccessControl.PropagationFlags]"InheritOnly"

# Directory rules 
$aclRule = New-Object System.Security.AccessControl.FileSystemAccessRule ($usr.upn, $fsRights, $Inheritance, $Propagation, $aclType)
$acl.AddAccessRule($aclRule)

# Apply homeDir access
Set-Acl -Path $homeDir -AclObject $acl 

# Export user information
$usr | export-csv .\new-users.csv -Encoding UTF8 -Delimiter ";" -NoTypeInformation -Append -Force
