# System description and trust boundaries

## Deployment usedREPOSITORY              TAG       DIGEST                                                                    IMAGE ID       CREATED       SIZE
bkimminich/juice-shop   latest    sha256:73c53fbf442e8337b3ea3d98c7e8550308854701ebdfce4cc39768f36b75430e   73c53fbf442e   7 weeks ago   511MB

## Components
| Component | Technology | Notes |
|---|---|---|
| Browser/client | Angular SPA | |
| App server | Node.js/Express | |
| Data store | SQLite (default) | |
| Container runtime | Docker | |
| Cloud/platform layer | (fill in) | IAM, networking, storage, firewall |

## Trust boundaries (diagram required: save in /diagrams, e.g. draw.io or Mermaid)
1. Internet/User  <-> Edge (firewall / reverse proxy)
2. Edge <-> Application container
3. Application <-> Data store
4. Container <-> Host / platform control plane

## Data flow diagram
(embed image from /diagrams)
