import urllib.request
import json
import re
import os

API_KEY = "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"
URL = "https://openrouter.ai/api/v1/chat/completions"

# Read the reference file
with open("app-flutter/unified/lib/layouts/layout_06/dashboard_page.dart", "r") as f:
    reference_code = f.read()

prompt = f"""
You are an expert Flutter developer and UI/UX designer.
I need you to create a new layout file: `lib/layouts/layout_11/dashboard_page.dart`.

Here is the code for an existing layout (Layout 06) to show you the required parameters, imports, and structure.
The new layout (Layout 11) must accept the EXACT SAME parameters in the constructor as Layout 06 (DashboardPage class).

Reference Code (Layout 06):
```dart
{reference_code}
```

Directives for Layout 11:
1. Class name must be `DashboardPage`.
2. Use the exact same imports and constructor parameters as the reference.
3. Design Style: "Cyberpunk / High-Tech". Use a dark theme with neon accents (pink, cyan, purple), sharp angles, and maybe a hexagonal or futuristic look. Different from Layout 06 (which is Premium Dark/Teal).
4. Keep all functionalities: Menu, Notifications, Balance Card, Quick Actions (Faturas, Velocidade, Suporte, Wifi), Plan Card, Services List, Bottom Nav Bar.
5. You can assume `widgets/glass_card.dart` exists in the `widgets` folder relative to this file (copy logic if needed or use it).
6. Return ONLY the Dart code for the file. Do not wrap in markdown if possible, or usually I will strip it. But please provide the full content.

Create `layout_11/dashboard_page.dart` now.
"""

payload = {
    "model": "qwen/qwen3-coder:free",
    "messages": [
        {
            "role": "user",
            "content": prompt
        }
    ]
}

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
    "HTTP-Referer": "https://antigravity.dev",
    "X-Title": "Antigravity Agent"
}

try:
    req = urllib.request.Request(URL, data=json.dumps(payload).encode('utf-8'), headers=headers)
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode('utf-8'))
        
        if 'choices' in result and len(result['choices']) > 0:
            content = result['choices'][0]['message']['content']
            
            # Extract code from markdown block if present
            match = re.search(r'```dart(.*?)```', content, re.DOTALL)
            if match:
                code = match.group(1).strip()
            else:
                code = content
            
            # Write key file
            output_path = "app-flutter/unified/lib/layouts/layout_11/dashboard_page.dart"
            with open(output_path, "w") as out_f:
                out_f.write(code)
            
            print(f"Successfully generated {output_path}")
            # Print first few lines to verify
            print("Preview:")
            print("\n".join(code.split('\n')[:10]))
        else:
            print("No choices returned in response.")
            print(result)

except urllib.error.HTTPError as e:
    print(f"HTTP Error: {e.code}")
    print(e.read().decode('utf-8'))
except Exception as e:
    print(f"Error: {e}")
