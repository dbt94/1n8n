# n8n selbst hosten — Anleitung

Praktische Schritt-für-Schritt-Anleitung, um **n8n dauerhaft** zu betreiben — mit
Postgres und persistenten Daten. Enthält zwei Wege: **eigener Server (Docker Compose)**
und **Railway** (empfohlen, weil bizzplug ohnehin Railway nutzt).

> **Warum nicht in der Claude-Cloud-Umgebung?** Die ist **flüchtig** — der Container wird
> nach Inaktivität verworfen. n8n braucht dauerhaften Speicher + eine feste URL für Webhooks.
> Deshalb: echte Infra (eigener Server / Railway), nicht die Session-Umgebung.

---

## 0. Voraussetzungen

- Eine **Domain oder feste URL** (für Webhooks & HTTPS) — optional lokal, Pflicht produktiv.
- **Docker** + **Docker Compose v2** (eigener Server) **oder** ein **Railway**-Account.
- Ein **Encryption Key** (einmal erzeugen, nie ändern):
  ```bash
  openssl rand -hex 32
  ```
  Ohne stabilen Key sind gespeicherte Credentials nach einem Neustart unbrauchbar.

---

## Weg A — Eigener Server / lokal (Docker Compose)

Dateien liegen in `deploy/`: `docker-compose.yml`, `.env.example`.

```bash
# 1) Env-Vorlage kopieren und ausfüllen
cp deploy/.env.example deploy/.env
#    -> POSTGRES_PASSWORD, N8N_ENCRYPTION_KEY (openssl rand -hex 32),
#       N8N_HOST/WEBHOOK_URL (Domain), N8N_PROTOCOL=https bei Domain

# 2) Starten
docker compose -f deploy/docker-compose.yml --env-file deploy/.env up -d

# 3) Logs prüfen
docker compose -f deploy/docker-compose.yml logs -f n8n

# 4) Öffnen
#    lokal:  http://localhost:5678
#    beim ERSTEN Aufruf: Owner-Account (E-Mail + Passwort) anlegen.
```

**Stoppen / Update / Backup:**
```bash
docker compose -f deploy/docker-compose.yml down           # stoppen (Daten bleiben in Volumes)
docker compose -f deploy/docker-compose.yml pull && \
  docker compose -f deploy/docker-compose.yml up -d         # auf neueste n8n-Version updaten
# Postgres-Backup:
docker compose -f deploy/docker-compose.yml exec postgres \
  pg_dump -U n8n n8n > n8n-backup-$(date +%F).sql
```

### HTTPS / Domain (produktiv)
n8n selbst macht kein TLS — einen **Reverse Proxy** davor setzen (Caddy/Traefik/Nginx):
- Proxy terminiert HTTPS und leitet auf `n8n:5678` weiter.
- In `.env`: `N8N_PROTOCOL=https`, `N8N_HOST=n8n.deinedomain.de`,
  `WEBHOOK_URL=https://n8n.deinedomain.de/`.
- Caddy-Beispiel (`Caddyfile`): `n8n.deinedomain.de { reverse_proxy n8n:5678 }` (Auto-HTTPS).

---

## Weg B — Railway (empfohlen)

Railway betreibt bizzplug schon — n8n passt daneben.

1. **Neues Projekt** → **Deploy → Docker Image** → `n8nio/n8n:latest`
   (oder aus dieser Fork bauen, siehe unten).
2. **Postgres** hinzufügen: im Projekt **+ New → Database → PostgreSQL**. Railway legt
   `PGHOST/PGPORT/PGUSER/PGPASSWORD/PGDATABASE` an.
3. **Variables** beim n8n-Service setzen:
   ```
   DB_TYPE=postgresdb
   DB_POSTGRESDB_HOST=${{Postgres.PGHOST}}
   DB_POSTGRESDB_PORT=${{Postgres.PGPORT}}
   DB_POSTGRESDB_DATABASE=${{Postgres.PGDATABASE}}
   DB_POSTGRESDB_USER=${{Postgres.PGUSER}}
   DB_POSTGRESDB_PASSWORD=${{Postgres.PGPASSWORD}}
   N8N_ENCRYPTION_KEY=<openssl rand -hex 32>
   N8N_HOST=<dein-service>.up.railway.app
   N8N_PROTOCOL=https
   WEBHOOK_URL=https://<dein-service>.up.railway.app/
   N8N_EDITOR_BASE_URL=https://<dein-service>.up.railway.app/
   N8N_PORT=5678
   GENERIC_TIMEZONE=Europe/Berlin
   N8N_RUNNERS_ENABLED=true
   N8N_DIAGNOSTICS_ENABLED=false
   ```
4. **Persistenz:** ein **Volume** an den n8n-Service mounten auf `/home/node/.n8n`
   (Railway → Service → **Volumes**). Sonst gehen lokale Dateien/Keys verloren.
5. **Port/Domain:** Railway erkennt Port 5678; unter **Settings → Networking** eine Domain
   generieren → in `N8N_HOST`/`WEBHOOK_URL` eintragen und Service neu deployen.
6. Beim ersten Aufruf **Owner-Account** anlegen.

---

## Eigene Fork bauen (statt offiziellem Image)

Diese Fork (`dbt94/1n8n`) kann als eigenes Image gebaut werden — nur nötig, wenn du am
n8n-Code selbst etwas änderst. Sonst reicht `n8nio/n8n:latest`.

- Build-Kontext liegt unter `docker/images/` im Repo.
- In `deploy/docker-compose.yml` beim `n8n`-Service `image:` durch `build:` ersetzen und
  auf den Dockerfile-Pfad der Fork zeigen (siehe `docker/images/n8n/Dockerfile`).
- Hinweis: Der Build des Monorepos (pnpm + turbo) ist schwer/langsam — nur bei echtem
  Code-Bedarf. Für reines Hosting ohne Code-Änderung immer das offizielle Image nehmen.

---

## Sicherheit (Pflicht)

- **`deploy/.env` NIE committen** — nur `.env.example` (Platzhalter). Empfohlen in
  `.gitignore`: `deploy/.env`.
- **`N8N_ENCRYPTION_KEY`** wie ein Secret behandeln, sichern, nie ändern.
- **Owner-Account** mit starkem Passwort; n8n hinter HTTPS betreiben.
- Secrets (API-Keys für Nodes) liegen verschlüsselt in n8n — Backup von `n8n_data`-Volume
  **und** Postgres nicht vergessen.
- Öffentlich erreichbare Instanz: Zugriff einschränken (Proxy-Auth/Firewall), Webhooks
  bewusst freigeben.

---

## Bezug zu diesem Projekt

- **Workflow-Wissen** (Nodes/Trigger/Expressions): Skill `n8n-reference` (komprimierte Doku).
- **Echter Quellcode / Node-Verhalten**: diese Fork (`packages/nodes-base`).
- **Ideen:** Bizzplug-Events (Stripe/Wise/SignalWire-Webhooks) → n8n → Slack/Sheets/CRM,
  Reports, Reminder — als No-/Low-Code-Automation neben dem Backend.
