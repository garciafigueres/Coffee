# Shortcut:
# powershell.exe -WindowStyle Hidden -File "C:\DEV\_Snippets\Scripts\Coffee\Coffee.ps1"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$iconPath = Join-Path $scriptPath "ico"

function Load-Icon($filename) {
    $fullPath = Join-Path $iconPath $filename
    if (Test-Path $fullPath) {
        try {
            return New-Object System.Drawing.Icon($fullPath)
        } catch {
            Write-Log "Error loading icon: $filename. Using default icon."
            return [System.Drawing.SystemIcons]::Information
        }
    } else {
        Write-Log "Icon not found: $filename. Using default icon."
        return [System.Drawing.SystemIcons]::Information
    }
}

function Write-Log($message) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $message"
}

$icon_CON_SLON   = Load-Icon "CON_SLON.ico"
$icon_CON_SLOFF  = Load-Icon "CON_SLOFF.ico"
$icon_COFF_SLON  = Load-Icon "COFF_SLON.ico"
$icon_COFF_SLOFF = Load-Icon "COFF_SLOFF.ico"
$icon_BLINK      = Load-Icon "BLINK.ico"

$icon = New-Object System.Windows.Forms.NotifyIcon
$icon.Visible = $true

$WShell = New-Object -ComObject "WScript.Shell"

$global:coffeeEnabled = $true
$global:lastScrollLockState = $null
$global:blinkInterval = 60000  # ⏱ Producción: 60000 ms (60 seg). Para pruebas: 5000 ms

function Update-Icon {
    $scrollLockOn = [System.Windows.Forms.Control]::IsKeyLocked([System.Windows.Forms.Keys]::Scroll)

    if ($global:coffeeEnabled) {
        if ($scrollLockOn) {
            $icon.Icon = $icon_CON_SLON
            $icon.Text = "Coffee: ON | Scroll Lock: ON"
            Write-Log "Coffee: Enabled | Scroll Lock: ON"
        } else {
            $icon.Icon = $icon_CON_SLOFF
            $icon.Text = "Coffee: ON | Scroll Lock: OFF"
            Write-Log "Coffee: Enabled | Scroll Lock: OFF"
        }
    } else {
        if ($scrollLockOn) {
            $icon.Icon = $icon_COFF_SLON
            $icon.Text = "Coffee: OFF | Scroll Lock: ON"
            Write-Log "Coffee: Disabled | Scroll Lock: ON"
        } else {
            $icon.Icon = $icon_COFF_SLOFF
            $icon.Text = "Coffee: OFF | Scroll Lock: OFF"
            Write-Log "Coffee: Disabled | Scroll Lock: OFF"
        }
    }

    $global:lastScrollLockState = $scrollLockOn
}

function Toggle-Coffee {
    $global:coffeeEnabled = -not $global:coffeeEnabled
    if ($global:coffeeEnabled) {
        Write-Log "Manual action: Toggle Coffee => Enabled"
    } else {
        Write-Log "Manual action: Toggle Coffee => Disabled"
    }
    Update-Icon
    Update-Menu
}

function Update-Menu {
    # Actualiza el texto del ítem Coffee
    # if ($global:coffeeEnabled) {
    #     $toggleCoffeeItem.Text = "[*] Toggle Coffee"
    # } else {
    #     $toggleCoffeeItem.Text = "[ ] Toggle Coffee"
    # }

    # Actualiza el texto del ítem Scroll Lock
    # $scrollLockOn = [System.Windows.Forms.Control]::IsKeyLocked([System.Windows.Forms.Keys]::Scroll)
    # if ($scrollLockOn) {
    #     $toggleScrollItem.Text = "[*] Toggle Scroll Lock"
    # } else {
    #     $toggleScrollItem.Text = "[ ] Toggle Scroll Lock"
    # }

    # Actualiza el submenú de intervalos
    foreach ($item in $intervalMenu.MenuItems) {
        $seconds = [int]$item.Tag
        if ($global:blinkInterval -eq ($seconds * 1000)) {
            $item.Text = "$seconds [*]"
        } else {
            $item.Text = "$seconds"
        }
    }
}

# Timer 1: Parpadeo Scroll Lock
$blinkTimer = New-Object System.Windows.Forms.Timer
$blinkTimer.Interval = $global:blinkInterval
$blinkTimer.Add_Tick({
    if ($global:coffeeEnabled) {
        $icon.Icon = $icon_BLINK
        $icon.Text = "Coffee: BLINKING..."
        Write-Log "Coffee: BLINKING Scroll Lock"

        $WShell.SendKeys("{SCROLLLOCK}")
        Start-Sleep -Milliseconds 100
        $WShell.SendKeys("{SCROLLLOCK}")

        Update-Icon
    }
})

# Timer 2: Monitor Scroll Lock manual
$monitorTimer = New-Object System.Windows.Forms.Timer
$monitorTimer.Interval = 500
$monitorTimer.Add_Tick({
    $currentScrollLock = [System.Windows.Forms.Control]::IsKeyLocked([System.Windows.Forms.Keys]::Scroll)
    if ($currentScrollLock -ne $global:lastScrollLockState) {
        Update-Icon
    }
})

# Menú contextual
$menu = New-Object System.Windows.Forms.ContextMenu
$toggleCoffeeItem = New-Object System.Windows.Forms.MenuItem "Toggle Coffee"
$toggleCoffeeItem.add_Click({ Toggle-Coffee })
$menu.MenuItems.Add($toggleCoffeeItem)

$toggleScrollItem = New-Object System.Windows.Forms.MenuItem "Toggle Scroll Lock"
$toggleScrollItem.add_Click({
    Write-Log "Manual action: Menu => Toggle Scroll Lock"
    $WShell.SendKeys("{SCROLLLOCK}")
    Start-Sleep -Milliseconds 100
    Update-Icon
})
$menu.MenuItems.Add($toggleScrollItem)

$intervalMenu = New-Object System.Windows.Forms.MenuItem "Set Blink Interval (sec)"
foreach ($sec in @(10, 20, 30, 60)) {
    $item = New-Object System.Windows.Forms.MenuItem "$sec"
    $item.Tag = $sec
    $item.add_Click({
        $selectedSec = [int]$this.Tag
        $global:blinkInterval = $selectedSec * 1000
        $blinkTimer.Interval = $global:blinkInterval
        Write-Log "Manual action: Set blink interval => $selectedSec seconds"
        Update-Menu
    })
    $intervalMenu.MenuItems.Add($item)
}
$menu.MenuItems.Add($intervalMenu)

$exitItem = New-Object System.Windows.Forms.MenuItem "Exit"
$exitItem.add_Click({
    Write-Log "Manual action: Exit script"
    $icon.Visible = $false
    $blinkTimer.Stop()
    $monitorTimer.Stop()
    [System.Windows.Forms.Application]::Exit()
})
$menu.MenuItems.Add($exitItem)

$icon.ContextMenu = $menu

# Eventos del icono
$icon.add_MouseClick({
    if ($_.Button -eq "Left") {
        Write-Log "Manual action: Single left click => Toggle Scroll Lock"
        $WShell.SendKeys("{SCROLLLOCK}")
        Start-Sleep -Milliseconds 100
        Update-Icon
    }
})

$icon.add_MouseDoubleClick({
    if ($_.Button -eq "Left") {
        Toggle-Coffee
    }
})

Update-Icon
Update-Menu
$blinkTimer.Start()
$monitorTimer.Start()

[System.Windows.Forms.Application]::Run()
