# Test Instructions

## Principios
- Tests primero (TDD) cuando el usuario lo pida explícitamente
- Usar `/tdd` (mattpocock) para red-green-refactor
- Nunca escribir tests sin haber visto el código primero

## Estructura de Tests
```typescript
// 1. Arrange - setup
// 2. Act - call the function  
// 3. Assert - verify outcome
```

## Frameworks Preferidos
- Jest para JavaScript/TypeScript
- pytest para Python
- Go test para Go
- Vitest para React/Vite

## Coverage Mínimo
- Funciones: 80% coverage
- Paths críticos: 100%
- Edge cases documentados

## Mocking
- No mockear lo que no es tuyo
- Usar interfaces reales cuando sea posible
- Mockear solo APIs externas y servicios