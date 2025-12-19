import requests
import json
import time

API_KEY = "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"
URL = "https://openrouter.ai/api/v1/chat/completions"

models = [
    "tngtech/deepseek-r1t2-chimera:free",
    "mistralai/devstral-2512:free",
    "openai/gpt-oss-120b:free",
    "xiaomi/mimo-v2-flash:free",
    "nousresearch/hermes-3-llama-3.1-405b:free",
    "qwen/qwen3-coder:free"
]

results = {}

print(f"Starting connection tests for {len(models)} models...")
print(f"API Key: {API_KEY[:10]}...")

for model in models:
    print(f"\n---------------------------------------------------")
    print(f"Testing Model: {model}")
    
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://localhost", 
        "X-Title": "Connectivity Test", 
    }
    
    # Basic message
    data = {
        "model": model,
        "messages": [
            {"role": "user", "content": "Hello, please reply with 'OK'."}
        ]
    }
    
    start_time = time.time()
    try:
        response = requests.post(URL, headers=headers, json=data, timeout=45)
        duration = time.time() - start_time
        
        if response.status_code == 200:
            content = response.json()
            try:
                reply = content['choices'][0]['message']['content']
                print(f"SUCCESS ({duration:.2f}s)")
                print(f"Reply: {reply[:100]}...") # Truncate long replies
                results[model] = "SUCCESS"
            except Exception as e:
                 print(f"RESPONSE PARSE ERROR: {e}")
                 print(f"Raw: {content}")
                 results[model] = "PARSE_ERROR"
        else:
            print(f"FAILED ({response.status_code})")
            print(f"Response: {response.text}")
            results[model] = f"FAILED_{response.status_code}"
            
    except Exception as e:
        print(f"EXCEPTION: {str(e)}")
        results[model] = "EXCEPTION"

print("\n\n================ SUMMARY ================")
for model, status in results.items():
    icon = "✅" if status == "SUCCESS" else "❌"
    print(f"{icon} {model}: {status}")
