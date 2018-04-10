param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
    [ScriptBlock]$scriptBlock,
    
    [Parameter(Mandatory = $False)]
    [pscredential]$Credential
)

$myRandom = $([System.Guid]::NewGuid())
$myTmpPath = $([System.IO.Path]::GetTempPath())
$elevatedTextOutputFile = $(Join-Path $myTmpPath "$myRandom.elevated.log")
  
$scriptBlockString = $scriptBlock.ToString()
$captureElevatedScriptBlock = @"
try {
    `$ErrorActionPreference = 'Stop'
    & { $scriptBlockString } | Tee-Object $elevatedTextOutputFile
} catch {
    Write-Output `$_
    if (-Not `$lastexitcode) {
        `$lastexitcode = 1
    }
} finally {
    if (-Not `$lastexitcode) {
        `$lastexitcode = 0
    }
    exit `$lastexitcode
}
"@

$myWd = $(Get-Location).Path
$startElevatedProcessArgs = @{
    FilePath     = "PowerShell.exe"
    PassThru     = $true
    WorkingDir   = "$myWd"
    Verb         = "runas"
    ArgumentList = @("-Command", "& { Set-Location '$myWd'; $captureElevatedScriptBlock }")
}

if (-Not $Credential) {
    # easy: run with the current user context
    $p = Start-Process @startElevatedProcessArgs -Wait
    $p.WaitForExit()
    $res = @{
        ExitCode = $p.ExitCode
        Output   = Get-Content $elevatedTextOutputFile
    }
}
else {
    # tricky: need to switch to a new session with given credentials ...
    # this session then needs to run the above code actually calling the elevated session
    $wrapperScript = Join-Path $myTmpPath "$myRandom.magic.ps1"
    $wrapperScriptLog = "$wrapperScript.log"

    @"
    `$startElevatedProcessArgs = @{
        FilePath     = `"PowerShell.exe"
        PassThru     = `$true
        WorkingDir   = '$myWd'
        Verb         = "runas"
        ArgumentList = @(`"-noexit`",`"-Command`", `"& { Set-Location '$myWd'; $($captureElevatedScriptBlock.Replace("`$","```$")) }")
    }
    `$p = Start-Process `@startElevatedProcessArgs -Wait
    `$p.WaitForExit()
    exit `$p.ExitCode
"@ | Out-File $wrapperScript -Encoding default

    $startWithCredentialsArgs = @{
        FilePath               = "PowerShell.exe"
        PassThru               = $true
        WorkingDir             = $myWd
        ArgumentList           = @("-ExecutionPolicy bypass", "-noprofile", "-noninteractive", "-Command", "& { Set-Location '$myWd'; $wrapperScript }")
        Credential             = $Credential
        RedirectStandardOutput = $wrapperScriptLog
    }

    $p = Start-Process @startWithCredentialsArgs -Wait
    $p.WaitForExit()
    Remove-Item $wrapperScript

    $res = @{
        ExitCode      = $p.ExitCode
        Output        = Get-Content $elevatedTextOutputFile
        WrapperOutput = Get-Content $wrapperScriptLog
    }
    Remove-Item $wrapperScriptLog
}

Remove-Item $elevatedTextOutputFile
$res