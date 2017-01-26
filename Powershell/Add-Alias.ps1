param(
  [parameter(Mandatory=$true, Position=0)][ValidateSet('user','alluser')] $visibility,
  [parameter(Mandatory=$true, Position=1)][string] $aliasName,
  [parameter(Mandatory=$true, Position=2)][string] $aliasTarget
)

$profilepath = switch ($visibility) {
                                      'user'      { $PROFILE.CurrentUserCurrentHost }
                                      'alluser'   { $PROFILE.AllUsersAllHosts }
                                    }

Write-Output "Add-Alias: $aliasName -> $aliasTarget"
Write-Output "using profile $profilepath"

if (-Not (Test-Path $profilepath)) {
  Write-Output "PS profile $profilepath does not exist yet - creating one!"
  New-Item -Path $profilepath -ItemType File
}


$checkExists = $(Select-String -Path $profilepath -Pattern "New-Alias .*$aliasName .*")
if ($checkExists) {
  Write-Output "the alias seems to exist .. skipping"
  Write-Output "$checkExists"
} else {
  "`nNew-Alias -Name $aliasName -Value $aliasTarget" | Out-File -Append $profilepath -Encoding utf8
}