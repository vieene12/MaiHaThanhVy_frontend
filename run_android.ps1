$ErrorActionPreference = 'Stop'

$projectRoot = $PSScriptRoot
$sdkLink = Join-Path $projectRoot '.flutter_sdk'
$flutterCommand = Get-Command flutter.bat -CommandType Application -ErrorAction Stop
$sdkRoot = Split-Path (Split-Path $flutterCommand.Source -Parent) -Parent

if (-not (Test-Path -LiteralPath $sdkLink)) {
    New-Item -ItemType Junction -Path $sdkLink -Target $sdkRoot | Out-Null
}

$link = Get-Item -LiteralPath $sdkLink
if ($link.LinkType -ne 'Junction' -or $link.Target -ne $sdkRoot) {
    throw ".flutter_sdk must be a junction to $sdkRoot"
}

$flutter = Join-Path $sdkLink 'bin\flutter.bat'
& $flutter run @args
exit $LASTEXITCODE
