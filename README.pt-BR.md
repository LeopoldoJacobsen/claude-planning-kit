# claude-planning-kit

[English](README.md) | **Português (BR)** | [Español](README.es.md)

Kit de planejamento e execução para o Claude Code. Funciona como um "prompt inicial" reutilizável: você instala em qualquer projeto (novo ou existente) e o Claude passa a planejar e executar melhorias de forma estruturada — com descoberta do código, perguntas em lote, plano revisado por um agente independente e execução contínua à prova de conflitos.

> **Visão geral visual:** [leopoldojacobsen.github.io/claude-planning-kit](https://leopoldojacobsen.github.io/claude-planning-kit/) — como funciona, o workflow completo e o que ele faz / não faz, numa página só (em inglês).

**O loop completo:**

```
triagem → (brainstorm se a ideia for vaga) → discovery → perguntas → plano
       → revisão independente → execução contínua → checklist final humano
```

Tudo vira arquivo em `planning/<slug>/` — qualquer sessão retoma de onde parou, sem depender do histórico do chat.

## Instalação

> O kit já está instalado no projeto? Não há nada para decorar nem comando para rodar — é só descrever o que você quer. Veja [Como usar no dia a dia](#como-usar-no-dia-a-dia).

### Opção 1 — Prompt de bootstrap (recomendado: o Claude faz tudo)

| Situação | O que fazer |
|---|---|
| **Projeto existente** | Abra o Claude Code na raiz do repositório e cole o conteúdo de [`prompts/BOOTSTRAP-EXISTING-PROJECT.md`](prompts/BOOTSTRAP-EXISTING-PROJECT.md) |
| **Projeto novo (pasta vazia)** | Abra o Claude Code na pasta e cole [`prompts/BOOTSTRAP-NEW-PROJECT.md`](prompts/BOOTSTRAP-NEW-PROJECT.md), trocando apenas `<PROJECT-NAME>` pelo nome do projeto |

Os prompts já apontam para este repositório (`LeopoldoJacobsen/claude-planning-kit`) — é só copiar e colar. O Claude instala as skills, configura o roteador de triagem no `CLAUDE.md`, puxa as 4 skills compatíveis do Superpowers, verifica tudo e commita.

### Opção 2 — Plugin marketplace (com auto-update)

Dentro do Claude Code:

```
/plugin marketplace add LeopoldoJacobsen/claude-planning-kit
/plugin install planning-kit@claude-planning-kit
```

As skills ficam disponíveis como `/planning-kit:feature-planning` e `/planning-kit:plan-execution`. Depois, adicione o bloco "Task Triage" de [`templates/CLAUDE-md-snippet.md`](templates/CLAUDE-md-snippet.md) ao `CLAUDE.md` de cada repositório.

### Opção 3 — Cópia manual

Copie `plugins/planning-kit/skills/*` para `.claude/skills/` e `plugins/planning-kit/agents/*` para `.claude/agents/` do projeto (ou para `~/.claude/`, valendo para todos os projetos). Adicione o bloco de triagem ao `CLAUDE.md`.

Detalhes completos das três opções em [INSTALL.md](INSTALL.md).

## Como usar no dia a dia

1. **Descreva a melhoria normalmente**, em português, inglês ou espanhol (ex.: "quero um sistema de afiliados com comissão de 10%"). Não precisa dizer "planeje".
2. O roteador de triagem classifica sozinho:

| Nível | Quando | O que acontece |
|---|---|---|
| **DIRECT** | Correção trivial, ≤2 arquivos, sem tocar schema/API/env/auth/pagamentos | Faz direto |
| **LIGHT** | 3–10 arquivos, lógica moderada | Mini-plano de 5–10 linhas no chat; você dá o "go" |
| **FULL** | Feature nova, schema de banco, contratos de API, env vars, auth, pagamentos, multi-tenant | Pipeline completo abaixo |

3. **No pipeline FULL:** ideia vaga passa primeiro pelo brainstorming. Depois o Claude explora o repositório (discovery), faz **um lote único de perguntas** — a única pausa antes da aprovação —, escreve o plano dividido em fases e um revisor independente com contexto limpo valida tudo.
4. **Você aprova o plano e confirma os pré-requisitos da Fase 0** (chaves de API, contas, decisões de produto) — coletados uma única vez, no início.
5. **Execução contínua:** o Claude executa todas as fases de agente em sequência (sessões paralelas são bem-vindas; locks evitam colisão) e termina entregando o `user-tasks.md` — sua lista de testes manuais, validações e aprovações, agrupada no final para nunca travar os agentes.
6. **Executar ou retomar depois:** em qualquer sessão nova, diga "continue o plano" ou "execute o plano do sistema-de-afiliados" — ou simplesmente cite a pasta `planning/<slug>/`. O estado vive em disco, então a execução retoma exatamente de onde parou, mesmo dias depois ou na máquina de um colega.

## O que tem dentro

```
.claude-plugin/marketplace.json    # manifesto do marketplace (habilita o /plugin marketplace add)
plugins/planning-kit/
  skills/feature-planning/         # máquina de estados do planejamento (artefatos em planning/<slug>/)
  skills/plan-execution/           # executor contínuo: locks, worktrees, scope fence, definition of done
  agents/repo-explorer.md          # subagente read-only de descoberta (janela de contexto própria)
  agents/plan-reviewer.md          # revisor adversarial de planos, com contexto limpo
templates/CLAUDE-md-snippet.md     # roteador de triagem em 3 níveis para o CLAUDE.md de cada repo
prompts/                           # prompts de bootstrap (projeto novo/existente) + versões standalone
```

As versões standalone (`prompts/*-standalone.md`) servem para agentes sem suporte a skills: cole o prompt inteiro na sessão e o pipeline roda do mesmo jeito.

## Princípios de design

- **Disco > chat:** cada fase grava um artefato em `planning/<slug>/`; qualquer sessão retoma pelos arquivos.
- **Contínuo por padrão (v2):** as fases rodam em sequência na mesma sessão; `/clear` é válvula de escape, não ritual.
- **Trabalho humano nas bordas (v2):** pré-requisitos viram a Fase 0, coletada no início; todo o resto que depende de você (QA manual, testes reais de pagamento/afiliado, DNS, aprovações) é sequenciado DEPOIS da última fase de agente, no `user-tasks.md`. O revisor rejeita planos com passos humanos enterrados no meio.
- **Paralelismo seguro:** fases são reivindicadas via lock files no diretório `.git` compartilhado — sessões independentes e colegas de equipe nunca colidem.
- **Compõe com Superpowers:** `brainstorming` refina ideias vagas; `test-driven-development`, `systematic-debugging` e `requesting-code-review` entram na execução. Os planners/executors do Superpowers NÃO são usados.

## Compatibilidade com Superpowers

Instale SOMENTE estas skills: `brainstorming`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`. NUNCA instale `writing-plans`, `executing-plans`, `subagent-driven-development` ou `using-git-worktrees` junto com o kit — dois planners/executors brigam pelo mesmo gatilho. Os prompts de bootstrap já cuidam disso automaticamente.

## Melhorando o kit

Trate o texto das skills como código. Depois de cada feature real: leia os logs de execução em `planning/<slug>/execution/`, incorpore desvios recorrentes às skills, suba a versão nos dois manifestos (`plugin.json` e `marketplace.json`), commite e dê push. Projetos instalados via marketplace recebem a atualização automaticamente; cópias vendored re-rodam o prompt de bootstrap.
