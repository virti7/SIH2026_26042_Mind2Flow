import re

app_router_file = r'd:\1SIH_JHAR_WORKING\lib\app\router\app_router.dart'
with open(app_router_file, 'r', encoding='utf-8') as f:
    text = f.read()

# find all GoRoute and ShellRoute definitions
routes = re.findall(r'GoRoute\s*\(\s*(?:/\*.*?\*/\s*)?path:\s*([^\n,]+),\s*(?:pageBuilder|builder):\s*\(context, state\)\s*(?:=>|{)(.*?)(?:\n\s*\),|\n\s*\}\s*\),)', text, re.DOTALL)

print(f'Total GoRoutes found in app_router.dart: {len(routes)}')
for path, body in routes:
    path = path.strip()
    # extract return widget or page
    widget_match = re.search(r'(?:const\s+)?([A-Z]\w+Screen|[A-Z]\w+Page|[A-Z]\w+Viewer|[A-Z]\w+View|[A-Z]\w+Player)', body)
    widget_name = widget_match.group(1) if widget_match else 'Custom/Conditional'
    print(f'{path:45} -> {widget_name}')
