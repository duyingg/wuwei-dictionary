"""生成单字异读音映射；运行时需安装 pypinyin==0.55.0。"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path('.tmp_pypinyin').resolve()))

from pypinyin import Style, pinyin  # noqa: E402


entries_path = Path('assets/data/chinese_entries_v2.json')
output_path = Path('assets/data/pinyin_readings.json')
entries = json.loads(entries_path.read_text(encoding='utf-8'))
readings = {}

for entry in entries:
    character = entry['character']
    values = pinyin(
        character,
        style=Style.TONE,
        heteronym=True,
        strict=False,
        errors=lambda value: [],
    )
    merged = []
    for value in (values[0] if values else []):
        value = value.strip().lower().replace('u:', 'ü').replace('v', 'ü')
        if value and value != character and value not in merged:
            merged.append(value)
    if merged:
        readings[character] = merged

output_path.write_text(
    json.dumps(readings, ensure_ascii=False, indent=2) + '\n',
    encoding='utf-8',
)
print(f'Generated readings for {len(readings)} characters.')
