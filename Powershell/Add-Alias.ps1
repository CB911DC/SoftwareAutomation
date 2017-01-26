param(
  [parameter(Mandatory=$true, Position=0)][ValidateSet('user','alluser')] $visibility,
  [parameter(Mandatory=$true, Position=1)][string] $aliasName,
  [parameter(Mandatory=$true, Position=2)][string] $aliasTarget
)

$profilepath = switch ($visibility) {
                                      'user'      { $PROFILE.CurrentUserCurrentHost }
                                      'alluser'   { $PROFILE.AllUsersAllHosts }
                                    }

if (-Not $profilepath) {
  if ($profilepath -And (-Not $PROFILE)) {
    Write-Warning "this is awkwark - could not determine your PS session, using fallback (alluser)"
    $profilepath = Join-Path $env:windir "System32\WindowsPowerShell\v1.0\profile.ps1"
  } else {
    Write-Warning "this is awkwark - could not determine your PS session, using fallback (current profile)"
    $profilepath = $PROFILE
  }
}

Write-Output "Add-Alias: $aliasName -> $aliasTarget"
Write-Output "using profile $profilepath"

if (-Not (Test-Path $profilepath)) {
  Write-Warning "PS profile $profilepath does not exist yet - creating one!"
  New-Item -Path $profilepath -ItemType File
}

$checkExists = $(Select-String -Path $profilepath -Pattern "New-Alias .*$aliasName .*")
if ($checkExists) {
  Write-Warning "the alias seems to exist .. skipping"
  Write-Output "$checkExists"
} else {
  "`nNew-Alias -Name $aliasName -Value $aliasTarget" | Out-File -Append $profilepath -Encoding utf8
}