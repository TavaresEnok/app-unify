# Configuração OpenRouter AI

**API Key**: `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`

**Base URL**: `https://openrouter.ai/api/v1/chat/completions`

## 🧠 Modelos Selecionados (Free Tier)

A lista abaixo substitui quaisquer seleções anteriores.

1.  **DeepSeek R1**: `tngtech/deepseek-r1t2-chimera:free`
2.  **Mistral Dev**: `mistralai/devstral-2512:free`
3.  **GPT-OSS**: `openai/gpt-oss-120b:free`
4.  **Xiaomi Mimo**: `xiaomi/mimo-v2-flash:free`
5.  **Hermes 3**: `nousresearch/hermes-3-llama-3.1-405b:free`
6.  **Qwen 3 Coder**: `qwen/qwen3-coder:free`

## 📝 Exemplo de Implementação (Referência)

```json
{
  "model": "tngtech/deepseek-r1t2-chimera:free",
  "messages": [
    {
      "role": "user",
      "content": "Hello"
    }
  ]
}
```
