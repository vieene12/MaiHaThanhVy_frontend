$ErrorActionPreference = 'Stop'

$env:ConnectionStrings__DefaultConnection = 'Server=localhost\SQLEXPRESS;Database=MaiHaThanhVy_AttendanceDB;Trusted_Connection=True;Encrypt=False;TrustServerCertificate=True;MultipleActiveResultSets=true'
$backendProject = Join-Path $PSScriptRoot '..\MaiHaThanhVy_Backend\MaiHaThanhVy_Backend.csproj'
& dotnet run --project $backendProject --no-launch-profile -- --urls 'http://0.0.0.0:5215'
exit $LASTEXITCODE
