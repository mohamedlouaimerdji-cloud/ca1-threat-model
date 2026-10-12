# 00 – Target, authorisation and scope

## Target

OWASP Juice Shop (`bkimminich/juice-shop`), an intentionally vulnerable web application, run in Docker on a VM in the student Azure subscription (`vm-juiceshop`, resource group `rg-ca1-juiceshop`). The target was installed, configured and is solely operated by the student for this assignment; no CCT system or third-party service was used or tested.

## Authorisation evidence

Authorisation was confirmed by the module lecturer, Dr Matt Lemon, by email on **Mon 5 Oct 2026**, in reply to a question about whether a cloud platform was required for the "cloud-hosted" requirement in the brief. The relevant parts of that email:

> "Docker on your own laptop is fine. You do not need a cloud platform, and you should not pay for one or chase the Azure for Students code on my account."
>
> "Treat this email as your authorisation. You installed the target yourself, on hardware you own, and you are the only user of it, so you are the owner granting permission. Say exactly that in your authorisation statement, and note that the assessment was carried out on a local Docker instance of OWASP Juice Shop on your own machine, not against any CCT system or third-party service."
>
> "Do not expose the container to the internet or to the college network. Bind it to localhost only. A deliberately vulnerable application reachable from outside your machine is a genuine risk to you, not a theoretical one."
>
> "Running locally does reduce one dimension of the threat model — you will not have real cloud platform configuration to appraise, such as IAM, storage permissions or network security groups. Do not ignore that. Either model the deployment as it would be if hosted, and say you are doing so, or state the scope limitation explicitly and explain what you would have examined with a cloud deployment."

A screenshot of this email is kept in `evidence/screenshots/email_authorisation_evidence.png` as a record.

## Access controls kept during testing

Per Dr Lemon's instruction, the container was never exposed to the internet or the college network:

- The Juice Shop container is bound to the VM's loopback interface only (`127.0.0.1:3000`), not to its public interface.
- Access for testing was only possible through an SSH tunnel, authenticated with a private key, from the student's own machine.
- The Azure Network Security Group's only inbound rule permits SSH (TCP/22) from one specific IP address at a time (the student's own, updated whenever it changed); all other inbound traffic is denied by the default rule.

These controls are evidenced in `docs/03-existing-controls.md` 

## Summary of scope

| In scope | Out of scope |
|---|---|
| OWASP Juice Shop application (self-deployed) | Any CCT system or network |
| Docker container configuration | Any third-party service or production system |
| Azure VM, NSG, and SSH/IAM configuration | Azure Storage / blob storage (not used in this deployment) |
| Manual testing performed by the student, against their own instance, via the SSH tunnel only | Azure platform-wide CIS Benchmark automated scan (stated as a time-scope limitation in `docs/04-owasp-cis-assessment.md`) |
