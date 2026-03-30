import os
import shutil
import argparse
import subprocess
import re
import tempfile
import sys
from pathlib import Path

def run_command(command, cwd, env=None):
    """Run a shell command and print output."""
    print(f"Executing: {command} in {cwd}")
    try:
        # If env is provided, merge it with os.environ, otherwise use os.environ
        cmd_env = os.environ.copy()
        if env:
            cmd_env.update(env)
            
        subprocess.check_call(command, shell=True, cwd=cwd, env=cmd_env)
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='Gerador de APK White Label')
    parser.add_argument('--id', required=True, help='ID do provedor (Firebase)')
    parser.add_argument('--nome', required=True, help='Nome do App')
    parser.add_argument('--logo', required=True, help='Caminho para o arquivo de logo')
    parser.add_argument('--output', default='/home/app/projects/painel_provedores/public_apks', help='Diretório de saída')
    parser.add_argument('--format', default='apk', choices=['apk', 'aab'], help='Formato de saída: apk ou aab')
    parser.add_argument('--obfuscate', action='store_true', help='Ativar ofuscação de código (Blindagem)')
    parser.add_argument('--package', help='Nome do pacote personalizado (ex: com.vibe.app)')
    parser.add_argument('--arm64', action='store_true', help='Otimizar para processadores recentes (ARM64 apenas)')
    parser.add_argument('--version-code', help='Código da versão (Build Number)')
    parser.add_argument('--version-name', help='Nome da versão (ex: 1.0.0)')
    
    args = parser.parse_args()
    
    # Paths
    base_project_dir = '/home/app/projects/painel_provedores/app-flutter/unified'

    logo_path = Path(args.logo)
    
    if not logo_path.exists():
        print(f"Erro: Logo não encontrada em {logo_path}")
        sys.exit(1)

    # 1. Create Temp Directory
    with tempfile.TemporaryDirectory() as temp_dir:
        build_dir = os.path.join(temp_dir, 'build_project')
        print(f"Creating temporary build directory: {build_dir}")
        shutil.copytree(base_project_dir, build_dir)

        # =========================================================
        # WHITE LABEL PACKAGE RENAMING LOGIC
        # =========================================================
        if args.package and args.package != "com.example.unified":
            print(f"🔄 Renaming package to: {args.package}")
            
            # 1. Update build.gradle (applicationId and namespace)
            gradle_path = os.path.join(build_dir, 'android', 'app', 'build.gradle')
            with open(gradle_path, 'r') as f:
                gradle_content = f.read()
            
            # Replace applicationId
            gradle_content = re.sub(
                r'applicationId\s*=\s*"[^"]+"',
                f'applicationId = "{args.package}"',
                gradle_content
            )
            # Replace namespace (important for newer AGP)
            gradle_content = re.sub(
                r'namespace\s*=\s*"[^"]+"',
                f'namespace = "{args.package}"',
                gradle_content
            )

            with open(gradle_path, 'w') as f:
                f.write(gradle_content)
            
            # 2. Update AndroidManifest.xml
            manifest_path = os.path.join(build_dir, 'android', 'app', 'src', 'main', 'AndroidManifest.xml')
            with open(manifest_path, 'r') as f:
                manifest_content = f.read()
            
            # 3. Refactor Directory Structure (Kotlin/Java)
            old_package_path = os.path.join(build_dir, 'android', 'app', 'src', 'main', 'kotlin', 'com', 'example', 'unified')
            new_package_path_list = args.package.split('.')
            new_package_path = os.path.join(build_dir, 'android', 'app', 'src', 'main', 'kotlin', *new_package_path_list)

            if os.path.exists(old_package_path):
                print(f"Moving Kotlin source files from {old_package_path} to {new_package_path}")
                os.makedirs(new_package_path, exist_ok=True)
                
                # Move files and update package declarations
                for item in os.listdir(old_package_path):
                    s = os.path.join(old_package_path, item)
                    d = os.path.join(new_package_path, item)
                    if os.path.isfile(s) and item.endswith('.kt'):
                        # Read, update package, and write to new location
                        with open(s, 'r') as f:
                            content = f.read()
                        # Update package declaration
                        content = re.sub(r'package\s+com\.example\.unified', f'package {args.package}', content)
                        # Update R import
                        content = re.sub(r'import\s+com\.example\.unified\.R', f'import {args.package}.R', content)
                        with open(d, 'w') as f:
                            f.write(content)
                        print(f"  Updated and moved: {item}")
                    elif os.path.isfile(s):
                        shutil.copy2(s, d)
                
                # DELETE the original directory to avoid duplicate classes
                shutil.rmtree(old_package_path)
                print(f"Deleted original package directory: {old_package_path}")
            else:
                 print(f"WARNING: Old package path not found: {old_package_path}. Skipping directory move.")
        # =========================================================

        
        # 2. Inject Provider ID (Dart)
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
            
        new_manifest_content = re.sub(
            r'android:label="[^"]+"',
            f'android:label="{args.nome}"',
            manifest_content
        )
        
        with open(manifest_path, 'w') as f:
            f.write(new_manifest_content)
        print(f"App Name injected: {args.nome}")

        # 3.5. Ensure Dependencies & Patch Namespace (AGP 8+ Fix)
        # =========================================================
        print("📥 Fetching dependencies...")
        # We assume apk-builder-service sets PUB_CACHE to a writable location (e.g. /home/app/.pub-cache)
        run_command('flutter pub get', build_dir)

        print("🔧 Patching flutter_internet_speed_test namespace...")
        try:
            # Determine potential pub cache search paths
            search_paths = []
            
            # Priority: Environment variable (set by service to /home/app/.pub-cache)
            env_pub_cache = os.environ.get('PUB_CACHE')
            if env_pub_cache:
                search_paths.append(Path(env_pub_cache))
            
            # Common defaults
            search_paths.append(Path.home() / '.pub-cache')
            # Fallback (read-only likely, but good to check)
            search_paths.append(Path('/root/.pub-cache'))
            
            # Deduplicate paths
            unique_paths = list(set(search_paths))
            
            print(f"   Debugging: Searching for plugins in: {[str(p) for p in unique_paths]}")

            found_gradles = []
            for cache_root in unique_paths:
                # Expand user explicitly just in case
                if str(cache_root).startswith('~'):
                    cache_root = Path(os.path.expanduser(str(cache_root)))
                    
                if cache_root.exists():
                    # Search for the specific package
                    print(f"   Scanning {cache_root}...")
                    found = list(cache_root.rglob('flutter_internet_speed_test*/android/build.gradle'))
                    found_gradles.extend(found)
            
            if found_gradles:
                # Deduplicate found files
                found_gradles = list(set(found_gradles))
                
                for gradle_file in found_gradles:
                    print(f"   Found: {gradle_file}")
                    with open(gradle_file, 'r') as f:
                        g_content = f.read()
                    
                    if 'namespace' not in g_content:
                        # Use regex to find android block with flexible spacing
                        if re.search(r'android\s*{', g_content):
                            # Replace 'android {' with 'android { namespace ...'
                            # We use sub to handle variable whitespace
                            g_content = re.sub(
                                r'android\s*{',
                                'android {\n    namespace "com.example.flutter_internet_speed_test"',
                                g_content,
                                count=1
                            )
                            with open(gradle_file, 'w') as f:
                                f.write(g_content)
                            print(f"   ✅ Applied namespace patch to {gradle_file}")
                        else:
                             print(f"   ⚠️ 'android {{' block not found in {gradle_file}")
                    else:
                        print(f"   ℹ️ Namespace already present in {gradle_file}")
            else:
                print("   ⚠️ flutter_internet_speed_test build.gradle not found in any cache location. Skipping patch.")
        except Exception as e:
             print(f"   ❌ Error patching build.gradle: {e}")

        print("🔧 Patching flutter_internet_speed_test AndroidManifest.xml...")
        try:
            # Re-use the same search paths logic
            found_manifests = []
            for cache_root in unique_paths:
                if str(cache_root).startswith('~'):
                    cache_root = Path(os.path.expanduser(str(cache_root)))
                    
                if cache_root.exists():
                     found = list(cache_root.rglob('flutter_internet_speed_test*/android/src/main/AndroidManifest.xml'))
                     found_manifests.extend(found)

            if found_manifests:
                found_manifests = list(set(found_manifests))
                for manifest_file in found_manifests:
                    print(f"   Found: {manifest_file}")
                    with open(manifest_file, 'r') as f:
                        m_content = f.read()
                    
                    # Remove package="com.shaz..." attribute
                    if 'package="' in m_content:
                        # Regex to remove package="..." attribute
                        m_content = re.sub(r'package="[^"]+"', '', m_content)
                        with open(manifest_file, 'w') as f:
                            f.write(m_content)
                        print(f"   ✅ Removed 'package' attribute from {manifest_file}")
                    else:
                        print(f"   ℹ️ 'package' attribute already clean in {manifest_file}")
            else:
                print("   ⚠️ flutter_internet_speed_test AndroidManifest.xml not found. Skipping.")

        except Exception as e:
             print(f"   ❌ Error patching manifest: {e}")

        # 4. Icon Generation
        icon_config_path = os.path.join(build_dir, 'flutter_launcher_icons.yaml')
        icon_source_dir = os.path.join(build_dir, 'assets', 'images')
        icon_source_path = os.path.join(icon_source_dir, 'logo_temp.png')
        
        # Ensure directory exists
        os.makedirs(icon_source_dir, exist_ok=True)
        
        # Copy logo and verify
        shutil.copy(logo_path, icon_source_path)
        if not os.path.exists(icon_source_path):
            print(f"ERROR: Failed to copy logo to {icon_source_path}")
            sys.exit(1)
        
        # Verify it's a valid image
        logo_size = os.path.getsize(icon_source_path)
        print(f"Logo copied: {icon_source_path} ({logo_size} bytes)")
        
        icon_config_content = f"""
flutter_launcher_icons:
  android: "ic_launcher"
  ios: false
  image_path: "assets/images/logo_temp.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/images/logo_temp.png"
    background_color: "#hex_code"
    theme_color: "#hex_code"
  windows:
    generate: true
    image_path: "assets/images/logo_temp.png"
    icon_size: 48
  macos:
    generate: true
    image_path: "assets/images/logo_temp.png"
"""
        with open(icon_config_path, 'w') as f:
            f.write(icon_config_content)
            
        run_command('dart run flutter_launcher_icons -f flutter_launcher_icons.yaml', build_dir)
        print("Icons generated.")

        # 4.5. Splash Screen Generation (flutter_native_splash)
        # =========================================================
        print("🖼️ Updating Splash Screen with provider logo...")
        
        # Copy logo to splash image location
        splash_source_path = os.path.join(icon_source_dir, 'logo_splash.png')
        shutil.copy(logo_path, splash_source_path)
        print(f"   Logo copied for splash: {splash_source_path}")
        
        # Update flutter_native_splash.yaml to use provider logo
        splash_config_path = os.path.join(build_dir, 'flutter_native_splash.yaml')
        splash_config_content = """flutter_native_splash:
  color: "#0F172A"
  image: assets/images/logo_splash.png
  android_12:
    color: "#0F172A"
    image: assets/images/logo_splash.png
  web: false
"""
        with open(splash_config_path, 'w') as f:
            f.write(splash_config_content)
        print("   Splash config updated.")
        
        # Regenerate splash screen
        try:
            run_command('dart run flutter_native_splash:create --path=flutter_native_splash.yaml', build_dir)
            print("   ✅ Splash screen generated with provider logo!")
        except Exception as e:
            print(f"   ⚠️ Warning: Splash generation failed: {e}")

        # 5. Build
        print(f"Starting {args.format.upper()} Build (Obfuscated: {args.obfuscate}, ARM64 Only: {args.arm64})...")
        print(f"Package: {args.package or 'DEFAULT'}")
        
        # Explicitly update local.properties to force version code
        if args.version_code or args.version_name:
            local_props_path = os.path.join(build_dir, 'android', 'local.properties')
            print(f"🔧 Forcing version info in {local_props_path}")
            
            # Read existing content if any
            props_content = ""
            if os.path.exists(local_props_path):
                with open(local_props_path, 'r') as f:
                    props_content = f.read()
            
            # Remove existing version keys to avoid duplicates
            props_lines = [line for line in props_content.splitlines() 
                           if not line.startswith('flutter.versionCode') 
                           and not line.startswith('flutter.versionName')]
            
            # Append new version info
            if args.version_code:
                props_lines.append(f"flutter.versionCode={args.version_code}")
                print(f"   -> flutter.versionCode={args.version_code}")
            
            if args.version_name:
                props_lines.append(f"flutter.versionName={args.version_name}")
                print(f"   -> flutter.versionName={args.version_name}")
                
            with open(local_props_path, 'w') as f:
                f.write('\n'.join(props_lines) + '\n')
            
            # PATCH PUBSPEC.YAML (The strict Flutter way)
            if args.version_code:
                pubspec_path = os.path.join(build_dir, 'pubspec.yaml')
                print(f"📄 Patching pubspec.yaml version...")
                with open(pubspec_path, 'r') as f:
                    pubspec_content = f.read()
                
                # Replace version: X.Y.Z+N with version: {version_name}+{version_code}
                # Default to 1.0.0 if version_name not provided
                v_name = args.version_name if args.version_name else "1.0.0"
                v_code = args.version_code
                
                new_version_line = f"version: {v_name}+{v_code}"
                
                # Regex to find version: ...
                if re.search(r'^version:.*', pubspec_content, re.MULTILINE):
                    pubspec_content = re.sub(
                        r'^version:.*',
                        new_version_line,
                        pubspec_content,
                        flags=re.MULTILINE
                    )
                    print(f"   ✅ pubspec.yaml updated to: {new_version_line}")
                else:
                    print("   ⚠️ Cold not find 'version:' key in pubspec.yaml")
                
                with open(pubspec_path, 'w') as f:
                    f.write(pubspec_content)

        print("🧹 Cleaning Flutter project to remove cached artifacts...")
        run_command('flutter clean', build_dir)
        print("📥 Fetching dependencies (again after clean)...")
        run_command('flutter pub get', build_dir)

        build_cmd = f"flutter build {('appbundle' if args.format == 'aab' else 'apk')} --release"
        
        # Inject Versioning
        if args.version_code:
            build_cmd += f" --build-number={args.version_code}"
        if args.version_name:
            build_cmd += f" --build-name={args.version_name}"
        
        # Optimization: ARM64-v8a Only
        if args.arm64:
             build_cmd += " --target-platform android-arm64"
             print("🚀 Optimization Enabled: Building for ARM64 only (Small size)")

        # Security: Obfuscation
        if args.obfuscate:
            # Create symbols directory
            symbols_dir = os.path.join(temp_dir, 'symbols')
            os.makedirs(symbols_dir, exist_ok=True)
            build_cmd += f" --obfuscate --split-debug-info={symbols_dir}"
        
        # Container limit increased to 4GB. Using 3GB for Gradle.
        build_env = {
            'GRADLE_OPTS': '-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs="-Xmx3072m -XX:MaxMetaspaceSize=768m"'
        }
        
        run_command(build_cmd, build_dir, env=build_env)
        
        # 6. Move Output
        if args.format == 'aab':
            output_source = os.path.join(build_dir, 'build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab')
            extension = 'aab'
        else:
            output_source = os.path.join(build_dir, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')
            extension = 'apk'
        
        if not os.path.exists(output_source):
             print(f"Error: Build finished but {extension.upper()} not found at {output_source}")
             sys.exit(1)
             
        output_dir = Path(args.output)
        output_dir.mkdir(parents=True, exist_ok=True)
        
        safe_name = re.sub(r'[^a-zA-Z0-9]', '_', args.nome)
        target_file = output_dir / f"app_{safe_name}.{extension}"
        
        shutil.copy(output_source, target_file)
        print(f"\n✅ SUCESSO! {extension.upper()} gerado em: {target_file}")
        print(f"Temp directory {temp_dir} will be automatically deleted.")

if __name__ == '__main__':
    main()
