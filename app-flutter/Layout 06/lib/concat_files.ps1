# Caminho da pasta onde os arquivos .dart estão localizados
$folderPath = "C:\Users\tavares\StudioProjects\app-provedor-flutter\lib"  # Caminho fornecido

# Caminho do arquivo de saída
$outputFile = "C:\Users\tavares\StudioProjects\app-provedor-flutter\lib\saida.txt"

# Obtém todos os arquivos .dart na pasta e subpastas
$dartFiles = Get-ChildItem -Path $folderPath -Filter "*.dart" -Recurse -File

# Se o arquivo de saída já existir, ele será limpo
if (Test-Path -Path $outputFile) {
    Clear-Content -Path $outputFile -Force
} else {
    New-Item -Path $outputFile -ItemType File | Out-Null
}

# Para cada arquivo .dart encontrado, adiciona o nome do arquivo e o conteúdo ao arquivo de saída
foreach ($file in $dartFiles) {
    Add-Content -Path $outputFile -Value "`n### Arquivo: $($file.FullName) ###`n"
    Get-Content -Path $file.FullName | Add-Content -Path $outputFile
}

Write-Host "Arquivos concatenados com sucesso em $outputFile"
