. "$PSScriptRoot/lib/Common.ps1"
Assert-Admin
Write-Header "Restarting Audio Services"

Stop-Service "Audiosrv" -Force
Stop-Service "AudioEndpointBuilder" -Force

Start-Service "AudioEndpointBuilder"
Start-Service "Audiosrv"

Write-Host "Audio Stack Restarted. Test your sound now." -ForegroundColor Green