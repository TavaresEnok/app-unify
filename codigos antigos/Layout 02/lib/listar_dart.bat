@echo off
set "output=lista_dart_com_conteudo.txt"
> "%output%" ( 
    for %%f in (*.dart) do (
        echo === %%f ===
        type "%%f"
        echo.
    )
)
echo Arquivo "%output%" gerado com sucesso.
pause
