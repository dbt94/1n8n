# MODEL-LINK — dieses Projekt ist ein Body von MasterModel.bd

**Was das bedeutet:** Dieses Projekt (1n8n) wird vom **Model** (`MasterModel.bd`) bedient —
ein projekt-agnostisches AI-Entwicklungs-System (Kopf/Regeln/Skills/Agenten/Guards). Das Model
ist Ebene 0/1, dieses Projekt konkretisiert es (Ebene 2), ersetzt es nie.

## So nutzt du das Model hier
- Installieren (idempotent): `bash MasterModel.bd/install.sh` → Skills/Regeln/Hooks nach `~/.claude`.
- Einstieg/Navigation: `MasterModel.bd/MASTERPROMPT.md` (Kopf) · `config/MASTER-NAVIGATION.md` ·
  `config/SKILLS-INDEX.md` (vor jeder Aufgabe scannen).
- Neues Projekt ideal aufsetzen: Skill `project-launch` (+ `agent-project-launch`).

## Lern-Schleife — das Model lernt mit (Muster ja, Fall nie)
Wenn hier etwas **Verallgemeinerbares** gelernt wird (eine Methode, ein Muster, ein Debugging-/
Workflow-Trick), wird es **ins Model zurückgespielt** — als generischer Skill/Agent/Lehre, nach
dem Pflicht-Verfahren **`model-contribution`**. **Projekt-private Daten** (Namen, Workflows,
Credentials, Business-Logik) bleiben in DIESEM Repo und gehen **nie** ins Model.
Mechanisch gesichert: `MasterModel.bd/guards/check-model.sh` (Namen) + `scan-sensitive.sh` (Felder).

## Leitplanken (aus dem Model, gelten auch hier)
Nie hart löschen (safe-archive) · nie ohne `git log` überschreiben · keine Secrets in Code/Commits ·
`main` nur mit Freigabe · jeden PR bis MERGED/CLOSED überwachen · GitHub-Zugriff via `mcp__github__*`.
