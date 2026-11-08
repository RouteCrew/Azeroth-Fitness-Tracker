"""Run the full mocked WoW regression suite for every supported client locale."""
import os
from pathlib import Path
import re
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
locales = ['deDE','enUS','enGB','frFR','esES','esMX','itIT','ptBR','ptPT','ruRU','koKR','zhCN','zhTW','xxXX']
for locale in locales:
    result = subprocess.run([sys.executable, 'tests/check.py'], cwd=root,
                            env={**os.environ, 'AFT_TEST_LOCALE': locale},
                            text=True, capture_output=True)
    if result.returncode:
        print(result.stdout, result.stderr)
        raise SystemExit(f'FAIL: {locale}')
    print(f'PASS: {locale}')
# Every application locale key must be defined in the English fallback table.
locale_source = (root/'ForeverSteps/Locale.lua').read_text()
base = locale_source.split('dictionaries.enUS = {',1)[1].split('\n}',1)[0]
keys = set(re.findall(r'^    (\w+) = ', base, re.M))
extra = (root/'ForeverSteps/LocaleExtras.lua').read_text().split('extra.enUS = {',1)[1].split('\n}',1)[0]
keys |= set(re.findall(r'^    (\w+) = ', extra, re.M))
for name in ['Core.lua','Features.lua','Settings.lua','ForeverSteps.lua']:
    source = (root/'ForeverSteps'/name).read_text()
    used = set(re.findall(r'\bL\.(\w+)', source))
    assert used <= keys, (name, used - keys)
print('PASS: all referenced localization keys exist')
