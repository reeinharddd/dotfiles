Detecta el stack del proyecto actual y genera `.opencode/PROJECT_CONTEXT.md` con las skills y MCPs específicos del proyecto.

## Uso

```
/project-bootstrap              # detecta cwd
/project-bootstrap [path]       # detecta path específico
```

## Qué hace

1. Escanea el directorio por manifests (`package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, etc.)
2. Detecta frameworks secundarios (`angular.json`, `nest-cli.json`, `next.config.*`, etc.)
3. Detecta infra (`Dockerfile`, `k8s/`, `terraform/`, `.github/workflows/`)
4. Mapea stack detectado → skills específicas (e.g. `typescript + angular` → `angular-architect`, `typescript-pro`)
5. Mapea infra → skills DevOps/K8s/Terraform
6. Genera `.opencode/PROJECT_CONTEXT.md` con:
   - Stack detectado
   - Lista de skills específicas del proyecto (lazy)
   - MCPs relevantes
   - Sección vacía para reglas particulares

## Después de ejecutar

El agente principal debe:
1. Leer `.opencode/PROJECT_CONTEXT.md` para saber qué skills aplicar
2. Cargar `~/.config/opencode/domain-registry/REGISTRY.md` para skills adicionales
3. Invocar `skill(name="...")` solo cuando aplique, no pre-injectar

## Importante

- El contexto global (`AGENTS_CORE.md` + `core-skills/`) sigue siendo la fuente de reglas universales
- El PROJECT_CONTEXT solo AGREGA skills específicas del stack detectado
- Si agregas/eliminas skills de un proyecto, edita manualmente la sección "Project-Specific Rules"