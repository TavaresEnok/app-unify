import os
import shutil
import argparse
import subprocess
import re
import tempfile
import sys
from pathlib import Path

def run_command(command, cwd):
    """Run a shell command and print output."""
    print(f"Executing: {command} in {cwd}")
    try:
        subprocess.check_call(command, shell=True, cwd=cwd)
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='Gerador de APK White Label')
    parser.add_argument('--id', required=True, help='ID do Provedor (Firebase Doc ID)')
    parser.add_argument('--nome', required=True, help='Nome do App (Display Name)')
    parser.add_argument('--logo', required=True, help='Caminho absoluto para o arquivo de logo (PNG/JPG)')
    parser.add_argument('--output', default='/home/app/painel-provedores-projeto/public_apks', help='Diretório de saída')
    
    args = parser.parse_args()
    
    # Paths
    base_project_dir = '/home/app/painel-provedores-projeto/app-flutter/unified'
    logo_path = Path(args.logo)
    
    if not logo_path.exists():
        print(f"Erro: Logo não encontrada em {logo_path}")
        sys.exit(1)

    # 1. Create Temp Directory
    with tempfile.TemporaryDirectory() as temp_dir:
        build_dir = os.path.join(temp_dir, 'build_project')
        print(f"Creating temporary build directory: {build_dir}")
        shutil.copytree(base_project_dir, build_dir)
        
        # 2. Inject Provider ID
        main_dart_path = os.path.join(build_dir, 'lib', 'main.dart')
        with open(main_dart_path, 'r') as f:
            content = f.read()
        
        # Regex to replace 'const String providerId = '...';'
        new_content = re.sub(
            r"const String providerId = '[^']+';",
            f"const String providerId = '{args.id}';",
            content
        )
        
        if content == new_content:
            print("AVISO: ID do provedor não encontrado ou não alterado em main.dart")
        
        with open(main_dart_path, 'w') as f:
            f.write(new_content)
        print(f"Provider ID injected: {args.id}")

        # 3. Inject App Name (AndroidManifest.xml)
        manifest_path = os.path.join(build_dir, 'android', 'app', 'src', 'main', 'AndroidManifest.xml')
        with open(manifest_path, 'r') as f:
            manifest_content = f.read()
            
        # Regex to replace android:label="original"
        # We look for android:label="..." inside <application
        # Note: XML parsing is better, but regex is faster for this specific known structure
        
        # Simple string replacement for the specific line we identified earlier
        # android:label="unified" (from step 12097)
        new_manifest_content = re.sub(
            r'android:label="[^"]+"',
            f'android:label="{args.nome}"',
            manifest_content
        )
        
        with open(manifest_path, 'w') as f:
            f.write(new_manifest_content)
        print(f"App Name injected: {args.nome}")

        # 4. Icon Generation
        # Copy logo to assets/images/icon.png (or whatever flutter_launcher_icons expects)
        # We need to check pubspec.yaml config. Assuming generic 'flutter_launcher_icons' config
        # We will create a flutter_launcher_icons.yaml content on the fly to be sure
        
        icon_config_path = os.path.join(build_dir, 'flutter_launcher_icons.yaml')
        icon_source_path = os.path.join(build_dir, 'assets', 'images', 'logo_temp.png')
        
        shutil.copy(logo_path, icon_source_path)
        
        icon_config_content = f"""
flutter_launcher_icons:
  android: "ic_launcher"
  ios: false
  image_path: "assets/images/logo_temp.png"
  min_sdk_android: 21 # android min sdk min:16, default 21
  web:
    generate: true
    image_path: "assets/images/logo_temp.png"
    background_color: "#hex_code"
    theme_color: "#hex_code"
  windows:
    generate: true
    image_path: "assets/images/logo_temp.png"
    icon_size: 48 # min:48, max:256, default: 48
  macos:
    generate: true
    image_path: "assets/images/logo_temp.png"
"""
        with open(icon_config_path, 'w') as f:
            f.write(icon_config_content)
            
        # Run icon generator
        run_command('dart run flutter_launcher_icons -f flutter_launcher_icons.yaml', build_dir)
        print("Icons generated.")

        # 5. Build
        print("Starting APK Build. This may take a while...")
        run_command('flutter build apk --release', build_dir)
        
        # 6. Move Output
        apk_source = os.path.join(build_dir, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')
        
        if not os.path.exists(apk_source):
             print("Error: Build finished but APK not found at expected path.")
             sys.exit(1)
             
        output_dir = Path(args.output)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        safe_name = re.sub(r'[^a-zA-Z0-9]', '_', args.nome)
        target_apk = output_dir / f"app_{safe_name}.apk"
        
        shutil.copy(apk_source, target_apk)
        print(f"\n✅ SUCESSO! APK gerado em: {target_apk}")
        print(f"Temp directory {temp_dir} will be automatically deleted.")

if __name__ == '__main__':
    main()
