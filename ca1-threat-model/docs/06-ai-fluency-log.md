# AI use log (feeds the AI Fluency declaration appendix)

Keep this honest and up to date as you go. Record: date, tool, what you asked, what you used, how you checked it.

| Date | Tool | Purpose | What I used / changed | How I verified it |
|---|---|---|---|---|
| 7-8 Oct 2026 | Claude | Explain Trivy and Docker Bench for Security before running them | Learned what each flag/output field meant | Ran the tools myself; only used the real output they produced |
| 8 Oct 2026 | Claude |	Generate the scan automation script (scripts/run-scans.sh) to run Trivy and Docker Bench for Security |Used the script as-is to run both scans against my own container | Ran it myself, read every line before running it, and checked the output files it created (evidence/scans/trivy-image.txt, evidence/scans/docker-bench.txt) against the real scan resultsd |
| 9 Oct 2026 | Claude | Draft OWASP Top 10 / CIS Docker Benchmark write-up | Drafted wording for docs/04-owasp-cis-assessment.md |Cross-checked every CIS control ID Claude wrote against my own docker-bench-bash.txt; found and corrected wrong IDs|
| 9-11 Oct 2026 | Claude | Confirm current OWASP Top 10 edition | Used OWASP Top 10:2025 instead of an older edition from memory | Checked top10.owasp.org/2025 myself |
| 11 Oct 2026 | Claude | Draft CVSS vectors for each finding before scoring | Draft vectors for F1-F6 | Scored every finding myself on the real FIRST.org calculator; replaced any vector Claude estimated with the confirmed one |
| 11 Oct 2026 | Claude | Look up CVE-2026-19481 | Took the CVSS score directly from the NVD listing, not an estimate | Opened the NVD page myself and checked the score matched |
| 13 Oct 2026 | Claude | reform report and wording to academic language | rebuiled the full report in academic words (threat model, controls, OWASP/CIS, findings, conclusion) from my evidence and scan output | Read through every section and corrected where wrong |
| 14 Oct 2026 | Claude | add CVSS justifications, draft AI Fluency appendix based on my prompts and references also style it | Fixed missing section headings in the .docx, wrote Appendix B based on the prompts used | Opened the rendered PDF myself and checked every page before submitting |
