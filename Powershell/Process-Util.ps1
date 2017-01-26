
function Stop-ProcessIfRunning($procName) {
  Write-Output "Stop-ProcessIfRunning: $procName" -ForegroundColor Yellow
  if ((Get-Process $procName) -eq $Null){ 
        Write-Output "$procName Not Running" 
  } else { 
    Write-Output "$procName Running - stopping..." -ForegroundColor Yellow
    Stop-Process -processname $procName -Force
  }
}
