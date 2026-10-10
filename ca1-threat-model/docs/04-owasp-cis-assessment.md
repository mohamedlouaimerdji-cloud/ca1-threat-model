# 04 – Assessment against OWASP Top 10 and CIS Benchmarks

**Target:** OWASP Juice Shop (`bkimminich/juice-shop`) in Docker on an Azure VM, reached only through an SSH tunnel (localhost-only).
**Standards used:**
- OWASP Top 10:**2025** (current edition, checked on top10.owasp.org on 9 Oct 2026).
- CIS Docker Benchmark **v1.6.0** (the version Docker Bench for Security v1.6.0 implements; confirmed in the tool's README).

> Status: DRAFT. A01 and A05 are now confirmed by hand (SQL injection login bypass). A07/A04 confirmed via browser DevTools observation. Remaining **(to confirm)**: A06 design review only, A08 not tested.

---

## 1. OWASP Top 10:2025

| Category | Applies? | Finding(s) | Evidence | How useful was this category for THIS target? |
|---|---|---|---|---|
| **A01 Broken Access Control** | Yes, **confirmed** | The SQL injection login bypass (`'or 1=1--`) is also a full authentication and access-control bypass: it grants an administrator session with no valid password. `/rest/admin/application-configuration` can also be read without logging in. `/ftp` folder is browsable (`package.json.bak`, `suspicious_errors.yml`). `Access-Control-Allow-Origin: *` lets any website read responses. | `sqli_login_bypass.png`, `private_ip_disclosure.png`, `cross_domaine_misconfiguration.png`, `zap-report.html`, `ZAP-Report.json` | **High, now with direct proof.** The admin login bypass is the clearest access-control failure in the assessment. |
| **A02 Security Misconfiguration** | Yes | No Content-Security-Policy, no X-Content-Type-Options, no anti-clickjacking header, CORS set to `*`. Container runs with default capabilities, writable filesystem, no limits. Original NSG had a default SSH-from-Any rule (threat M1, removed). | `no_Content-Security-Policy.png`, `cross_domaine_misconfiguration.png`, `clickjacking.png`, `docker-bench-bash.txt`, `docker_inspect.png`, `ssh_my_ip.png`, `VM_firewalls(public).png` | **High.** Best fit of all categories: it covers the app, the container and the cloud network in one place. |
| **A03 Software Supply Chain Failures** | Yes | Trivy reported **175 findings** in the image (10 CRITICAL, 55 HIGH, 86 MEDIUM, 24 LOW), so **65 are HIGH or CRITICAL**. Image is pulled from Docker Hub by tag, not pinned to a digest. | `trivy.json`, `trivy-high-critical.txt`, `trivy_total.png`, `trivy_summary_table_1.png`, `trivy_summary_table_2.png`, `trivy_findings_list_1.png`, `trivy_findings_list_2.png` | **High for the image, limited for the app.** Fits Trivy output well. Many packages are never reached by the app, so the count overstates real risk. |
| **A04 Cryptographic Failures** | Yes | The app has no TLS. The login request and the token cookie travel over plain `http://`, and the cookie has no Secure flag. Only the SSH tunnel is encrypted, and that protects our lab, not the app. The token header shows it is signed with RS256. Password hashing was **not tested**. | `http_evidence.png`, `auth_login_http.png`, `auth_cookies_evidence.png`, `docs/03-existing-controls.md` | **Medium.** The tunnel hides the risk in our lab, so the category is better for explaining what would happen if the app were public. |
| **A05 Injection** | Yes, **confirmed** | **SQL injection login bypass, proven by hand.** Entering `'or 1=1--` as the username (any text as password) on the login form logged us in as an admin account, with no valid password. The string is inserted directly into the SQL query; `1=1` is always true, so the login check passes. Juice Shop itself labels this challenge "Login Admin". ZAP separately raised a Low-confidence SQL Injection alert on `GET /rest/products/search?q=`, caused by a `'(` input returning a SQLite syntax error. | `sqli_login_bypass.png`, `zap-report.html` | **High, and the best example in the whole report.** This is proof, not a hint: a manual test confirmed exactly what the automated scanner only suspected, which is the strongest argument for doing both automated and manual testing. |
| **A06 Insecure Design** | Yes | Design-level gaps found in the threat model: no rate limiting, no separation between app and admin functions, container holds app and data together, CSRF exposure (threat M3). | `Threat_Model_triaged.tm7`, `threat_triage_all_65.csv`, `trust_boundry_diagram.png`, `1_threat_list.png`, `2_threat_list.png`, `docs/02-threat-model-stride.md` | **Medium, and mostly conceptual.** No scanner finds design flaws. Our STRIDE model is the evidence, so this category justifies doing threat modelling at all. |
| **A07 Authentication Failures** | Yes | The login token (a JWT) is stored in **two places**: browser Local Storage and a cookie named `token`. The cookie has **no HttpOnly, no Secure and no SameSite** flag, so page scripts can read it and the browser will send it over plain HTTP. The login request itself is `POST http://127.0.0.1:3000/rest/user/login` (plain HTTP). ZAP also found the Socket.IO session ID in the URL. **Not tested:** password policy, brute-force protection, token expiry and logout (this part was observation-only, no attack attempts). | `auth_storage_evidence.png`, `auth_cookies_evidence.png`, `auth_login_http.png`, `sessionID_in_URL_rewrite.png` | **High for the findings we observed, limited in depth.** The category fits what we saw, but the biggest authentication risks (weak passwords, no lockout) need active testing that was outside our observation-only scope. |
| **A08 Software or Data Integrity Failures** | Partly | Image is not verified by signature or digest. No other integrity test done. | `docker_inspect.png` | **Low here.** Little we tested maps to it. |
| **A09 Security Logging and Alerting Failures** | Yes | Only container logs exist. No central log, no alerts, no NSG flow logs. The scan's attack traffic raised no alert. | `docker_logs.png`, `docs/03-existing-controls.md` | **High.** Found by reviewing controls, not by any scanner, which shows scanners miss this category. |
| **A10 Mishandling of Exceptional Conditions** | Yes | The failing search request returns `500 Internal Server Error` with a SQLite error and stack trace shown to the user. | `sql__injection(critical).png` | **High.** Good fit, and a new category in 2025. |

---

## 2. CIS Benchmarks

### 2a. CIS Docker Benchmark v1.6.0 (run with Docker Bench for Security)

Result: **PASS 50, WARN 40, INFO 62** (`docker-bench-bash.txt`, `docker_bench1.png` to `docker_bench5.png`, `docker_bench_warnlist.png`).

Control IDs and results below are copied from `docker-bench-bash.txt` (checked 10 Oct 2026). I picked the controls that matter most for this target out of the 40 WARN results.

| Control ID | Recommendation (CIS wording) | Result | Evidence | Relevance to this target |
|---|---|---|---|---|
| 5.14 | Ensure that incoming container traffic is bound to a specific host interface | **PASS** | `dockerjuiceshop_running(localhost).png`: `127.0.0.1:3000->3000/tcp` | **High.** This is our main protection and the condition Dr Lemon set. |
| 5.5 | Ensure that privileged containers are not used | **PASS** | `docker_inspect.png`: Privileged=false | High. Stops a container break-out giving full host control. |
| 4.1 | Ensure that a user for the container has been created | **PASS** | `docker_inspect.png`: User=65532 | High. Limits what an attacker can do after a break-in. |
| 5.10 | Ensure that the host's network namespace is not shared | **PASS** | `docker-bench-bash.txt` | Medium. The app container has its own network. |
| 5.4 | Ensure that Linux kernel capabilities are restricted within containers | **PASS** (see note) | `docker_inspect.png`: CapDrop=[] | Medium. Tool passes it because nothing extra was added, but all default capabilities are still kept. |
| 5.13 | Ensure that the container's root filesystem is mounted as read only | **WARN** | `docker_inspect.png`: ReadOnly=false | Medium. Would stop an attacker writing files. May break Juice Shop. |
| 5.11 | Ensure that the memory usage for containers is limited | **WARN** | `docker_inspect.png`: Memory=0 | Medium. A flood of requests could use all VM memory. |
| 5.26 | Ensure that the container is restricted from acquiring additional privileges | **WARN** | `docker_inspect.png`: SecurityOpt=[] | Medium. no-new-privileges is not set. |
| 5.3 | Ensure that, if applicable, SELinux security options are set | **WARN** | `docker-bench-bash.txt` | **Low.** Ubuntu uses AppArmor by default, not SELinux, so this warning says little about our VM. |
| 5.12 | Ensure that CPU priority is set appropriately on containers | **WARN** | `docker-bench-bash.txt` | Low. A tuning setting, not a security hole here. |

**Note on 5.4:** a PASS here does not mean the container is minimal. `docker inspect` shows no capabilities were dropped. This is one example for the critical evaluation: the benchmark's pass/fail view hides the difference between "nothing extra added" and "least privilege".

### 2b. Other CIS Benchmarks (honest scope note)

CIS also publishes benchmarks for **Ubuntu 24.04** (the VM operating system) and for **Microsoft Azure** (the cloud platform). **We did not run these.** For the platform layer we reviewed the NSG, SSH settings and public IP by hand (`docs/03-existing-controls.md`). That is a manual review, not a benchmark result, and the report states it as a limitation.

---

## 3. Critical evaluation (where the marks are)

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
