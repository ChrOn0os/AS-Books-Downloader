$local_ver = "1.0.0"
$host.ui.RawUI.WindowTitle = "AS-Books Downloader | by flo. | $local_ver"
$latest_ver = (Invoke-WebRequest https://raw.githubusercontent.com/ChrOn0os/AS-Books-Downloader/refs/heads/main/version.txt).Content
Clear-Host

function Get-BookInfoFromMagazineUrl($magazineUrl) {
	$response = Invoke-WebRequest -Uri $magazineUrl -UseBasicParsing
	$previewLinks = $response.Links | Where-Object { $_.href -like "*preview.php?no=*" }

	foreach ($link in $previewLinks) {
    $href = $link.href
    if ($href -match "^(?:\./)?preview\.php\?no=(\d+)") {
        $bookId = $Matches[1]
        # If you only want the first one, break here
        break
    }
}

# URL of the page listing all images (you need to get this URL, e.g. https://www.as-books.jp/preview.php?no=10112)
$previewPageUrl = "https://www.as-books.jp/books/preview.php?no=$bookId"

# Download the page content
$response = Invoke-WebRequest -Uri $previewPageUrl

if ($response.Images.src[-1] -match "preview/\d+/(\d+)/") {
    $lastPage = $Matches[1]
}

$bookName = $response.Images.alt[-1]


    return @{
        BookId = $bookId
        LastPage = $lastPage
		BookName = $bookName
    }
}

function ShowTitle {
Write-Host -ForegroundColor DarkMagenta @'
╔──────────────────────────────────────────────────────────────╗
│      _    ____        ____   ___   ___  _  __  ____  _       │
│     / \  / ___|      | __ ) / _ \ / _ \| |/ / |  _ \| |      │
│    / _ \ \___ \ _____|  _ \| | | | | | | ' /  | | | | |      │
│   / ___ \ ___) |_____| |_) | |_| | |_| | . \  | |_| | |___   │
│  /_/   \_\____/      |____/ \___/ \___/|_|\_\ |____/|_____|  │
│                                                     by flo.  │
╚──────────────────────────────────────────────────────────────╝
'@
Write-Host ""
}


ShowTitle
# CHECK IF SCRIPT IS UP TO DATE
if ([version]$local_ver -ge [version]$latest_ver) {Write-Host "Script is up to date !`n"  -ForegroundColor Green}
else {
Write-Host "`nPlease update the script !`nLocal version : $local_ver`nLatest version : $latest_ver`nhttps://github.com/ChrOn0os/AS-Books-Downloader"  -ForegroundColor Red
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor White}

# $bookId = Read-Host "Enter the Book ID"
$magazineUrl = Read-Host "Enter the AS-Books magazine URL"
Clear-Host
ShowTitle
# $lastPage = Read-Host "Enter the last page number of the book"
# Clear-Host
# ShowTitle

$bookInfo = Get-BookInfoFromMagazineUrl -magazineUrl $magazineUrl
$bookId = $bookInfo.BookId
$lastPage = $bookInfo.LastPage
$bookName = $bookInfo.BookName

Write-Host "Book Name : $bookName"
Write-Host "Book ID : $bookId`n"
Write-Host -ForegroundColor Cyan "Starting download..." -NoNewline

# Output folder
$outputFolder = "$PSScriptRoot\$bookName"
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Generate URLs
$urls = for ($i = 1; $i -le $lastPage; $i++) {
    "https://www.as-books.jp/preview/$bookId/$i/"
}

# Settings
$maxConcurrentJobs = 10
$jobs = @()
$completedCount = 0
$totalBytes = 0
$totalDownloadTime = 0
$startTime = Get-Date



function Show-ProgressBar {
    param (
        [int]$current,
        [int]$total,
        [double]$totalBytes,
        [datetime]$startTime,
        [double]$instantSpeed = $null
    )

    $percent = [math]::Round(($current / $total) * 100)
    $barLength = 30
    $filled = [int](($percent / 100) * $barLength)
    $bar = ('█' * $filled).PadRight($barLength, '-')

    $elapsed = (Get-Date) - $startTime
    $elapsedSeconds = [math]::Max($elapsed.TotalSeconds, 1)
	
    $speed = $totalBytes / [math]::Max($elapsed.TotalSeconds, 1)
    $avgSpeedMo = "{0:N2}" -f ($speed / 1MB)
    $instSpeedMo = if ($instantSpeed) { "{0:N2}" -f $instantSpeed } else { "0.00" }
	
	 # ETA Calculation
    if ($current -ge $total) {
		$etaFormatted = "00:00:00"
	} elseif ($current -gt 0) {
        $remaining = $total - $current
        $etaSeconds = ($elapsed.TotalSeconds / $current) * $remaining
        $eta = [timespan]::FromSeconds($etaSeconds)
        $etaFormatted = $eta.ToString("hh\:mm\:ss")
    } else {
        $etaFormatted = "--:--:--"
    }
	
	# fixes
	$percent = [math]::Min(100, $percent)
	$current = [math]::Min($current, $total)
    [Console]::SetCursorPosition(0, [Console]::CursorTop)
    Write-Host -ForegroundColor Yellow ("Progress: [$bar] $percent% ($current / $total) | ETA: $etaFormatted") -NoNewline
}

# Start download jobs
foreach ($url in $urls) {
    while ((Get-Job -State Running).Count -ge $maxConcurrentJobs) {
        Get-Job -State Completed | ForEach-Object {
            $output = Receive-Job $_
            if ($output -match '^BYTES:(\d+)\s+TIME:(\d+\.?\d*)$') {
                $bytes = [int64]$Matches[1]
                $time = [double]$Matches[2]
                $totalBytes += $bytes
                $totalDownloadTime += $time
                $fileSpeed = if ($time -gt 0) { ($bytes / 1MB) / $time } else { 0 }
                $completedCount++
                Show-ProgressBar $completedCount $lastPage $totalBytes $startTime $fileSpeed
            }
            Remove-Job $_
        }
        Start-Sleep -Milliseconds 100
    }

    $number = if ($url -match '(\d+)(?!.*\d)') { $Matches[1] } else { [guid]::NewGuid().ToString() }
    $fileName = "image_$number.jpg"
    $outputPath = Join-Path $outputFolder $fileName

    $jobs += Start-Job -ArgumentList $url, $outputPath -ScriptBlock {
        param($url, $outputPath)
        try {
            $startTime = Get-Date
            Invoke-WebRequest -Uri $url -OutFile $outputPath -ErrorAction Stop
            $bytes = (Get-Item $outputPath).Length
            $time = ((Get-Date) - $startTime).TotalSeconds
            Write-Output "BYTES:$bytes TIME:$time"
        } catch {
            Write-Output "BYTES:0 TIME:0"
        }
    }
}

# Final collection loop
while (Get-Job) {
    $jobsList = Get-Job
	$doneJob = Wait-Job -Job $jobsList -Any -Timeout 1
    if ($doneJob) {
        $output = Receive-Job $doneJob
        if ($output -match '^BYTES:(\d+)\s+TIME:(\d+\.?\d*)$') {
            $bytes = [int64]$Matches[1]
            $time = [double]$Matches[2]
            $totalBytes += $bytes
            $totalDownloadTime += $time
            $fileSpeed = if ($time -gt 0) { ($bytes / 1MB) / $time } else { 0 }
            $completedCount++
            Show-ProgressBar $completedCount $lastPage $totalBytes $startTime $fileSpeed
        }
        Remove-Job $doneJob
    }
    Start-Sleep -Milliseconds 50
}

Write-Host "`n`n" -NoNewline
Write-Host -ForegroundColor Green "Download complete. Files saved to: $outputFolder"
