#!/usr/bin/env python3
"""
Script para testar conexão com modelos OpenRouter
"""

import requests
import json
import time

API_KEY = "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"
BASE_URL = "https://openrouter.ai/api/v1/chat/completions"

MODELS = [
    "tngtech/deepseek-r1t2-chimera:free",
    "mistralai/devstral-2512:free",
    "openai/gpt-oss-120b:free",
    "xiaomi/mimo-v2-flash:free",
    "nousresearch/hermes-3-llama-3.1-405b:free",
    "qwen/qwen3-coder:free",
]

def test_model(model_name):
    """Testa um modelo específico"""
    print(f"\n{'='*60}")
    print(f"🧪 Testando: {model_name}")
    print(f"{'='*60}")
    
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://painel-provedores.web.app",
        "X-Title": "Painel Provedores Test",
    }
    
    data = {
        "model": model_name,
        "messages": [
            {
                "role": "user",
                "content": "Responda em português: Diga 'Olá, estou funcionando!' em uma única linha."
            }
        ],
        "max_tokens": 100
    }
    
    try:
        start_time = time.time()
        response = requests.post(BASE_URL, headers=headers, json=data, timeout=60)
        elapsed = time.time() - start_time
        
        if response.status_code == 200:
            result = response.json()
            content = result.get('choices', [{}])[0].get('message', {}).get('content', 'Sem resposta')
            print(f"✅ Status: {response.status_code}")
            print(f"⏱️  Tempo: {elapsed:.2f}s")
            print(f"💬 Resposta: {content[:200]}")
            return True
        else:
            print(f"❌ Status: {response.status_code}")
            print(f"📄 Erro: {response.text[:300]}")
            return False
            
    except requests.exceptions.Timeout:
        print(f"⏰ Timeout após 60s")
        return False
    except Exception as e:
        print(f"❌ Erro: {str(e)}")
        return False

def main():
    print("\n" + "="*60)
    print("🚀 TESTE DE CONEXÃO - OPENROUTER AI MODELS")
    print("="*60)
    
    results = {}
    
    for model in MODELS:
        success = test_model(model)
        results[model] = "✅ OK" if success else "❌ FALHOU"
        time.sleep(1)  # Delay entre requests
    
    print("\n" + "="*60)
    print("📊 RESUMO DOS RESULTADOS")
    print("="*60)
    
    for model, status in results.items():
        print(f"  {status} - {model}")
    
    print("\n")

if __name__ == "__main__":
    main()
