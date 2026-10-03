# CA1 — Threat Modelling & Vulnerability Assessment (Data and Application Security)
CCT College Dublin, MSc Cybersecurity. Deadline: **Tue 13 Oct 2026, 23:59** via Moodle.

Target: OWASP Juice Shop (intentionally vulnerable). Local-only, bound to 127.0.0.1.

## Work order
1. `docker compose -f docker/docker-compose.yml up -d` then open http://localhost:3000
2. Fill `docs/00` and `docs/01`, draw the diagram (save in `diagrams/`)
3. STRIDE table `docs/02`, controls `docs/03`
4. `./scripts/run-scans.sh` then evidence in `evidence/scans/`; manual testing screenshots in `evidence/screenshots/`
5. OWASP/CIS `docs/04`, CVSS `docs/05`
6. Write report in `report/` (~2,000 words ±10%, Harvard refs, CCT cover page, AI Fluency appendix)

Report word count excludes references and appendices.
