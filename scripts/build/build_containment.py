"""Private immutable build receipts. No Firebase, publisher or credential access."""
import hashlib
import json
import re
import shutil
import unicodedata
from pathlib import Path


def normalized(value):
    return re.sub('[^a-z0-9]', '', unicodedata.normalize('NFKD', value).lower())


def check_identity(registry_path, provider, name, package):
    registry = json.loads(Path(registry_path).read_text())
    if registry.get('schema') != 1 or registry.get('reviewed') is not True:
        raise ValueError('identity-registry-required')
    rows = registry['identities']
    for field, transform in [('providerId', str), ('providerId', normalized),
                             ('applicationId', str), ('appName', normalized)]:
        values = [transform(row[field]) for row in rows]
        if len(values) != len(set(values)) or not all(values):
            raise ValueError('identity-registry-conflict')
    matches = [row for row in rows if row['providerId'] == provider]
    if len(matches) != 1:
        raise ValueError('identity-inventory-required')
    row = matches[0]
    if (row.get('inventoryReviewed') is not True or row['appName'] != name or
            row['applicationId'] != package or not re.fullmatch(r'[a-fA-F0-9]{64}', row.get('signingCertificateSha256', '')) or
            not re.fullmatch(r'[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+', package)):
        raise ValueError('identity-inventory-required')
    return row


def checksum(file):
    return hashlib.sha256(Path(file).read_bytes()).hexdigest()


def persist_build(output, artifact, symbols, mapping, metadata, obfuscated=False):
    """Must complete before TemporaryDirectory cleanup; partial output never succeeds."""
    target = Path(output)
    target.mkdir(parents=True, exist_ok=False, mode=0o700)
    files = []

    def retain(source, relative):
        source = Path(source)
        if source.is_symlink() or not source.is_file() or not source.stat().st_size:
            raise ValueError('missing-build-output')
        dest = target / relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        with source.open('rb') as src, dest.open('xb') as dst:
            shutil.copyfileobj(src, dst)
            dst.flush()
            import os
            os.fsync(dst.fileno())
        digest = checksum(source)
        if checksum(dest) != digest:
            raise ValueError('build-persistence-failed')
        files.append({'path': relative, 'sha256': digest})

    retain(artifact, 'artifact.' + metadata['format'])
    symbol_files = sorted(Path(symbols).rglob('*')) if symbols else []
    if obfuscated and not any(p.is_file() for p in symbol_files):
        raise ValueError('missing-obfuscation-symbols')
    for file in symbol_files:
        if file.is_file():
            retain(file, 'symbols/' + str(file.relative_to(symbols)))
    if mapping and Path(mapping).exists():
        retain(mapping, 'mapping/mapping.txt')
    # R8 mapping is required whenever the generated release enables minification.
    if metadata.get('minified') and not any(f['path'] == 'mapping/mapping.txt' for f in files):
        raise ValueError('missing-r8-mapping')
    with (target / 'manifest.json').open('x') as receipt:
        json.dump({**metadata, 'files': files}, receipt, sort_keys=True)
        receipt.flush()
        import os
        os.fsync(receipt.fileno())
    return target / 'manifest.json'
