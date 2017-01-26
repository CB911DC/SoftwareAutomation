

function InstallService([string]$pathToService, $startType = "auto") {
  $svcExe = Get-Item $pathToService
  $svcFullPath = $svcExe.FullName
  $svcName = $svcExe.BaseName

  Write-Output "installing $pathToService as service, startType = $startType" -ForegroundColor Yellow
  Write-Output "using name $svcName for service" -ForegroundColor Yellow

  cmd /c "sc create $svcName binpath= `"$svcFullPath`""
  cmd /c "sc description $svcName $svcName"
  cmd /c "sc config $svcName start= $startType"
  cmd /c "sc start $svcName"
}


function UnInstallService([string]$serviceName) {
  Write-Output "un-installing service $serviceName" -ForegroundColor Yellow
  cmd /c "sc stop $serviceName"
  cmd /c "sc delete $serviceName"
}
