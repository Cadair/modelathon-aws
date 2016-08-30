# Remove the local password limits
secedit /export /cfg c:\secpol.cfg
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
rm -force c:\secpol.cfg -confirm:$false

# Allow powershell scripts (for logon)
Set-ExecutionPolicy Unrestricted

# Make the user accounts
NET USER {team[username]} "{team[password]}" /ADD
NET LOCALGROUP "Remote Desktop Users" {team[username]} /ADD

NET USER {team[username]}a "{team[password]}" /ADD
NET LOCALGROUP "Remote Desktop Users" {team[username]}a /ADD

NET USER {team[username]}b "{team[password]}" /ADD
NET LOCALGROUP "Remote Desktop Users" {team[username]}b /ADD

NET USER {team[username]}c "{team[password]}" /ADD
NET LOCALGROUP "Remote Desktop Users" {team[username]}c /ADD

NET USER {team[username]}d "{team[password]}" /ADD
NET LOCALGROUP "Remote Desktop Users" {team[username]}d /ADD

NET USER {team[username]}e "{team[password]}" /ADD
NET LOCALGROUP "Remote Desktop Users" {team[username]}e /ADD

NET USER admin adminpassword /ADD
NET LOCALGROUP "Remote Desktop Users" admin /ADD
NET LOCALGROUP "Administrators" admin /ADD

# Configure VPN and Static Routes to Filesore
Add-VpnConnection -Name "Sheffield VPN" -ServerAddress "vpn.sheffield.ac.uk" `
  -TunnelType Pptp -EncryptionLevel Required -AuthenticationMethod MSChapv2 `
  -AllUserConnection  -RememberCredential -PassThru -SplitTunneling

Add-VpnConnectionRoute -ConnectionName "Sheffield VPN" -DestinationPrefix 172.30.1.0/24 -PassThru
Add-VpnConnectionRoute -ConnectionName "Sheffield VPN" -DestinationPrefix 172.26.3.0/24 -PassThru


# Write the logon script to c:\vpn.ps1
"rasdial 'Sheffield VPN' {team[username]} {team[rats]}`nnet use M: \\uosfstore.shef.ac.uk\Shared\{team[share]} /user:{team[username]}@shefuniad {team[password]}" | Out-File c:\vpn.ps1

# Create a Shortcut to the vpn startup script that will be executed at logon
$strAllUsersProfile = [io.path]::GetFullPath($env:AllUsersProfile)
$TargetFile = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" + " & 'C:\vpn.ps1'"
$ShortcutFile = $strAllUsersProfile + "\Start Menu\Programs\Startup\VPN.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-noexit & C:\vpn.ps1"
$Shortcut.Save()
