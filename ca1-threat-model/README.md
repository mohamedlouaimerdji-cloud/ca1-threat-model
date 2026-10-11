# CA1 – Threat Modelling and Vulnerability Assessment of a Cloud-Hosted Application

**Module:** Data and Application Security
**Student:** 2026197, MSc Cybersecurity, CCT College Dublin
**Target:** OWASP Juice Shop (`bkimminich/juice-shop`), deployed in Docker on a self-managed Azure VM
**Authorisation:** self-deployed instance on the student's own Azure account, localhost-only access; see `docs/00-authorisation.md`

## What this is

This repository holds the evidence, scans, and supporting documents for a threat model and vulnerability assessment of an intentionally vulnerable web application, covering both the application layer and the cloud platform it runs on.

## Repository structure

```
ca1-threat-model/
├── docs/                          Written analysis (the content behind the report)
│   ├── 00-authorisation.md        Scope and authorisation statement
│   ├── 01-system-description.md   Components, trust boundaries, data flow diagram
│   ├── 02-threat-model-stride.md  STRIDE threat model
│   ├── 03-existing-controls.md    Controls review (what's in place, what's missing)
│   ├── 04-owasp-cis-assessment.md OWASP Top 10:2025 and CIS Benchmark assessment
│   ├── 05-findings-cvss.md        Top findings, scored with CVSS v3.1
│   └── 06-ai-fluency-log.md       Log of AI assistance used on this assignment
├── evidence/
│   ├── diagrams/                  Threat model file (.tm7) and trust boundary diagram
│   ├── scans/                     Raw scan output: Trivy, Docker Bench, OWASP ZAP
│   └── screenshots/                Supporting screenshots for every finding
├── scripts/                       Scan automation scripts
└── docker/                        Docker/Docker Compose files used for the deployment
```

## Tools used

| Tool | Purpose |
|---|---|
| Docker | Runs the Juice Shop container, localhost-only |
| Microsoft Threat Modeling Tool | STRIDE threat model and trust boundary diagram |
| Trivy | Container image vulnerability scan |
| Docker Bench for Security | CIS Docker Benchmark v1.6.0 check |
| OWASP ZAP | Automated scan (spider, AJAX spider, active scan) of the running app |
| FIRST CVSS v3.1 Calculator | Scoring of top findings |

## Key finding

A SQL injection in the login form (`'or 1=1--`) allows a full authentication bypass with no valid password, confirmed by hand and scored **CVSS 9.1 (Critical)**. Full details in `docs/05-findings-cvss.md`.

## Reproducing the scans

See `scripts/run-scans.sh`. All scans were run against a local, localhost-only instance, accessed only via an authenticated SSH tunnel — not against any public or third-party system.

## AI use disclosure

Claude was used to assist with explaining tools and concepts, drafting documentation structure, and reviewing evidence against the assessment criteria. All commands were run and all scans were performed by the student. See `docs/06-ai-fluency-log.md` for the full log, as required by the assignment brief.
