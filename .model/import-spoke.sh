#!/usr/bin/env bash
# import-spoke.sh — importiert die Model-Speiche in DIESE n8n-Laufzeit.
#
# Voraussetzung: n8n dieses Forks ist gebaut (die CLI liegt unter packages/cli/bin/n8n) und
# MODEL_DIR ist gesetzt (siehe .model/.env.example). Idempotent: n8n dedupliziert per Workflow-ID
# nicht automatisch — mehrfacher Import legt Kopien an; darum vor Re-Import ggf. alte Version löschen.
#
# Aufruf:  bash .model/import-spoke.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

# .env laden, falls vorhanden (MODEL_DIR/OMNIROUTE_*)
[ -f "$HERE/.env" ] && { set -a; . "$HERE/.env"; set +a; }
: "${MODEL_DIR:?MODEL_DIR nicht gesetzt — .model/.env aus .env.example anlegen}"
[ -x "$MODEL_DIR/bin/mm" ] || [ -f "$MODEL_DIR/bin/mm" ] || { echo "⚠️  mm-Kern nicht gefunden unter $MODEL_DIR/bin/mm"; exit 2; }

# n8n-CLI dieses Forks finden
N8N="$REPO/packages/cli/bin/n8n"
[ -x "$N8N" ] || N8N="$(command -v n8n || true)"
[ -n "$N8N" ] || { echo "⚠️  n8n-CLI nicht gefunden — erst das Monorepo bauen (pnpm build)."; exit 2; }

echo "→ importiere Speiche in n8n …"
"$N8N" import:workflow --input="$HERE/workflows/worker-replica.json"
echo "✓ importiert. In der n8n-UI aktivieren; Webhook: POST /webhook/worker-1n8n  (Body: { \"intent\": \"…\" })."
echo "  MODEL_DIR muss im n8n-Prozess-Env gesetzt sein, damit der Execute-Command-Node den mm-Kern findet."
