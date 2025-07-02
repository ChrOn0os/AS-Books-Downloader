# 📘 AS-Books Downloader

A PowerShell script to download all preview pages of any magazines on [as-books.jp](https://www.as-books.jp).  
Automatically handles book id detection, parallel downloads, and displays a live progress bar with ETA

---

## ✨ Features

- 🧠 Automatically extracts book ID and total pages from magazine URL  
- 🚀 Multi-threaded image downloader (configurable concurrency if needed)  
- 📊 Live progress bar with the ETA
- 💾 Saves all pages to a folder with clean file names  

---

## 🔧 Requirements

- PowerShell 7+ (you can download it right [here](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)
- Internet connection
- Console with UTF-8 (should be already the case with Powershell 7) and Unicode font (only for Japanese characters, i recommand the "NSimSun" font)

---

## 📥 How to Use

1. **Download** the latest release.
2. Open a PowerShell 7 window
3. Change directory to where the script is located
4. Run the script:

   ```powershell
   .\AS-Books_Downloader.ps1
5. Paste the link of the magazine you want to download in it, and press Enter
6. The script will do everything for you, enjoy! 😄

---

⚠️ You might have an error because the script isn't signed, if that's the case, open a Powershell 7 window with admin rights and paste that in it, then press Enter: "set-executionpolicy unrestricted" ⚠️

---

if you have any problems, don't hesitate to contact me on Discord, I'll help you with pleasure ! (˶˃ ᵕ ˂˶)
