# Acrobat Droplets & Hot Folder ⚙️📁

**Automated Preflight & Sorting Workflow for Adobe Acrobat Pro**

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg) ![Platform](https://img.shields.io/badge/platform-Windows-lightgrey) ![Language](https://img.shields.io/badge/language-PowerShell-blue) ![App](https://img.shields.io/badge/app-Adobe%20Acrobat%20Pro-red)

## Overview

**Acrobat Droplets & Hot Folder** is a background automation tool designed for DTP operators and prepress professionals. It monitors a designated "hot folder" for incoming PDF files, automatically processes them using Adobe Acrobat Pro's Preflight engine (via Droplets), and sorts them into "Correct" or "Incorrect" folders. Erroneous files are accompanied by a detailed text report explaining the exact preflight failures.

This solution eliminates manual file checking, saves hours of repetitive prepress work, and runs silently in the background without interrupting your active design workflow.

**Perfect for:** Busy print production environments, standardizing incoming client files, and reducing manual prepress errors.

---

## ✨ Key Features

### Zero-Click Automation
- **Watch & Execute**: Just drop a PDF into the hot folder. The script instantly detects the new file and handles the preflight process automatically.
- **Background Processing**: Runs completely out of sight. The `-Wait` flag intelligently queues multiple files to prevent Acrobat from freezing when handling large batches.

### Smart File Queuing
- **File Lock Detection**: Uses PowerShell's `FileSystemWatcher` with a retry loop to ensure large PDFs (especially over network drives) are completely copied and unlocked by the OS before sending them to Acrobat.

### Auto-Sorting & Reporting
- **Correct Folder**: Good files go straight to production without any unnecessary logs.
- **Incorrect Folder**: Bad files are isolated alongside a lightweight `.txt` report detailing exactly what rules were broken (e.g., RGB images, low resolution, missing bleeds).

### Portable Architecture
- **Relative Paths**: The PowerShell script uses `$PSScriptRoot`. You can move the entire project folder to any local drive without breaking the script's core logic.

---

## 💧 What is an Acrobat Droplet?

A **Droplet** is a small executable (`.exe`) file generated directly by Adobe Acrobat Pro. It acts as a standalone wrapper for a specific Preflight profile. 

When a PDF is passed to a Droplet, Acrobat automatically opens the file, runs the embedded preflight checks, applies any programmed fixups, and moves the final output to a pre-configured destination folder. In this project, PowerShell acts as the "messenger" that hands the PDF over to the Droplet.

---

## 🚀 Setup & Installation

### Prepare the Folder Structure
Ensure your main project folder contains the following setup:
```text
[Main Project Folder]
 ├── Correct/          (Good PDFs will be moved here)
 ├── Hot_folder/       (Drop new client PDFs here)
 ├── Incorrect/        (Failed PDFs + text reports go here)
 └── Script/
      ├── PdfDropletMonitor.ps1
      ├── Stop-PdfDropletMonitor.ps1
      └── droplet.exe  (You will generate this in Step 2)

### Create the Acrobat Droplet
1. Open **Adobe Acrobat Pro** and navigate to **Print Production > Preflight**.
2. Select or create your comprehensive Preflight profile (e.g., "Standard Print Check").
3. Click the **Options** menu (gear icon or top-right dropdown) and select **Create Droplet**.
4. **Configure Success Settings**:
   - Check **Move PDF file to success folder**.
   - Browse and select your `Correct` folder.
   - *Crucial:* **Uncheck** the option to create a report (keep successful files clean).
5. **Configure Error Settings**:
   - Check **Move PDF file to error folder**.
   - Browse and select your `Incorrect` folder.
   - Check **Create report and save in error folder** and select **Text report** from the format dropdown.
6. **Final Tweak**: Uncheck **Display a summary PDF** at the bottom of the window to ensure silent operation.
7. Click **Save** and save the file as `droplet.exe` inside the `Script` folder.

*Note: While the PowerShell script uses relative paths, Acrobat Droplets bake absolute paths for the Success/Error folders into the `.exe`. If you move your main project folder to a different drive later, you must recreate or edit the Droplet in Acrobat to point to the new folder locations.*

### Configure Acrobat Security (Windows)
Acrobat's internal sandbox blocks Droplets from moving files by default. To fix this:
1. In Acrobat, go to `Edit > Preferences` (Ctrl+K).
2. Go to **Security (Enhanced)**.
3. **Uncheck** `Enable Protected Mode at startup`.
4. Fully close and restart Acrobat Pro.

---

## 📖 Usage Guide

### Running the Automation Silently
You can run the script normally, but for a professional DTP workflow, it is best to run it hidden in the background so it doesn't clutter your screen with console windows.

**Create a Silent Shortcut:**
1. Right-click on your desktop (or inside your project folder) and select **New > Shortcut**.
2. In the location box, paste the following command (adjust the path to match where your `.ps1` file is located):
   ```cmd
   powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Your\Path\To\Script\Start-Preflight.ps1"
3. Name it "Start Preflight Monitor".
4. Double-click this shortcut. The script will now monitor the hot folder completely in the background.

### Stopping the Automation
Because the script runs hidden, you cannot simply close it with an "X". To stop monitoring:

1. Open Task Manager (`Ctrl+Shift+Esc`).
2. Find `Windows PowerShell` in background processes and click End Task.
3.  *Alternatively*, create a file named Stop-Preflight.ps1 with the following code and run it to safely kill the background watcher:

    ```powershell
    Get-Process powershell | Where-Object { $_.MainWindowTitle -eq "" } | Stop-Process -Force

## 💡 Pro Tips

- **Keep Acrobat Open**: The Droplet responds much faster and more reliably if the main Acrobat Pro application is already open (even if minimized to the tray) before you drop files into the hot folder.
- **Merge Your Checks**: Instead of creating multiple droplets for different checks (e.g., one for 300ppi, one for RGB), combine all your rules into one single Custom Preflight Profile. This processes the PDF once and generates a single, easy-to-read text report.
- **Network Safe**: The script includes a 60-second retry loop. If you are rendering a massive PDF straight out of InDesign into the hot folder, the script will patiently wait for the file to finish writing before triggering the preflight.

## 📄 License

This project is licensed under the **MIT License**.

---

*Created by a DTP professional for professionals.*