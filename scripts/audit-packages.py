"""Inspect signed owner/public IPA packages without exposing provisioned device identifiers."""
import argparse
import hashlib
import json
import plistlib
import re
import subprocess
import zipfile
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parents[1]
project = (root / 'project.yml').read_text()
version = re.search(r'MARKETING_VERSION: ([\d.]+)', project).group(1)
build = re.search(r'CURRENT_PROJECT_VERSION: (\d+)', project).group(1)
verification = root / f'deliverables/verification-{version}'
verification.mkdir(parents=True, exist_ok=True)
source = (root / 'AIFrontier/Resources/Curriculum.json').read_bytes()
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--public-only', action='store_true', help='Audit only the public App Store distribution package')
args = parser.parse_args()
results = {}
packages = [(f'AIFrontier-{version}-signed.ipa', False)]
if not args.public_only:
    packages.append((f'AIFrontier-{version}-owner-signed.ipa', True))
for name, owner in packages:
    package = root / 'deliverables' / name
    destination = root / '.build/package-audit' / version / ('owner' if owner else 'public')
    with zipfile.ZipFile(package) as archive:
        assert not any('..' in Path(member).parts for member in archive.namelist())
        assert not any(member.endswith(('.npz', '.safetensors', '.spm', '.py')) for member in archive.namelist())
        archive.extractall(destination)
    app = destination / 'Payload/AIFrontier.app'
    # ZIP extraction does not restore Unix execution bits.
    (app / 'AIFrontier').chmod(0o755)
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True, capture_output=True)
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    assert info['CFBundleIdentifier'] == 'com.geruyang.aifrontier'
    assert info['CFBundleShortVersionString'] == version
    assert info['CFBundleVersion'] == build
    assert info['MinimumOSVersion'] == '18.0'
    curriculum_bytes = (app / 'Curriculum.json').read_bytes()
    assert curriculum_bytes == source
    curriculum = json.loads(curriculum_bytes)
    lessons = curriculum['lessons']
    assert curriculum['schemaVersion'] == 3
    assert len(lessons) == len({lesson['id'] for lesson in lessons}) == 600
    assert Counter(lesson['level'] for lesson in lessons) == {'explorer': 200, 'secondary': 200, 'university': 200}
    assert sum(len(lesson['sections']) for lesson in lessons) == 1800
    assert sum(section['example'] is not None for lesson in lessons for section in lesson['sections']) == 720
    assert sum(len(lesson['questions']) for lesson in lessons) == 1980
    assert len(curriculum['references']) == 60
    privacy = plistlib.loads((app / 'PrivacyInfo.xcprivacy').read_bytes())
    assert not privacy['NSPrivacyTracking'] and not privacy['NSPrivacyCollectedDataTypes']
    assert (app / 'Assets.car').is_file()
    profile = plistlib.loads(subprocess.check_output(['security', 'cms', '-D', '-i', str(app / 'embedded.mobileprovision')]))
    signed = plistlib.loads(subprocess.run(['codesign', '-d', '--entitlements', ':-', str(app)], check=True, capture_output=True).stdout)
    assert profile['TeamIdentifier'] == ['VA8X63NPCS']
    assert signed['application-identifier'] == 'VA8X63NPCS.com.geruyang.aifrontier'
    assert bool(signed.get('get-task-allow', False)) == owner
    assert bool(profile.get('ProvisionedDevices')) == owner
    expiry = profile['ExpirationDate'].replace(tzinfo=timezone.utc)
    assert expiry > datetime.now(timezone.utc)
    results[name] = {
        'sha256': hashlib.sha256(package.read_bytes()).hexdigest(),
        'curriculumSHA256': hashlib.sha256(source).hexdigest(),
        'strictSignatureVerified': True, 'version': version, 'build': build, 'minimumOS': '18.0',
        'signingKind': 'development' if owner else 'App Store distribution',
        'team': 'VA8X63NPCS', 'provisionExpiresUTC': expiry.isoformat(),
        'provisionedDeviceCount': len(profile.get('ProvisionedDevices', [])),
        'lessons': 600, 'explanationSections': 1800, 'exampleBlocks': 720, 'questions': 1980, 'references': 60,
        'curriculumMatchesSourceExactly': True, 'modelWeightsBundled': False
    }
output = verification / 'package-audit.json'
output.write_text(json.dumps(results, indent=2) + '\n')
print(json.dumps(results, indent=2))
