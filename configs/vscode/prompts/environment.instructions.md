# Environment-Specific Instructions

## Sistema
- OS: Linux (zsh)
- GPU: NVIDIA GTX 1070 Ti 8GB VRAM
- Editor: VS Code + Fira Code + One Dark Pro Darker

## Proveedores Configurados
- Groq, Cerebras, OpenRouter, Google, Mistral, NVIDIA NIM

## Modelos Recomendados por Tarea

### Coding General
1. Groq: `llama-3.3-70b-versatile`
2. Cerebras: `gpt-oss-120b`
3. Fallback: OpenRouter `openrouter/free`

### Iteración Rápida
1. Groq: `mixtral-8x7b-32768`
2. Cerebras: `llama3.1-8b`

### Contexto Largo (>100K tokens)
1. Google: `gemini-2.5-flash` (1M contexto)
2. Mistral: `codestral-2501` (256K contexto)

### Debugging/Reasoning
1. OpenRouter: `deepseek/deepseek-r1:free`
2. Groq: `qwen/qwen3-32b`

### Coding Especializado (256K)
1. Mistral: `codestral-2501`
2. Mistral: `labs-devstral-small-2512`

## Rate Limits a Respetar
- Groq: 30 RPM, 1K-14.4K RPD
- Cerebras: 30 RPM, 14.4K RPD
- Google: 10-15 RPM, 250-1.5K RPD
- OpenRouter: 20 RPM, 50-1K RPD
- Mistral: ~1 RPS (backoff si 429)

## Skills Instalados
- gstack (QA, review, ship, office-hours, investigate)
- mattpocock/skills (diagnose, tdd, grill, triage, zoom-out)
- kiro/cc-sdd (spec-driven development)
- caveman (compresión output)
- context7 (docs lookup)
- engram (memoria persistente)