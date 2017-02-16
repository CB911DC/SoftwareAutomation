<#
	PowerShell script to sync chocolatey packages between servers using the business edition 'internalize' feature.
	This script is designed to be run from jenkins, P_* variables are defined in jenkins job!
#>
# section CREDS
	$sourceStream = $env:P_SRC_SRV
	$targetserver = $env:P_DST_SRV
	$apikey = $env:P_API_KEY
	$uncshare = $env:P_UNC_SHARE
# endsection

$envtmp = $env:temp
$tmpdir = "$envtmp\chocosync"

if ((Test-Path $tmpdir)) {
	Remove-Item $tmpdir -Recurse -Force -Verbose
}
New-Item $tmpdir -ItemType Directory -Force -Verbose

$pkglist = $(choco list -source="$sourceStream" -a)
$packageInfoMap = @{}

Foreach ($line in $pkglist ) {
	$_l = $line.Split(' ')
	if ($_l.Count -eq 2) {
		$_l[0] = $_l[0].Trim()
		$_l[1] = $_l[1].Trim()
		if ($_l[0] -eq "") {
			continue
		}
		if (!($packageInfoMap.ContainsKey($_l[0]))) {
				$packageInfoMap[$_l[0]] = @()
		}
		$packageInfoMap[$_l[0]] += $_l[1]  
	}
}
Write-Output "syncing packages..."
Write-Output "-------------------------------------------------------"
$packageInfoMap
Write-Output "-------------------------------------------------------"

function syncThisPkgVer($pkg, $ver) {	
	Write-Host "syncing $pkg, version $ver"
	Push-Location $tmpdir
	choco download --recompile $pkg --version=$ver --resources-location="$uncshare\$pkg" -source="$sourceStream" 
	$genpkg = ((Get-ChildItem *.nupkg -recurse).FullName | Select-String -Pattern $pkg)
	choco push $genpkg -source="$targetserver" -api-key="$apikey" -Verbose
	Write-Output "------------------------------------------------------------------------"
	Write-Output ""
	Pop-Location
}

Foreach ($pkgName in $packageInfoMap.Keys) {
	$pkgVers = $packageInfoMap[$pkgName]
	Foreach ($ver in $pkgVers) {
		syncThisPkgVer $pkgName $ver
	}
}

Remove-Item $tmpdir -Recurse -Force -Verbose
