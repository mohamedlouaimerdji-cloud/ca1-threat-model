# 05 – Findings, ranked by CVSS

**CVSS version used:** CVSS v3.1 (chosen for consistency with the most widely used scoring tool, the FIRST.org calculator).




---

## F1 – SQL injection authentication bypass (highest priority)

**What it is:** entering `'or 1=1--` as the username on the login form bypasses authentication entirely and logs in as an administrator, with no valid password. Confirmed by hand.

**CVSS v3.1 vector:** `AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N`

| Metric | Value | Why |
|---|---|---|
| Attack Vector | Network (N) | Exploited through the normal login web form. |
| Attack Complexity | Low (L) | No special conditions needed; a single crafted username works every time. |
| Privileges Required | None (N) | Done before any login. |
| User Interaction | None (N) | The attacker does this directly; no victim needed. |
| Scope | Unchanged (U) | Stays inside the same application/database. |
| Confidentiality | High (H) | Full admin access exposes all user and order data. |
| Integrity | High (H) | An admin session can change any data in the app. |
| Availability | None (N) | Not tested; no denial-of-service observed. |

**Base Score: 9.1 (Critical)** — confirmed on the FIRST calculator.
**Common name:** SQL Injection – Authentication Bypass (CWE-89)

**Contextual justification:** this is the only finding in the report proven by hand rather than inferred from a scanner, so it is rated with full confidence. In our lab the app sits behind an SSH tunnel reachable only from one IP, which lowers the real-world *likelihood* right now. CVSS Base Score does not account for that: it scores the flaw in the product, not our temporary network controls. If this app were exposed to the internet (its normal deployment), the full score applies directly. This is the clearest case in the whole assessment for separating "how bad is the bug" from "how exposed is it today".

**Evidence:** `(CWE-89).png`

---

## F2 – Session token has no HttpOnly / Secure / SameSite protection

**What it is:** the login token (JWT) is stored as a cookie with none of the three protective flags set, and also duplicated in Local Storage, readable by any script running on the page.

**CVSS v3.1 vector:** `AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:N`

| Metric | Value | Why |
|---|---|---|
| Attack Vector | Network (N) | Cookie/token can be read over the network or by a script. |
| Attack Complexity | High (H) | Needs either network interception or a working XSS, not a direct attack on its own. |
| Privileges Required | None (N) | — |
| User Interaction | None (N) | No victim click needed to steal a token in transit. |
| Scope | Unchanged (U) | — |
| Confidentiality | High (H) | Full session takeover. |
| Integrity | High (H) | Attacker can act as the user. |
| Availability | None (N) | — |

**Base Score: 7.4 (High)** — confirmed on the FIRST calculator.
**Common name:** Insecure Session Token Storage (CWE-614: Sensitive Cookie Without 'HttpOnly' Flag; CWE-311: Missing Encryption of Sensitive Data)

**Contextual justification:** this weakness is a precondition, not a standalone exploit: i did not demonstrate a working theft, only the missing protections (empty HttpOnly/Secure/SameSite columns). It becomes serious together with the next finding (plain HTTP) or with any future XSS. Scored High rather than Critical because real-world exploitation needs one extra step (network position or a script injection point).

**Evidence:** `(CWE-614  CWE-311).png`

---

## F3 – No TLS: login and session travel over plain HTTP

**What it is:** the login request (`POST http://127.0.0.1:3000/rest/user/login`) and the session cookie both travel unencrypted. There is no HTTPS anywhere on the app.

**CVSS v3.1 vector:** `AV:A/AC:H/PR:N/UI:N/S:U/C:H/I:L/A:N`

| Metric | Value | Why |
|---|---|---|
| Attack Vector | Adjacent (A) | Realistically needs a position on the same network path to intercept traffic. |
| Attack Complexity | High (H) | Needs an active interception setup, not a simple remote request. |
| Privileges Required | None (N) | — |
| User Interaction | None (N) | — |
| Confidentiality | High (H) | Credentials and session token exposed in plaintext. |
| Integrity | Low (L) | Limited direct tampering demonstrated. |
| Availability | None (N) | — |

**Base Score: 5.9 (Medium)** — confirmed on the FIRST calculator.
**Common name:** Missing Transport Layer Encryption / Cleartext Transmission (CWE-319)

**Contextual justification:** in our lab this traffic never leaves the VM (it goes through the SSH tunnel, which is encrypted separately), so there is no real interception path right now. In the app's normal deployment, with no tunnel, this would expose every login directly.

**Evidence:** `(CWE-319).png`

---

## F4 – Unauthenticated disclosure of internal configuration

**What it is:** `/rest/admin/application-configuration` can be read with no login, and it leaks internal private IP addresses.

**CVSS v3.1 vector:** `AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N`

| Metric | Value | Why |
|---|---|---|
| Attack Vector | Network (N) | Any browser request reaches it. |
| Attack Complexity | Low (L) | Simple direct request. |
| Privileges Required | None (N) | No login needed. |
| Confidentiality | Low (L) | Internal IPs and config details, not user data. |
| Integrity / Availability | None (N) | Read-only endpoint. |

**Base Score: 5.3 (Medium)** — confirmed on the FIRST calculator.
**Common name:** Unauthenticated Information Disclosure (CWE-200)

**Contextual justification:** on its own this leaks only internal network details, not user data, so it's scored lower than F1–F3. Its real value is as a stepping stone: the leaked internal IPs could help an attacker who already has another way into the network.

**Evidence:** `(CWE-200).png`

---

## F5 – Container hardening gaps (no capability drop, writable filesystem, no memory limit)

**What it is:** from Docker Bench and `docker inspect`: default Linux capabilities kept (5.4), root filesystem writable (5.13 WARN), no memory limit (5.11 WARN), no-new-privileges not set (5.26 WARN).

**CVSS v3.1 vector:** `AV:L/AC:H/PR:L/UI:N/S:U/C:L/I:L/A:L`

| Metric | Value | Why |
|---|---|---|
| Attack Vector | Local (L) | Only matters once an attacker already has code running inside the container. |
| Attack Complexity | High (H) | Needs a prior compromise first, then a separate container-escape or resource-abuse technique. |
| Privileges Required | Low (L) | Container's own low-privilege user (65532) is enough to attempt abuse. |
| Confidentiality/Integrity/Availability | Low (L) each | Limited extra damage beyond what app-level compromise already allows. |

**Base Score: 4.5 (Medium)** — confirmed on the FIRST calculator.
**Common name:** Insecure Container Configuration (maps to CIS Docker Benchmark 5.4, 5.11, 5.13, 5.26)

**Contextual justification:** these are defence-in-depth gaps, not an exploitable vulnerability by themselves. They matter only *after* one of F1–F4 is exploited, where they would let an attacker do more damage (fill disk, escalate inside the container) than a hardened container would allow. 

**Evidence:** `(CIS Docker gaps).png`

---

## F6 – Known vulnerabilities in Node.js dependencies (supply chain)

**What it is:** Trivy found 65 HIGH/CRITICAL vulnerabilities in the image, 62 of them in the app's own Node.js packages (10 CRITICAL). Example: `@fastify/busboy` CVE-2026-19481 (Denial of Service via crafted form-data headers), fixed in version 3.2.1 but running 2.1.1.

**Common name:** @fastify/busboy Denial of Service — **CVE-2026-19481**

**CVSS v3.1 vector (from NVD, CNA: openjs):** `AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H`

**Base Score: 7.5 (High)** — taken directly from the NVD page for CVE-2026-19481 


**Contextual justification:** Trivy's count (175 total, 65 HIGH/CRITICAL) overstates real risk because many flagged packages are never reached by code the app actually runs. Rather than score the whole list, we score one concrete, representative example and explain that the rest were triaged by severity and "fixed version available" rather than individually scored.

**Evidence:** `(CVE-2026-19481).png`

---

## Summary table

| Rank | Finding | Common name | Vector | Base Score | Severity |
|---|---|---|---|---|---|
| 1 | F1 – SQL injection auth bypass | SQL Injection – Authentication Bypass (CWE-89) | AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N | 9.1 | Critical |
| 3 | F6 – CVE-2026-19481 (@fastify/busboy) | @fastify/busboy Denial of Service | AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H | 7.5 | High |
| 2 | F2 – Insecure session token | Insecure Session Token Storage (CWE-614/CWE-311) | AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:N | 7.4 | High |
| 4 | F3 – No TLS (plain HTTP) | Missing Transport Layer Encryption (CWE-319) | AV:A/AC:H/PR:N/UI:N/S:U/C:H/I:L/A:N | 5.9 | Medium |
| 5 | F4 – Unauthenticated config disclosure | Unauthenticated Information Disclosure (CWE-200) | AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N | 5.3 | Medium |
| 6 | F5 – Container hardening gaps | Insecure Container Configuration | AV:L/AC:H/PR:L/UI:N/S:U/C:L/I:L/A:L | 4.5 | Medium |

