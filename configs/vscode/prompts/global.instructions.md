# Global Instructions for AI Coding Assistants

## Provider Priority (100% Free, Mayo 2026)

### Tier 1: Velocidad
- **Groq** (`https://api.groq.com/openai/v1`) — 30 RPM, 14.4K RPD, ~560 tok/s
  - `llama-3.3-70b-versatile` — Mejor calidad general
  - `mixtral-8x7b-32768` — Rápido
  - `llama-3.1-8b-instant` — Muy rápido
- **Cerebras** (`https://api.cerebras.ai/v1`) — 30 RPM, 14.4K RPD, ~3000 tok/s
  - `gpt-oss-120b` — Modelo grande-gratis
  - `llama3.1-8b` — ~2200 tok/s

### Tier 2: Contexto & Especializado
- **Google** (`https://api.languagemodel.google/v1`) — 10-15 RPM, 1M contexto
  - `gemini-2.5-flash` — Contexto largo
  - `gemini-2.0-flash` — Estable
- **Mistral** (`https://api.mistral.ai/v1`) — ~1 RPS, rate-limited
  - `codestral-2501` — Código con 256K contexto
  - `labs-devstral-small-2512` — Coding agent
- **OpenRouter** (`https://openrouter.ai/v1`) — 20 RPM, fallback
  - `deepseek/deepseek-r1:free` — Reasoning
  - `google/gemma-4-26b-a4b:free` — Google nuevo

### Routing por Tarea
```
Velocidad          → Groq mixtral o Cerebras gpt-oss
Código largo       → Mistral codestral (256K)
Contexto 1M       → Google gemini-2.5-flash
Debugging          → OpenRouter deepseek-r1:free
Fallback          → OpenRouter openrouter/free
```

## Skills Disponibles
- `/investigate` — Debugging disciplinado (gstack)
- `/diagnose` — Debugging (mattpocock)
- `/qa` — QA con navegador (gstack)
- `/review` — Code review (gstack)
- `/caveman` — Compresión output
- Context7 MCP — Docs lookup automático
- Engram — Memoria persistente

## Memoria Persistente
- Usar Engram para decisiones importantes
- `mem_save` después de cada decisión arquitectónica
- `mem_session_summary` al cerrar sesión

## Reglas de Contexto
- Máximo 50% del contexto por archivo
- Sesión >30K tokens → usar `/caveman`
- Máximo 3 subagentes simultáneos
- Nunca leer >20 archivos sin resumir

## Providers Eliminados (requieren pago)
- DeepSeek (pay-as-you-go)
- Moonshot/Kimi ($1 mínimo)
- Qwen DashScope (trial agotado)
- HuggingFace ($0.10/mes insuficiente)