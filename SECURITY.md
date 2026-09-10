# Security

## This repository is intentionally vulnerable

Every component in this lab is deliberately outdated or misconfigured:

- Plugins and themes ship with known exploits (e.g. CVE-2020-25213,
  CVE-2020-8772, CVE-2020-10564, CVE-2019-9978, CVE-2020-11738,
  CVE-2015-3173, CVE-2020-36708).
- Default credentials are weak on purpose (`admin/admin`, DB `root/password`).
- Standing up this stack creates an unauthenticated-RCE reachable box.

## Scope of use

- **Do NOT deploy this anywhere. It is not production software.**
- **Do NOT expose it to the internet.**
- Use it only on an isolated host/network, for authorized security training,
  CTFs, and penetration-testing practice on targets you own or have
  permission to test.

## No security bugs to report

Please do not open security advisories or "vulnerability reports" against this
repository - the vulnerabilities are the point. All CVEs listed are public and
intentional.

Report actual bugs in the *lab tooling* (scripts, Docker setup - not the
bundled vulnerable software) via a normal GitHub issue.