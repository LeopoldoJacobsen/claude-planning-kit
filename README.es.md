# claude-planning-kit

[English](README.md) | [Português (BR)](README.pt-BR.md) | **Español**

Kit de planificación y ejecución para Claude Code. Funciona como un "prompt inicial" reutilizable: lo instalas en cualquier proyecto (nuevo o existente) y Claude comienza a planificar y ejecutar mejoras de forma estructurada — con descubrimiento del código, preguntas en lote, un plan revisado por un agente independiente y ejecución continua a prueba de conflictos.

> **Resumen visual:** [leopoldojacobsen.github.io/claude-planning-kit](https://leopoldojacobsen.github.io/claude-planning-kit/) — cómo funciona, el workflow completo y qué hace / no hace, en una sola página (en inglés).

**El ciclo completo:**

```
triaje → (brainstorm si la idea es vaga) → discovery → preguntas → plan
      → revisión independiente → ejecución continua → checklist final humano
```

Todo se convierte en un archivo en `planning/<slug>/` — cualquier sesión retoma desde donde se detuvo, sin depender del historial del chat.

## Instalación

### Opción 1 — Prompt de bootstrap (recomendado: Claude lo hace todo)

| Situación | Qué hacer |
|---|---|
| **Proyecto existente** | Abre Claude Code en la raíz del repositorio y pega el contenido de [`prompts/BOOTSTRAP-EXISTING-PROJECT.md`](prompts/BOOTSTRAP-EXISTING-PROJECT.md) |
| **Proyecto nuevo (carpeta vacía)** | Abre Claude Code en la carpeta y pega [`prompts/BOOTSTRAP-NEW-PROJECT.md`](prompts/BOOTSTRAP-NEW-PROJECT.md), reemplazando solo `<PROJECT-NAME>` por el nombre del proyecto |

Los prompts ya apuntan a este repositorio (`LeopoldoJacobsen/claude-planning-kit`) — solo copia y pega. Claude instala las skills, configura el enrutador de triaje en `CLAUDE.md`, trae las 4 skills compatibles de Superpowers, verifica todo y hace el commit.

### Opción 2 — Plugin marketplace (con auto-update)

Dentro de Claude Code:

```
/plugin marketplace add LeopoldoJacobsen/claude-planning-kit
/plugin install planning-kit@claude-planning-kit
```

Las skills quedan disponibles como `/planning-kit:feature-planning` y `/planning-kit:plan-execution`. Después, agrega el bloque "Task Triage" de [`templates/CLAUDE-md-snippet.md`](templates/CLAUDE-md-snippet.md) al `CLAUDE.md` de cada repositorio.

### Opción 3 — Copia manual

Copia `plugins/planning-kit/skills/*` a `.claude/skills/` y `plugins/planning-kit/agents/*` a `.claude/agents/` del proyecto (o a `~/.claude/`, aplicando a todos los proyectos). Agrega el bloque de triaje al `CLAUDE.md`.

Detalles completos de las tres opciones en [INSTALL.md](INSTALL.md).

## Uso en el día a día

1. **Describe la mejora normalmente**, en portugués, inglés o español (ej.: "quiero un sistema de afiliados con comisión del 10%"). No hace falta decir "planifica".
2. El enrutador de triaje clasifica por sí solo:

| Nivel | Cuándo | Qué sucede |
|---|---|---|
| **DIRECT** | Corrección trivial, ≤2 archivos, sin tocar schema/API/env/auth/pagos | Lo hace directo |
| **LIGHT** | 3–10 archivos, lógica moderada | Mini-plan de 5–10 líneas en el chat; tú das el "go" |
| **FULL** | Feature nueva, schema de base de datos, contratos de API, env vars, auth, pagos, multi-tenant | Pipeline completo abajo |

3. **En el pipeline FULL:** una idea vaga pasa primero por el brainstorming. Después Claude explora el repositorio (discovery), hace **un único lote de preguntas** — la única pausa antes de la aprobación —, escribe el plan dividido en fases y un revisor independiente con contexto limpio valida todo.
4. **Tú apruebas el plan y confirmas los prerrequisitos de la Fase 0** (claves de API, cuentas, decisiones de producto) — recolectados una sola vez, al inicio.
5. **Ejecución continua:** Claude ejecuta todas las fases de agente en secuencia (las sesiones paralelas son bienvenidas; los locks evitan colisiones) y termina entregándote `user-tasks.md` — tu lista de pruebas manuales, validaciones y aprobaciones, agrupada al final para nunca bloquear a los agentes.

## Qué hay dentro

```
.claude-plugin/marketplace.json    # manifiesto del marketplace (habilita el /plugin marketplace add)
plugins/planning-kit/
  skills/feature-planning/         # máquina de estados de planificación (artefactos en planning/<slug>/)
  skills/plan-execution/           # ejecutor continuo: locks, worktrees, scope fence, definition of done
  agents/repo-explorer.md          # subagente read-only de descubrimiento (ventana de contexto propia)
  agents/plan-reviewer.md          # revisor adversarial de planes, con contexto limpio
templates/CLAUDE-md-snippet.md     # enrutador de triaje en 3 niveles para el CLAUDE.md de cada repo
prompts/                           # prompts de bootstrap (proyecto nuevo/existente) + versiones standalone
```

Las versiones standalone (`prompts/*-standalone.md`) sirven para agentes sin soporte de skills: pega el prompt entero en la sesión y el pipeline corre de la misma manera.

## Principios de diseño

- **Disco > chat:** cada fase graba un artefacto en `planning/<slug>/`; cualquier sesión retoma desde los archivos.
- **Continuo por defecto (v2):** las fases corren en secuencia en la misma sesión; `/clear` es una válvula de escape, no un ritual.
- **Trabajo humano en los bordes (v2):** los prerrequisitos se vuelven la Fase 0, recolectada al inicio; todo lo demás que depende de ti (QA manual, pruebas reales de pago/afiliado, DNS, aprobaciones) se secuencia DESPUÉS de la última fase de agente, en `user-tasks.md`. El revisor rechaza planes con pasos humanos enterrados a mitad de camino.
- **Paralelismo seguro:** las fases se reclaman vía lock files en el directorio `.git` compartido — sesiones independientes y compañeros de equipo nunca colisionan.
- **Compone con Superpowers:** `brainstorming` refina ideas vagas; `test-driven-development`, `systematic-debugging` y `requesting-code-review` entran en la ejecución. Los planners/executors de Superpowers NO se usan.

## Compatibilidad con Superpowers

Instala SOLAMENTE estas skills: `brainstorming`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`. NUNCA instales `writing-plans`, `executing-plans`, `subagent-driven-development` o `using-git-worktrees` junto con el kit — dos planners/executors pelean por el mismo disparador. Los prompts de bootstrap ya se encargan de esto automáticamente.

## Mejorando el kit

Trata el texto de las skills como código. Después de cada feature real: lee los logs de ejecución en `planning/<slug>/execution/`, incorpora las desviaciones recurrentes a las skills, sube la versión en los dos manifiestos (`plugin.json` y `marketplace.json`), haz commit y push. Los proyectos instalados vía marketplace reciben la actualización automáticamente; las copias vendored vuelven a ejecutar el prompt de bootstrap.
