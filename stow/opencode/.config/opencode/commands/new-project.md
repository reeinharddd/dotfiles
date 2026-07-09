Scaffold a new project with full opencode setup (git init, AGENTS.md, PROJECT_CONTEXT.md, .gitignore).

## Uso

```
/new-project <name>              # crea en ~/projects/<name>
/new-project <name> /path/to/dir # crea en ruta específica
```

## Qué hace

1. Crea el directorio del proyecto
2. `git init` + checkout `main`
3. `.gitignore` básico (node_modules, .env, dist, etc.)
4. Copia `AGENTS_CORE.md` template como `AGENTS.md`
5. Ejecuta `project-bootstrap` para detectar stack y generar `.opencode/PROJECT_CONTEXT.md`
6. Commit inicial

## Script

`~/tools/new-project/scaffold.sh`
