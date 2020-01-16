<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    > .\newaduser.ps1 (domain) givenname surname
    Will create a user with gisu and three random digits, ex, gisu666
.INPUTS
    Inputs
.OUTPUTS
    Output
.NOTES
    Users are created in the default user ou unless specified
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$givenName,
    [Parameter(Mandatory=$true)]
    [string]$surName
)

$ErrorActionPreference = "Stop"

# Domain 
$domain = 'wsone.ad'

# Export CSV path
$CSV = '.\new-usr.csv'

# Create share y/N
[bool]$share = 0

#-----------------------------------------------------------[Classes]--------------------------------------------------------------

class USR {
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
        $this.domain = $domain
        $this.surName = $surName
        $this.givenName = $givenName
        $this.uniqueDigits = (100..999) | Get-Random
        $this.displayName = $this.surName+', '+$this.givenName
        $this.userName = $this.givenName.Substring(0,2).ToLower()+$this.surName.Substring(0,2).ToLower()+$this.uniqueDigits
        $this.email = '{0}.{1}@{2}' -f $this.givenName, $this.surName, $this.domain
        $this.sAMA = $this.userName
        $this.upn = '{0}@{1}' -f $this.userName, $this.domain
        $this.pw = 'Winter!'+$this.uniqueDigits
    }
}

#-----------------------------------------------------------[Create-User]----------------------------------------------------------

# Create new object USR 
$usr =[USR]::new($domain, $givenName, $surName)

# Set a valid password param
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

#-----------------------------------------------------------[Create-Share]---------------------------------------------------------

if ($share -eq $true) {
    # Share settings
    $letter = "Z:"                          # EDIT ME
    $homeDir = 'C:\Users\'+$usr.userName    # EDIT ME

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
}

#-----------------------------------------------------------[Export-CSV]-----------------------------------------------------------

$usr | export-csv $CSV -Encoding UTF8 -Delimiter ";" -NoTypeInformation -Append -Force