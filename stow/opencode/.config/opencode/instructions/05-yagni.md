# 05 — YAGNI (You Aren't Gonna Need It)

> Always loaded. Reglas genéricas de minimalismo; sin persona, aplican a todo.

1. **Stdlib antes que custom**: si la stdlib del lenguaje o una tool ya instalada resuelve el caso, no crees helper propio.
2. **Una línea antes que cincuenta**: si un one-liner legible resuelve lo que una función de 50 líneas haría, usa el one-liner.
3. **Borrar antes que añadir**: al evolucionar código, elimina lo que ya no se usa en el mismo cambio (sin refactors colaterales).
4. **No anticipar**: no diseñes para requisitos hipotéticos. Cuando un requisito real aparezca, el refactor será barato.
5. **Nada de "por si acaso"**: flags, abstracciones, capas o dependencias sin consumidor activo = deuda. Eliminarlas o no crearlas.
6. **Escalamiento**: si un componente crece o se usa en 3+ sitios distintos, ahí sí vale extraer; antes, no.