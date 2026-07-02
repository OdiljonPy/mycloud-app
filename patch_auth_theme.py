import re

FILES = [
    'lib/features/auth/presentation/login_page.dart',
    'lib/features/auth/presentation/register_page.dart',
    'lib/features/auth/presentation/forgot_password_page.dart',
]сдф

for path in FILES:
    with open(path, 'r', encoding='utf-8') as f:
        c = f.read()

    original = c

    # ── 1: Scaffold backgroundColor: Colors.white → theme ──
    c = c.replace(
        'backgroundColor: Colors.white,\n      body:',
        'backgroundColor: Theme.of(context).scaffoldBackgroundColor,\n      body:'
    )

    # ── 2: AppBar backgroundColor: Colors.white ──
    c = c.replace(
        'backgroundColor: Colors.white,\n        elevation: 0,\n        leading: IconButton(\n          icon: const Icon(Icons.arrow_back_ios,\n              color: Colors.black, size: 20)',
        'backgroundColor: Theme.of(context).scaffoldBackgroundColor,\n        elevation: 0,\n        leading: IconButton(\n          icon: Icon(Icons.arrow_back_ios,\n              color: Theme.of(context).colorScheme.onSurface, size: 20)'
    )

    # ── 3: AppBar backgroundColor: Colors.white (register pattern) ──
    c = c.replace(
        'backgroundColor: Colors.white,\n        elevation: 0,\n        leading: IconButton(\n          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20)',
        'backgroundColor: Theme.of(context).scaffoldBackgroundColor,\n        elevation: 0,\n        leading: IconButton(\n          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface, size: 20)'
    )

    # ── 4: Title text Colors.black87 → onSurface ──
    # Заголовки "Welcome back", "Create Account" etc
    c = re.sub(
        r"color: Colors\.black87,\n(\s+)fontWeight: FontWeight\.(bold|w700|w600)",
        r"color: Theme.of(context).colorScheme.onSurface,\n\1fontWeight: FontWeight.\2",
        c
    )

    # ── 5: Input fillColor 0xFFF5F7FA → адаптивный ──
    c = c.replace(
        "fillColor: const Color(0xFFF5F7FA),",
        "fillColor: Theme.of(context).brightness == Brightness.dark\n                    ? const Color(0xFF2A2A2A)\n                    : const Color(0xFFF5F7FA),"
    )

    # ── 6: Input label Colors.black87 → onSurface ──
    c = re.sub(
        r"color: Colors\.black87,\n(\s+)fontSize:",
        r"color: Theme.of(context).colorScheme.onSurface,\n\1fontSize:",
        c
    )

    if c != original:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(c)
        print(f'OK: {path}')
    else:
        print(f'NO CHANGE: {path}')
