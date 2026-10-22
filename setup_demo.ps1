param(
    [string]$AdminEmail = 'admin@example.com',
    [string]$TeacherEmail = 'teacher1@example.com',
    [string]$StudentEmail = 'student1@example.com'
)

$ErrorActionPreference = 'Stop'
$backendDll = Join-Path $PSScriptRoot '..\MaiHaThanhVy_Backend\bin\Debug\net10.0\MaiHaThanhVy_Backend.dll'
if (-not (Test-Path -LiteralPath $backendDll)) {
    throw 'Build the backend first: dotnet build ..\MaiHaThanhVy_Backend\MaiHaThanhVy_Backend.csproj'
}

$env:ConnectionStrings__DefaultConnection = 'Server=localhost\SQLEXPRESS;Database=MaiHaThanhVy_AttendanceDB;Trusted_Connection=True;Encrypt=False;TrustServerCertificate=True;MultipleActiveResultSets=true'
$env:DEMO_ADMIN_EMAIL = $AdminEmail
$env:DEMO_TEACHER_EMAIL = $TeacherEmail
$env:DEMO_STUDENT_EMAIL = $StudentEmail

$seederProject = Join-Path $PSScriptRoot 'tools\DemoSeeder\DemoSeeder.csproj'
& dotnet run --project $seederProject --configuration Debug
exit $LASTEXITCODE
