Run quality checks before landing: linter, type check, tests, security scan.

## Uso

```
/quality-gate               # full suite
/quality-gate lint          # solo linter
/quality-gate test          # solo tests
/quality-gate security      # solo security audit
/quality-gate quick         # linter + tests (salta security)
```

## Qué hace

Ejecuta en secuencia:

1. **Linter**: detecta y corre el linter del proyecto (biome, eslint, ruff, golangci-lint)
2. **Type check**: si hay tsconfig, corre `tsc --noEmit`
3. **Tests**: corre test suite con detección automática de framework
4. **Security**: `npm audit` o dependencias equivalentes
5. **Resumen**: pasa/no pasa con detalles

Si todo pasa, el cambio está listo para commit/PR.
Si algo falla, detiene la ejecución y reporta qué falló.

## Notas

- Corre en el directorio actual del proyecto
- Detecta automáticamente el stack y herramientas disponibles
- Usa `bash` para ejecutar los comandos, no modifica archivos
