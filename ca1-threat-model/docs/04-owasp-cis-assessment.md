# 04 – Assessment against OWASP Top 10 and CIS Benchmarks

**Target:** OWASP Juice Shop (`bkimminich/juice-shop`) in Docker on an Azure VM, reached only through an SSH tunnel (localhost-only).
**Standards used:**
- OWASP Top 10:**2025** (current edition, checked on top10.owasp.org on 9 Oct 2026).
- CIS Docker Benchmark **v1.6.0** (the version Docker Bench for Security v1.6.0 implements; confirmed in the tool's README).

> Status: DRAFT. Rows marked **(to confirm)** need the hands-on tests planned for Saturday. Do not claim them as proven until a screenshot exists.

---

## 1. OWASP Top 10:2025

| Category | Applies? | Finding(s) | Evidence | How useful was this category for THIS target? |
|---|---|---|---|---|
| **A01 Broken Access Control** | Yes | `/rest/admin/application-configuration` can be read without logging in. `/ftp` folder is browsable (`package.json.bak`, `suspicious_errors.yml`). `Access-Control-Allow-Origin: *` lets any website read responses. Further access-control tests **(to confirm)**. | `private_ip_disclosure.png`, `cross_domaine_misconfiguration.png`, `zap-report.html`, `ZAP-Report.json` | **High.** Juice Shop is built around this. But a scanner cannot know who *should* be allowed to see what, so real access-control flaws need manual testing. |
| **A02 Security Misconfiguration** | Yes | No Content-Security-Policy, no X-Content-Type-Options, no anti-clickjacking header, CORS set to `*`. Container runs with default capabilities, writable filesystem, no limits. Original NSG had a default SSH-from-Any rule (threat M1, removed). | `no_Content-Security-Policy.png`, `cross_domaine_misconfiguration.png`, `clickjacking.png`, `docker-bench-bash.txt`, `docker_inspect.png`, `ssh_my_ip.png`, `VM_firewalls(public).png` | **High.** Best fit of all categories: it covers the app, the container and the cloud network in one place. |
| **A03 Software Supply Chain Failures** | Yes | Trivy found HIGH/CRITICAL vulnerabilities in packages inside the image (69 in the JSON; confirm exact figure). Image is pulled from Docker Hub by tag, not pinned to a digest. | `trivy.json`, `trivy-high-critical.txt`, `trivy_total.png`, `trivy_summary_table_1.png`, `trivy_summary_table_2.png`, `trivy_findings_list_1.png`, `trivy_findings_list_2.png` | **High for the image, limited for the app.** Fits Trivy output well. Many packages are never reached by the app, so the count overstates real risk. |
| **A04 Cryptographic Failures** | Yes | The app is served over plain HTTP, no TLS. Only the SSH tunnel is encrypted. Password hashing and JWT signing **(to confirm)**. | `http_evidence.png`, `docs/03-existing-controls.md` | **Medium.** The tunnel hides the risk in our lab, so the category is better for explaining what would happen if the app were public. |
| **A05 Injection** | Yes | ZAP raised SQL Injection (High, **Low confidence**) on `GET /rest/products/search?q=`. A `'(` input caused `SQLITE_ERROR: near "(": syntax error`. XSS **(to confirm)**. | `sql__injection(critical).png`, `sqlinjection_web_confirmation.png` (check what this one shows), `zap-report.html` | **High.** Matches the scanner finding directly, but ZAP gives only a hint. Manual testing is needed to prove it. |
| **A06 Insecure Design** | Yes | Design-level gaps found in the threat model: no rate limiting, no separation between app and admin functions, container holds app and data together, CSRF exposure (threat M3). | `Threat_Model_triaged.tm7`, `threat_triage_all_65.csv`, `trust_boundry_diagram.png`, `1_threat_list.png`, `2_threat_list.png`, `docs/02-threat-model-stride.md` | **Medium, and mostly conceptual.** No scanner finds design flaws. Our STRIDE model is the evidence, so this category justifies doing threat modelling at all. |
| **A07 Authentication Failures** | Yes **(to confirm)** | Socket.IO session ID travels in the URL (ZAP). Login, weak passwords and JWT handling not yet tested by hand. | `sessionID_in_URL_rewrite.png`; hand tests pending | **High for Juice Shop, but not yet evidenced.** |
| **A08 Software or Data Integrity Failures** | Partly | Image is not verified by signature or digest. No other integrity test done. | `docker_inspect.png` | **Low here.** Little we tested maps to it. |
| **A09 Security Logging and Alerting Failures** | Yes | Only container logs exist. No central log, no alerts, no NSG flow logs. The scan's attack traffic raised no alert. | `docker_logs.png`, `docs/03-existing-controls.md` | **High.** Found by reviewing controls, not by any scanner, which shows scanners miss this category. |
| **A10 Mishandling of Exceptional Conditions** | Yes | The failing search request returns `500 Internal Server Error` with a SQLite error and stack trace shown to the user. | `sql__injection(critical).png` | **High.** Good fit, and a new category in 2025. |

---

## 2. CIS Benchmarks

### 2a. CIS Docker Benchmark v1.6.0 (run with Docker Bench for Security)

Result: **PASS 50, WARN 40, INFO 62** (`docker-bench-bash.txt`, `docker_bench1.png` to `docker_bench5.png`, `docker_bench_warnlist.png`).

> Before submitting, copy the **exact control IDs** from `docker-bench-bash.txt`. The IDs below are from the container section (5.x) and must be checked against your output.

| Control ID | Recommendation | Pass/Fail | Evidence | Relevance to this target |
|---|---|---|---|---|
| 5.4 | Do not use privileged containers | **Pass** | `docker_inspect.png`: Privileged=false | High. Stops a full host takeover through the container. |
| 5.13 | Bind incoming container traffic to a specific host interface | **Pass** | `dockerjuiceshop_running(localhost).png`: `127.0.0.1:3000->3000/tcp` | High. This is our main protection and the condition Dr Lemon set. |
| 4.1 | Run the container as a non-root user | **Pass** | `docker_inspect.png`: User=65532 | High. Limits what an attacker can do after a break-in. |
| 5.12 | Mount the container root filesystem read-only | **Fail** | `docker_inspect.png`: ReadOnly=false | Medium. Would block an attacker from writing files. May break Juice Shop. |
| 5.10 | Limit memory use | **Fail** | `docker_inspect.png`: Memory=0 | Medium. A flood of requests could use all VM memory. |
| 5.3 | Restrict Linux kernel capabilities | **Fail** | `docker_inspect.png`: CapDrop=[] | Medium. Default capabilities are more than the app needs. |
| 5.25 | Block extra privileges (no-new-privileges) | **Fail** | `docker_inspect.png`: SecurityOpt=[] | Medium. |

### 2b. Other CIS Benchmarks (honest scope note)

CIS also publishes benchmarks for **Ubuntu 24.04** (the VM operating system) and for **Microsoft Azure** (the cloud platform). **We did not run these.** For the platform layer we reviewed the NSG, SSH settings and public IP by hand (`docs/03-existing-controls.md`). That is a manual review, not a benchmark result, and the report states it as a limitation.

---

## 3. Critical evaluation 

**Where the standards fit well**
- **OWASP Top 10:2025** gave one shared vocabulary for results from different tools. A02, A03, A05 and A10 each matched a concrete finding.
- **CIS Docker Benchmark** gave a clear checklist for the container. Its Pass/Fail result is easy to explain and the evidence is a single command.

**Where they missed or misled**
- **Intentionally vulnerable app.** In a normal system a Fail means "fix this". In Juice Shop the weaknesses are the point, so Fail counts say little about the quality of the setup. The useful question is what *we* added around it (localhost-only, key-only SSH, restricted NSG), and the benchmarks barely measure that.
- **OWASP is a category list, not a test.** It says what kinds of weakness exist, not whether this app has them. Each row still needs its own evidence.
- **Scanner output over-reports.** Trivy flags packages the app may never use. ZAP flagged missing clickjacking headers on `socket.io` API calls, where the risk is small. ZAP's SQL Injection alert has Low confidence and needs manual proof.
- **Scanners under-report.** A06 (design), A09 (logging) and real access-control logic came from the threat model and the controls review, not from tools.
- **CIS covers the Docker host and container, not the app.** Nothing in it says the search box is injectable.

**Scoring and prioritisation gaps**
- OWASP gives no severity. CIS gives only Pass/Fail. ZAP and Trivy use their own scales. We therefore use **CVSS** (`docs/05-findings-cvss.md`) to rank, and add context (localhost-only exposure lowers the real-world score here).

**Not covered by either standard**
- The Azure platform layer (not run), business-logic flaws, and anything that depends on how the app is used in production.
