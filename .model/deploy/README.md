# Self-Hosting — die 1n8n-Speiche (Docker)

Bringt die Speiche auf **deinem eigenen Host** zum Laufen: n8n + Postgres, verdrahtet an den
Model-Kern (`mm`) und OmniRoute. **Kein Quellcode-Build nötig** — offizielles n8n-Image.

## Voraussetzungen (auf dem Host)
- Docker + Docker Compose v2 (laufender Daemon).
- `MasterModel.bd` **auf dem Host ausgecheckt** (der mm-Kern wird read-only als `/model` gemountet).

## Schritte
```bash
docker network create model-net   # einmalig — das geteilte Netz des Stacks (external)

cd .model/deploy
cp .env.example .env
#   MODEL_DIR        → absoluter Pfad zum ausgecheckten MasterModel.bd
#   POSTGRES_PASSWORD→ frei wählen
#   N8N_ENCRYPTION_KEY→ openssl rand -hex 24
$EDITOR .env

docker compose up -d            # startet n8n (5678) + Postgres
docker compose logs -f n8n      # hochfahren beobachten
```
Dann die Speiche importieren (n8n läuft im Container):
```bash
docker compose exec n8n n8n import:workflow --input=/model-workflows/worker-replica.json
```
In der n8n-UI (`http://localhost:5678`) den Workflow **aktivieren**. Test:
```bash
curl -X POST http://localhost:5678/webhook/worker-1n8n -H 'content-type: application/json' \
     -d '{"intent":"pdf komprimieren"}'
```
Der Execute-Command-Node läuft dann `node /model/bin/mm guard|run …` im Container — `MODEL_DIR=/model`
ist gesetzt, `mm` hat 0 Runtime-Deps.

## LLM über OmniRoute (selbst gehostet)
`OMNIROUTE_BASE_URL` zeigt per Default auf `http://omniroute:20128` im geteilten Netz `model-net`.
OmniRoute im eigenen Repo mit dem mitgelieferten Netz-Override starten:
```bash
# im omniroute-Repo:
docker compose -f docker-compose.yml -f docker-compose.model-net.yml --profile base up -d
```
Der Override (`docker-compose.model-net.yml`) hängt den Gateway an `model-net` (Alias `omniroute`),
ohne die redis-Erreichbarkeit zu verlieren. Danach erreicht n8n den Gateway unter `http://omniroute:20128`.

## Zu „100% selbst gehostet" wachsen
Das Netz `model-net` ist der Anschlusspunkt. Weitere Bodies treten als **external network** bei und
werden so Teil desselben selbst-gehosteten Stacks:
- **OmniRoute** — LLM-Gateway (ein Key, alle Provider)
- **open-webui** — Chat-Oberfläche · **stirling-pdf** — PDF-Werkzeuge · **dify/langflow** — LLM-Apps/Flows
- **Coolify** (Body) — PaaS, um den ganzen Stack per UI zu betreiben statt per Hand-Compose

Jeder Body bleibt sein eigenes Repo mit eigenen Secrets; n8n orchestriert sie über den mm-Kern.

## Sicherheit / Betrieb
- `.env` (Passwörter/Keys) wird **nicht** committet (`.model/.gitignore`).
- Für öffentliche Erreichbarkeit einen Reverse-Proxy (TLS) davor setzen und `N8N_HOST`/`WEBHOOK_URL`
  auf die echte Domain stellen. Standard hört nur lokal auf `5678`.

## Verifikationsstand
Strukturell verifiziert: `docker compose config` löst sauber auf (Images, Env, Volumes, Netz).
**Nicht** in dieser Umgebung gestartet (kein Docker-Daemon/kein Host) — der Live-Lauf passiert auf
deinem Host mit obigen Schritten.
