# Caminho da pasta onde os arquivos .dart estão localizados
$folderPath = "C:\Users\tavares\StudioProjects\app-provedor-flutter\lib\services"  # Caminho fornecido

# Caminho do arquivo de saída
$outputFile = "C:\Users\tavares\StudioProjects\app-provedor-flutter\lib\services\saida2.txt"  # Você pode alterar para outro local se desejar

# Obtém todos os arquivos .dart na pasta
$dartFiles = Get-ChildItem -Path $folderPath -Filter "*.dart"

# Se o arquivo de saída já existir, ele será substituído automaticamente, caso contrário, será criado
if (Test-Path -Path $outputFile) {
    Clear-Content -Path $outputFile -Force
} else {
    # Caso o arquivo não exista, cria o arquivo vazio
    New-Item -Path $outputFile -ItemType File
}

# Para cada arquivo .dart encontrado, adiciona o nome do arquivo e o conteúdo ao arquivo de saída
foreach ($file in $dartFiles) {
    # Adiciona o nome do arquivo ao arquivo de saída
    Add-Content -Path $outputFile -Value "`n### Arquivo: $($file.Name) ###`n"

    # Adiciona o conteúdo do arquivo .dart ao arquivo de saída
    Get-Content -Path $file.FullName | Add-Content -Path $outputFile
}

Write-Host "Arquivos concatenados com sucesso em $outputFile"
