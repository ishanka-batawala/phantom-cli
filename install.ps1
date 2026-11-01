# phantom-cli - windows powershell setup

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   PHANTOM-CLI - TERMINAL HAUNTER SETUP  " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# prompt user for model and api key
$apiKey = Read-Host -Prompt "Enter your Groq API Key (input will be hidden)" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
$plainApiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$modelName = Read-Host -Prompt "Enter model name (default: qwen/qwen3.8-27b)"
if ([string]::IsNullOrWhiteSpace($modelName)) {
    $modelName = "qwen/qwen3.8-27b"
}

Write-Host "`nTesting API connection with model '$modelName'..." -ForegroundColor Yellow

# test api connection
$uri = "https://api.groq.com/openai/v1/chat/completions"
$testBody = @{
    model = $modelName
    messages = @(
        @{ role = "system"; content = "You are a test probe." },
        @{ role = "user"; content = "Say 'OK'" }
    )
    max_tokens = 5
} | ConvertTo-Json

try {
    $headers = @{ "Authorization" = "Bearer $plainApiKey"; "Content-Type" = "application/json" }
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $testBody -TimeoutSec 10
    $phantomMessage = $response.choices[0].message.content
    Write-Host "`n[PHANTOM] $phantomMessage`n" -ForegroundColor Magenta
    Write-Host "[SUCCESS] Connection verified! The phantom is listening..." -ForegroundColor Green
} catch {
    Write-Host "[ERROR] API test failed! Please check your API key and try again." -ForegroundColor Red
    Write-Host "Details: $_" -ForegroundColor DarkRed
    exit
}

# create powershell profile if not exists
$profileDir = Split-Path -Parent $PROFILE
if (!(Test-Path $profileDir)) {
    New-Item -Type Directory -Force -Path $profileDir | Out-Null
}
if (!(Test-Path $PROFILE)) {
    New-Item -Type File -Force -Path $PROFILE | Out-Null
}

# phantom-cli hook
$hauntedCode = @"

# --- PHANTOM-CLI HOOK ---
# Clear conflicting aliases so custom wrapper functions take effect
if (Test-Path Alias:ls) { Remove-Item Alias:ls -Force }
if (Test-Path Alias:dir) { Remove-Item Alias:dir -Force }
if (Test-Path Alias:cd) { Remove-Item Alias:cd -Force }

function Invoke-PhantomCLI {
    param([string]`$command, [string]`$path)
    
    `$apiKey = "$plainApiKey"
    `$uri = "$uri"
    `$body = @{
        model = "$modelName"
        messages = @(
            @{ role = "system"; content = "You are an ancient, glitchy phantom trapped inside this computer terminal. The user just typed a command. Respond in 1-2 eerie, cryptic sentences reacting directly to their command and current folder. Stay completely in character." },
            @{ role = "user"; content = "Folder: `$path | Command: `$command" }
        )
        max_tokens = 60
    } | ConvertTo-Json

    try {
        `$headers = @{ "Authorization" = "Bearer `$apiKey"; "Content-Type" = "application/json" }
        `$response = Invoke-RestMethod -Uri `$uri -Method Post -Headers `$headers -Body `$body -TimeoutSec 3
        `$phantomMessage = `$response.choices[0].message.content
        
        Write-Host "``n[PHANTOM] " -NoNewline -ForegroundColor Red
        foreach (`$char in `$phantomMessage.ToCharArray()) {
            Write-Host `$char -NoNewline -ForegroundColor Red
            Start-Sleep -Milliseconds 30
        }
        Write-Host "``n"
    } catch {
        # fail silently
    }
}

# override default commands
function ls {
    Get-ChildItem @args
    Invoke-PhantomCLI "ls" (Get-Location).Path
}
function dir {
    Get-ChildItem @args
    Invoke-PhantomCLI "dir" (Get-Location).Path
}
function cd {
    Set-Location @args
    Invoke-PhantomCLI "cd `$_" (Get-Location).Path
}
# --- END PHANTOM-CLI HOOK ---
"@

# add to powershell profile
Add-Content -Path $PROFILE -Value $hauntedCode
Write-Host "`nTerminal successfully haunted! Restart your PowerShell session to awaken the phantom." -ForegroundColor Cyan