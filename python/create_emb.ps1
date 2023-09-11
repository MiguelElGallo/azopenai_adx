Write-Host ""
Write-Host "Loading azd .env file from current environment"
Write-Host ""

$output = azd env get-values

foreach ($line in $output) {
  if (!$line.Contains('=')) {
    continue
  }

  $name, $value = $line.Split("=")
  $value = $value -replace '^\"|\"$'
  [Environment]::SetEnvironmentVariable($name, $value)
  Write-Host "Setting $name"
}

Write-Host "Environment variables set."

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
  # fallback to python3 if python not found
  $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
}

Write-Host 'Creating python virtual environment "scripts/.venv"'
Start-Process -FilePath ($pythonCmd).Source -ArgumentList "-m venv ./python/.venv" -Wait -NoNewWindow

$venvPythonPath = "./python/.venv/scripts/python.exe"
if (Test-Path -Path "/usr") {
  # fallback to Linux venv path
  $venvPythonPath = "./python/.venv/bin/python"
}

Write-Host 'Installing dependencies from "requirements.txt" into virtual environment'
Start-Process -FilePath $venvPythonPath -ArgumentList "-m pip install -r ./python/requirements.txt" -Wait -NoNewWindow

Write-Host 'Running "prepdocs.py"'
$cwd = (Get-Location)
Start-Process -FilePath $venvPythonPath -ArgumentList "./python/create_emb.py `"$cwd/data/`" --openaimodelname $env:AZURE_OPENAI_EMB_MODEL_NAME --openaiservice $env:AZURE_OPENAI_SERVICE --openaideployment $env:AZURE_OPENAI_EMB_DEPLOYMENT"  -Wait -NoNewWindow
