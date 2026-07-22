# `.model/` — die 1n8n-Speiche des Models

Dieses Verzeichnis macht den **1n8n-Body** zur **live Speiche** von
[`MasterModel.bd`](../.claude/MODEL-LINK.md). Es fasst **kein** Upstream-n8n an — es liegt
out-of-band unter `.model/` und verdrahtet nur, wie diese n8n-Laufzeit den **`mm`-Kern** des
Models ruft.

## Prinzip (Ring/Speichen — `MasterModel.bd/ARCHITEKTUR.md`)

Der Kern (`mm`) **denkt, gatet, routet**; n8n ist die **Automations-Oberfläche** darüber. Eine
Anfrage läuft den Fluss **9 → Ring 2 (guard) → Ring 3 (`mm run`, Direktor→Kritiker+Gate) → 10**.
So bleibt es **eine** Quelle der Wahrheit — n8n baut keinen zweiten Regel-/Index-Layer.

```
POST /webhook/worker-1n8n  { "intent": "<aufgabe>" }
        │
        9 Anfrage ──▶ Ring 2 · mm guard ──▶ Ring 3 · mm run (gated) ──▶ 10 Ausgabe → Prüfer(7)
```

## Inhalt

| Datei | Zweck |
|---|---|
| `workflows/worker-replica.json` | projekt-fertige Speiche (dieser Body). Nur verifizierte Node-Typen (webhook · executeCommand · respondToWebhook), graph-valide. |
| `.env.example` | Verdrahtung: `MODEL_DIR` (Pfad zum Model-Repo) + `OMNIROUTE_BASE_URL`. Echte Werte nie committen. |
| `import-spoke.sh` | importiert die Speiche via `packages/cli/bin/n8n import:workflow`. |

## In Betrieb nehmen

1. `cp .model/.env.example .model/.env` und `MODEL_DIR` auf das ausgecheckte `MasterModel.bd` setzen.
2. Monorepo bauen (`pnpm install && pnpm build`) — liefert die n8n-CLI.
3. `bash .model/import-spoke.sh` — importiert den Workflow.
4. In der n8n-UI aktivieren. `MODEL_DIR` muss im **n8n-Prozess-Env** stehen (der Execute-Command-Node
   läuft mit `shell:true`, darum expandiert `${MODEL_DIR}` echt).
5. Test: `curl -X POST .../webhook/worker-1n8n -d '{"intent":"pdf komprimieren"}'`.

## Verdrahtung — Details

- **`mm` lokal, nicht via GitHub-Raw.** Execute-Command ruft `node ${MODEL_DIR}/bin/mm …`. Das
  Model-Repo ist privat/auf Feature-Branch — kein Netz-Fetch.
- **Trocken by default.** `mm run` läuft ohne `--execute` (zeigt Plan/Gate). Echtes Handeln nur mit
  `--execute --approve` **hinter** einer Freigabe — das ist ein Gate (Ring 2), kein Default.
- **LLM über den Gateway.** AI-Agent-Nodes zeigen auf `${OMNIROUTE_BASE_URL}/v1` (ein Key, alle Provider).
- **Eigenes Gedächtnis je Projekt.** Diese Replik liest/schreibt ihr **eigenes** Wiki
  (`mm`/`wiki-builder --scope project`) → „lernt spezifisch für sich". Nur **Muster** fließen via
  `mm learn` zurück in den Kern; **projekt-private Daten bleiben hier**.

## Was hier NICHT hingehört

Kein Model-Regelwerk kopieren (das lebt im Model, via `MODEL-LINK.md` referenziert). Keine Secrets.
Feinschliff (Auth, Retries, Fehlerpfade) gehört in **diesen** Body — nicht ins Model.

> Status: strukturell verifiziert (JSON + Graph, Node-Typen gegen den Fork geprüft). **End-to-End
> (echter Import/Lauf) braucht die gebaute n8n-Laufzeit** — in dieser flüchtigen Umgebung nicht getestet.
