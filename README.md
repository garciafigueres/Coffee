# ☕ Coffee.ps1

**Coffee.ps1** is a PowerShell utility that keeps your system "awake" by periodically toggling the Scroll Lock key. It runs silently in the background with a system tray icon and offers a contextual menu for manual control and customization.

---

## 🔧 Features

- Prevents system sleep by blinking the Scroll Lock key at set intervals
- Tray icon reflects current status:
  - Coffee ON/OFF
  - Scroll Lock ON/OFF
  - Blinking animation
- Manual toggle for Coffee mode and Scroll Lock
- Customizable blink interval (10, 20, 30, or 60 seconds)
- Context menu for quick access and control
- Graceful exit via tray menu

---

## 🚀 How to Run

Use the following shortcut to launch the script silently:

```powershell
powershell.exe -WindowStyle Hidden -File "C:\DEV\_Snippets\Scripts\Coffee\Coffee.ps1"
