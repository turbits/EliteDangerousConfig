# elite dangerous x56 launch guard
# this little helper script only works with the Saitek X56 Rhino joy/throttle
# ===============
# @turbits
# https://github.com/turbits
# 16 December 2025
# ===============
# ensures saitek x56 joy/throttle are connected and
# custom binds file exists prior to game launch
#
# this helps with the issue of starting ED and the game using
# the incorrect keybinds because it cant find the correct devices
# ===============

param(
	[switch]$NoBackup
)

# CONFIG
$GameVersionMajor = "4"
$GameVersionMinor ="2"
$JoystickName = "SaitekX56Joystick"
$ThrottleName = "SaitekX56Throttle"
$JoystickVidPid = "VID_0738&PID_2221"
$ThrottleVidPid = "VID_0738&PID_A221"

$BindingsDir = Join-Path $env:LOCALAPPDATA "Frontier Developments\Elite Dangerous\Options\Bindings"
$BindsFile = Join-Path $BindingsDir ("turbits_x56.{0}.{1}.binds" -f $GameVersionMajor,$GameVersionMinor)
$BackupDir = "C:\temp\EDBindBackups"
$DateStamp = (Get-Date).ToString("ddMMMyyyy").ToLower() # ex: 16dec2025
$TimeStamp = (Get-Date).ToString("HHmmss") # ex: 183454 (18:34:54)
$BackupFile = Join-Path $BackupDir ("turbits_x56.{0}.{1}.binds.{2}.{3}.bak" -f $GameVersionMajor,$GameVersionMinor,$DateStamp,$TimeStamp)
$EliteSteamAppId = 359320


# HELPER FUNCTIONS
function Get-PresentPnpDevices {
	try {
		Get-PnpDevice -PresentOnly | Where {$_.Status -eq "OK"}
	} catch {
		Get-PnpDevice | Where {$_.Status -eq "OK"}
	}
}

function Test-X56DevicePresent {
	param(
		[Parameter(Mandatory)] [string]$FriendlyName,
		[Parameter(Mandatory)] [string]$VidPid,
		[Parameter(Mandatory)] $Devices
	)

	foreach ($device in $Devices) {
		$name = $device.FriendlyName
		$id = $device.InstanceId

		if ($name -and $name -eq $FriendlyDeviceName) {return $true}
		if ($id -and $id -match [regex]::Escape($VidPid)) {return $true}
	}

	return $false
}

# MAIN
if (-not (Test-Path $BindingsDir)) {
	Write-Error "Bindings folder not found: $BindingsDir"
	exit 1
}

if (-not (Test-Path $BindsFile)) {
	Write-Error "Bindings file not found: $BindsFile"
	exit 1
}

$devices = Get-PresentPnpDevices
$joystickTestOk = Test-X56DevicePresent -FriendlyName $JoystickName -VidPid $JoystickVidPid -Devices $devices
$throttleTestOk = Test-X56DevicePresent -FriendlyName $ThrottleName -VidPid $ThrottleVidPid -Devices $devices

if (-not $joystickTestOk) { Write-Error "X56 Joystick not detected. Can't find by name ($JoystickName) or vidpid ($JoystickVidPid). Not launching."; exit 1 }
if (-not $throttleTestOk) { Write-Error "X56 Throttle not detected.  Can't find by name ($ThrottleName) or vidpid ($ThrottleVidPid). Not launching."; exit 1 }

if (-not $NoBackup) {
	New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
	Copy-Item -Path $BindsFile -Destination $BackupFile -Force
}

$status = @"
X56 Joystick: $(if ($joystickTestOk) {"OK"} else {"ERROR"})
X56 Throttle: $(if ($throttleTestOk) {"OK"} else {"ERROR"})
Binding File: $(if (Test-Path $BindsFile) {"OK"} else {"MISSING"})
Backup: $(if (-not $NoBackup) {"OK ($BackupFile)"} else {"SKIPPED"})
"@

Write-Host $status
Write-Host "Launching Elite Dangerous..."
Start-Process ("steam://rungameid/{0}" -f $EliteSteamAppId)
exit 0
