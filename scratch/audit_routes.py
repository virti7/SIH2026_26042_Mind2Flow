import re
import os

routes_file = r'd:\1SIH_JHAR_WORKING\lib\app\router\route_names.dart'
with open(routes_file, 'r', encoding='utf-8') as f:
    routes_text = f.read()

defined_routes = re.findall(r'static const String (\w+)\s*=\s*[\'"]([^\'"]+)[\'"]', routes_text)
print(f'Total defined routes in route_names.dart: {len(defined_routes)}')

lib_dir = r'd:\1SIH_JHAR_WORKING\lib'
file_contents = {}
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            # exclude route_names.dart and app_router.dart to see actual app usage
            if not ('route_names.dart' in path or 'app_router.dart' in path):
                with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                    file_contents[path] = f.read()

usage_counts = {}
for name, val in defined_routes:
    count = 0
    used_in = []
    val_clean = val.split(':')[0]
    for path, content in file_contents.items():
        if f'AppRoutes.{name}' in content or f'"{val}"' in content or f"'{val}'" in content or (len(val_clean) > 3 and f'"{val_clean}' in content):
            count += 1
            used_in.append(os.path.basename(path))
    usage_counts[name] = (val, count, used_in)

unused = [k for k, v in usage_counts.items() if v[1] == 0]
print(f'Unused / Disconnected routes ({len(unused)}):')
for u in unused:
    print(f'  - AppRoutes.{u} ({usage_counts[u][0]})')

print('\nRoutes used ONLY in tablet_sidebar.dart:')
for k, v in usage_counts.items():
    if v[1] == 1 and 'tablet_sidebar.dart' in v[2]:
        print(f'  - AppRoutes.{k} ({v[0]}) used ONLY in tablet_sidebar.dart!')

print('\nAll routes and usage summaries:')
for k, v in usage_counts.items():
    print(f'{k}: {v[1]} times in {v[2]}')
