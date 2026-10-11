# 01 – System description and trust boundaries

## Target

OWASP Juice Shop, an intentionally vulnerable web application used for security training. Deployed and operated by the author for this assessment, with written authorisation (see `docs/00-authorisation.md`).

## Deployment used

```
REPOSITORY          TAG     DIGEST                                                                   IMAGE ID       CREATED      SIZE
bkimminich/juice-shop latest sha256:73c53fbf442e8337b3ea3d98c7e8550308854701ebdfce4cc39768f36b75430e 73c53fbf442e   7 weeks ago  511MB
```

Run as: `docker run -d --name juice-shop --restart unless-stopped -p 127.0.0.1:3000:3000 bkimminich/juice-shop`

Access is only possible via an SSH tunnel (`ssh -L 3000:127.0.0.1:3000 ...`) to the Azure VM; the container is not reachable from the public internet.

## Components

| Component | Technology | Notes |
|---|---|---|
| Browser/client | Angular SPA | Runs in the tester's own browser, communicates with the app server over HTTP/REST and Socket.IO. |
| App server | Node.js/Express | Serves the API and the compiled Angular app; handles authentication (JWT) and business logic. |
| Data store | SQLite (default) | File-based database bundled inside the container; no separate database service. |
| Container runtime | Docker (Community Engine) | Single container, non-root user (UID 65532), default capabilities, no resource limits (see `docs/03-existing-controls.md`). |
| Cloud/platform layer | Microsoft Azure IaaS VM (`vm-juiceshop`, Standard_B2ats_v2, Ubuntu 24.04, Denmark East region) | **IAM:** SSH key-based login only (`PasswordAuthentication no`), single `azureuser` account, no Azure AD/role-based access layer in front of the VM. **Networking:** one public IP, one Network Security Group (`vm-juiceshop-nsg`) with a single custom inbound rule (`ssh_my_ip`, TCP/22, restricted to the author's current IP) and the default `DenyAllInBound` rule for everything else; outbound traffic is unrestricted. **Storage:** standard OS managed disk only; no separate storage account or blob storage used. **Firewall:** the NSG is the only firewall layer; no Azure Firewall, WAF, or reverse proxy is in front of the VM. |

## Trust boundaries

A trust boundary is drawn wherever data crosses from one zone of trust into another, and each one is where an attacker could try to break through.

| ID | Boundary | Description |
|---|---|---|
| TB1 | Internet/User ↔ Edge | The public internet and the tester's own machine, versus the Azure NSG, which is the only firewall/edge control in front of the VM. No reverse proxy or WAF sits here (see `docs/03-existing-controls.md`). |
| TB2 | Edge ↔ Application container | The VM's network stack, versus the Juice Shop container. Crossed only through the SSH tunnel binding to `127.0.0.1:3000`; the container is not otherwise reachable from the VM's network interface. |
| TB3 | Application ↔ Data store | The Node.js/Express app server, versus the SQLite database file. Both run inside the same container process/filesystem, so this boundary is weak: there is no separate database service, authentication, or network control between them. |
| TB4 | Container ↔ Host/platform control plane | The Juice Shop container, versus the Docker engine and the underlying Ubuntu host it runs on. Crossed if a container escape or privilege escalation occurs (relevant to the CIS Docker Benchmark findings in `docs/04-owasp-cis-assessment.md`, e.g. no capability drop, writable root filesystem). |

These four boundaries match the ones modelled in the Microsoft Threat Modeling Tool diagram (`evidence/diagrams/Threat_Model_triaged.tm7`), referred to there as TB1–TB3 plus the container/host boundary added manually as threat M2.

## Data flow diagram

![Trust boundary diagram](../evidence/diagrams/trust_boundry_diagram.png)

The diagram above is exported from the Microsoft Threat Modeling Tool model used for this assessment (`evidence/diagrams/Threat_Model_triaged.tm7`). It shows:

- **Human User**, **admin** and **Azure Portal** as the external actors, each crossing the **Internet Boundary** (red dashed line, = TB1) to reach the **Azure Firewall** (the NSG). The admin path includes `SSH:22 (key_auth)`, and the Azure Portal path includes firewall management and VM start/stop, both of which are platform-level administrative actions outside the application itself.
- The **Azure Firewall** forwarding traffic on `HTTP:3000` into the **Web Application (Node.js)** inside the **Docker container (Juice Shop)** box — this crossing is TB2.
- The **Web Application** exchanging SQL queries and results with the **SQL Database**, both inside the same container box — this crossing is TB3. The diagram shows them in the same box deliberately: there is no network or authentication boundary between the app and its database, which is itself a finding (see `docs/03-existing-controls.md`).
- The **SSH Service (sshd)**, drawn inside the **Azure VM (Ubuntu)** box but outside the Docker container box, reachable from the Azure Firewall on `SSH:22`. This is the path used for the management tunnel, not a path into the application itself.
