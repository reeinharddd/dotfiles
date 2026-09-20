# Política Antigravity — Uso de cuotas gratuitas de Google

> **Principio**: Antigravity es un *fallback de último recurso*, no infraestructura principal.
> El riesgo de baneo de cuenta Google es real y documentado.

## Riesgos Documentados

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| **Baneo de cuenta Google** | Pérdida de Gmail, Drive, Photos, Cloud | Usar SOLO cuenta desechable |
| **FreeTierError 403** | zen free solo funciona dentro de OpenCode app | No usar zen en background/subagentes |
| **Rate limit agotado** | Cuota diaria consumida | Multi-cuenta con rotación automática |
| **Violación TOS Google** | Uso automatizado de cuotas | Solo cuenta desechable, sin datos personales |

## Reglas de Uso

### ✅ PERMITIDO
- Cuenta Google **exclusivamente creada para esto** (desechable)
- Solo en perfil `personal` (nunca en `client`)
- Como fallback cuando todos los proveedores gratuitos fallan
- Con `ANTIGRAVITY_KILL_SWITCH=true` (desactivable instantáneo)
- Cuota monitoreada: alerta al 80% de consumo

### ❌ PROHIBIDO
- Cuenta Google principal (Gmail, Drive, Cloud personal)
- En perfil `client` (datos de terceros/NDA)
- En agentes background/subagentes (zen falla con 403)
- Como proveedor primario (solo fallback)
- Sin kill-switch activo

## Configuración Técnica

```bash
# Variables en .env.sops.personal (encriptado con sops+age)
ANTIGRAVITY_ENABLED=true
ANTIGRAVITY_ACCOUNT_TYPE=disposable
ANTIGRAVITY_EMAIL=antigravity-xxx@gmail.com
ANTIGRAVITY_PASSWORD=  # se guarda en secret manager, no en .env
ANTIGRAVITY_KILL_SWITCH=true
```

## Monitoreo y Alertas

| Métrica | Umbral | Acción |
|---------|--------|--------|
| Cuota diaria usada | > 80% | Notificación ntfy, desactivar antigravity |
| Errores 403 FreeTier | > 5/min | Kill-switch automático |
| Cuenta baneada | 1 vez | Rotar cuenta inmediatamente |

## Procedimiento de Rotación

1. Detectar baneo o cuota agotada → `ANTIGRAVITY_ENABLED=false`
2. Crear nueva cuenta Google desechable
3. Actualizar credenciales en `.env.sops.personal` (sops -e)
4. Reactivar `ANTIGRAVITY_ENABLED=true`
5. Verificar con `opencode -p "test antigravity"`

## Integración con Harness

- **model-routing-guard.js**: Excluye zen de agentes background
- **oh-my-openagent.json**: zen solo en agentes `smart`, `build` (interactivos)
- **profile.personal**: `ANTIGRAVITY_ENABLED=true`, cuenta desechable
- **profile.client**: `ANTIGRAVITY_ENABLED=false`, `NO_ANTIGRAVITY=true`
- **ai wrapper**: Carga profile.personal/client → setea `ANTIGRAVITY_ENABLED` en env

## Decisiones de Arquitectura (ADR)

- **D1**: Antigravity diferido como fallback, no proveedor primario
- **D2**: Solo cuenta desechable, nunca cuenta principal
- **D3**: Kill-switch obligatorio (variable de entorno)
- **D4**: Solo perfil personal, nunca client
- **D5**: Monitoreo activo con alertas ntfy

## Referencias

- GitHub issues: opencode-antigravity-auth #47, #89, #156
- Google TOS: "Automated access to services prohibited without permission"
- Issue zen: FreeTierError 403 en clientes externos (2026-09-18)