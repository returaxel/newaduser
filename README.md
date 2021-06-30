## Example of randomized batch user creation

It ain't much but it's honest work.

```PS
# Import CSV with givenName + surName as headers 
    $nameGen = Import-Csv .\nameGen.csv -Delimiter ";" -Encoding UTF8 -Header givenName, Surname
    
# How many accounts should be made
    [int]$ttr = 50

# Run loop
    for ($i = 0; $i -lt $ttr; $i++) {
        .\newaduser.ps1 ($nameGen.givenName | Get-Random) ($nameGen.surName | Get-Random)
    } 
```
