<#
	PowerShell script to internalize chocolatey packages from the community feed to an internal server using the business edition 'internalize' feature.
	This script is designed to be run from jenkins, P_* variables are defined in jenkins job!
#> 
# section CREDS
	$pkgs = $env:P_PKGLIST
	$uncshare = $env:P_UNC_SHARE
	$targetserver = $env:P_DST_SRV
	$apikey = $env:P_API_KEY

	$envtmp = $env:temp
	$tmpdir = "$envtmp\chocointernalize"
	$basefeed = "https://chocolatey.org/api/v2/"
# endsection

function InternalizePkg($pkg) {
	Push-Location $tmpdir
	choco download --internalize $pkg --resources-location="$uncshare\$pkg" --source="$basefeed"
	$genpkg = ((Get-ChildItem *.nupkg -recurse).FullName | Select-String -Pattern $pkg)
	choco push $genpkg --source="$targetserver" --api-key="$apikey" -Verbose
        Write-Output "------------------------------------------------------------------------"
        Write-Output ""
	Pop-Location
}

if ((Test-Path $tmpdir)) {
	Remove-Item $tmpdir -Recurse -Force -Verbose
}
New-Item $tmpdir -ItemType Directory -Force -Verbose

$pkgs | ForEach-Object {
	InternalizePkg $_
}

Remove-Item $tmpdir -Recurse -Force -Verbose
