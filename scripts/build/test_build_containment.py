import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from build_containment import persist_build, checksum, check_identity


class ContainmentTests(unittest.TestCase):
    def metadata(self):
        return dict(providerId='isp-a', applicationId='br.com.existing', versionCode='123',
                    buildId='synthetic-build', format='aab', minified=True)

    def test_symbols_and_mapping_recover_after_real_temporary_cleanup(self):
        with tempfile.TemporaryDirectory() as durable:
            output = Path(durable) / 'tenant/123/build'
            with tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                artifact = root / 'app.aab'; artifact.write_bytes(b'fake build output')
                symbols = root / 'symbols'; symbols.mkdir()
                (symbols / 'app.android-arm64.symbols').write_bytes(b'fake symbols')
                mapping = root / 'mapping.txt'; mapping.write_text('fake R8 mapping')
                manifest = persist_build(output, artifact, symbols, mapping, self.metadata(), obfuscated=True)
            self.assertFalse(root.exists())
            receipt = json.loads(manifest.read_text())
            self.assertEqual(receipt['applicationId'], 'br.com.existing')
            for entry in receipt['files']:
                self.assertEqual(checksum(output / entry['path']), entry['sha256'])
            self.assertEqual((output / 'symbols/app.android-arm64.symbols').read_bytes(), b'fake symbols')
            self.assertEqual((output / 'mapping/mapping.txt').read_text(), 'fake R8 mapping')

    def test_missing_symbols_mapping_and_failed_persistence_never_announce_success(self):
        for failure in ['symbols', 'mapping', 'copy']:
            with self.subTest(failure=failure), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary); artifact = root / 'app.aab'; artifact.write_bytes(b'fake')
                symbols = root / 'symbols'; symbols.mkdir(); mapping = root / 'mapping.txt'
                if failure != 'symbols': (symbols / 'app.symbols').write_text('fake symbols')
                if failure != 'mapping': mapping.write_text('fake mapping')
                output = root / 'private'
                if failure == 'copy':
                    with patch('build_containment.shutil.copyfileobj', side_effect=OSError('synthetic full disk')):
                        with self.assertRaises(OSError): persist_build(output, artifact, symbols, mapping, self.metadata(), True)
                else:
                    with self.assertRaises(ValueError): persist_build(output, artifact, symbols, mapping, self.metadata(), True)
                self.assertFalse((output / 'manifest.json').exists())

    def test_same_build_cannot_overwrite_existing_output(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); artifact = root / 'app.apk'; artifact.write_bytes(b'old')
            metadata = {**self.metadata(), 'format': 'apk', 'minified': False}
            output = root / 'tenant/123/build'
            persist_build(output, artifact, None, None, metadata)
            artifact.write_bytes(b'new')
            with self.assertRaises(FileExistsError): persist_build(output, artifact, None, None, metadata)
            self.assertEqual((output / 'artifact.apk').read_bytes(), b'old')

    def test_inventory_preserves_package_and_rejects_aliases(self):
        with tempfile.TemporaryDirectory() as temporary:
            registry = Path(temporary) / 'identities.json'
            row = dict(providerId='isp-a', appName='Same Name', applicationId='br.com.legacy',
                       signingCertificateSha256='a' * 64, inventoryReviewed=True)
            def write(rows): registry.write_text(json.dumps(dict(schema=1, reviewed=True, identities=rows)))
            write([row]); before = registry.read_bytes()
            self.assertEqual(check_identity(registry, 'isp-a', 'Same Name', 'br.com.legacy'), row)
            self.assertEqual(registry.read_bytes(), before)
            with self.assertRaises(ValueError): check_identity(registry, 'isp-a', 'Same Name', 'br.com.new')
            for other in [{**row, 'providerId': 'ispa', 'appName': 'Other', 'applicationId': 'br.com.other'},
                          {**row, 'providerId': 'other', 'applicationId': 'br.com.other'}]:
                write([row, other])
                with self.assertRaises(ValueError): check_identity(registry, 'isp-a', 'Same Name', 'br.com.legacy')
            registry.unlink()
            with self.assertRaises(FileNotFoundError): check_identity(registry, 'isp-a', 'Same Name', 'br.com.legacy')

    def test_real_python_pipeline_cleans_temp_after_persisting_fake_build_outputs(self):
        spec = importlib.util.spec_from_file_location('generate_apk', Path(__file__).with_name('generate-apk.py'))
        module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); template = root / 'flutter'
            for name, content in {
                'lib/main.dart': "const String providerId = 'original';",
                'android/app/build.gradle': 'applicationId = "com.example.unified"\nnamespace = "com.example.unified"\nminifyEnabled true',
                'android/app/src/main/AndroidManifest.xml': '<application android:label="Example"/>',
                'pubspec.yaml': 'version: 1.0.0+1',
            }.items():
                file = template / name; file.parent.mkdir(parents=True, exist_ok=True); file.write_text(content)
            registry = root / 'identities.json'
            registry.write_text(json.dumps(dict(schema=1, reviewed=True, identities=[dict(providerId='isp-a', appName='Synthetic', applicationId='br.com.legacy', signingCertificateSha256='a'*64, inventoryReviewed=True)])))
            logo = root / 'logo.png'; logo.write_bytes(b'fake')
            built_dirs = []
            def fake_command(command, cwd, env=None):
                if command.startswith('flutter build'):
                    built_dirs.append(Path(cwd))
                    artifact = Path(cwd) / 'build/app/outputs/bundle/release/app-release.aab'
                    artifact.parent.mkdir(parents=True); artifact.write_bytes(b'fake signed output')
                    symbols = Path(cwd).parent / 'symbols'; (symbols / 'app.symbols').write_bytes(b'fake symbols')
                    mapping = Path(cwd) / 'build/app/outputs/mapping/release/mapping.txt'
                    mapping.parent.mkdir(parents=True); mapping.write_text('fake mapping')
            argv = ['generate-apk.py', '--id', 'isp-a', '--nome', 'Synthetic', '--logo', str(logo), '--output', str(root / 'private'),
                    '--flutter-project', str(template), '--package', 'br.com.legacy', '--identity-registry', str(registry),
                    '--build-id', 'test-build', '--version-code', '123', '--format', 'aab', '--obfuscate']
            real_rglob = Path.rglob
            def synthetic_cache_scan(directory, pattern):
                return iter([]) if 'flutter_internet' in pattern else real_rglob(directory, pattern)
            with patch('sys.argv', argv), patch.object(module, 'run_command', fake_command), patch.object(Path, 'rglob', autospec=True, side_effect=synthetic_cache_scan):
                module.main()
            self.assertTrue(built_dirs); self.assertFalse(built_dirs[0].exists())
            receipt = json.loads((root / 'private/manifest.json').read_text())
            self.assertTrue(any(f['path'].startswith('symbols/') for f in receipt['files']))
            for entry in receipt['files']: self.assertEqual(checksum(root / 'private' / entry['path']), entry['sha256'])


if __name__ == '__main__':
    unittest.main()
