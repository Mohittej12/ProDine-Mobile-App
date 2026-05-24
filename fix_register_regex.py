from pathlib import Path
path = Path('lib/features/auth/pages/auth_register_page.dart')
text = path.read_text(encoding='utf-8')
old = "if (!RegExp(r'^\\d+').hasMatch(value.trim())) {"
new = "if (!RegExp(r'^\\d+$').hasMatch(value.trim())) {"
if old not in text:
    raise RuntimeError('Old pattern not found')
text = text.replace(old, new, 1)
path.write_text(text, encoding='utf-8')
print('patched')
