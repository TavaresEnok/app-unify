# Obtém automaticamente o diretório onde o script está sendo executado
$folderPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Caminho do arquivo de saída no mesmo diretório
$outputFile = Join-Path $folderPath "saida_dart.txt"

# Extensões desejadas
$extensoes = @(".dart")

# Obtém todos os arquivos .dart na pasta e subpastas
$files = Get-ChildItem -Path $folderPath -Recurse -File |
         Where-Object { $extensoes -contains $_.Extension }

# Limpa ou cria o arquivo de saída
if (Test-Path -Path $outputFile) {
    Clear-Content -Path $outputFile -Force
} else {
    New-Item -Path $outputFile -ItemType File | Out-Null
}

# Adiciona os arquivos ao TXT com cabeçalho organizado
foreach ($file in $files) {
    Add-Content -Path $outputFile -Value "`n========================================="
    Add-Content -Path $outputFile -Value "=== ARQUIVO: $($file.FullName)"
    Add-Content -Path $outputFile -Value "=========================================`n"

    Get-Content -Path $file.FullName | Add-Content -Path $outputFile
}

Write-Host "Arquivos .dart concatenados com sucesso em $outputFile"
