# Threat model (STRIDE) — cover BOTH app layer and platform layer

Apply STRIDE to each component or data flow / boundary crossing.

| ID | Layer (App/Platform) | Component / flow | STRIDE | Threat | Likelihood | Impact | Existing mitigation |
|---|---|---|---|---|---|---|---|
| T1 | App | Login endpoint | S | Credential stuffing / SQLi auth bypass | | | |
| T2 | App | Basket API | E | IDOR: access another user's basket | | | |
| T3 | Platform | Container | E | Container runs as root; escape risk | | | |
| T4 | Platform | Host port exposure | I | Service reachable beyond intended network | | | |
(add rows; aim for coverage of all six letters)

Method justification: why STRIDE (vs PASTA / attack trees) for this target?
