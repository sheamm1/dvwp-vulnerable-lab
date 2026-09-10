# Damn Vulnerable WordPress

Playground for WordPress hacking and [wpscan](https://github.com/wpscanteam/wpscan) testing.

Source: **https://github.com/sheamm1/dvwp-vulnerable-lab** (fork of
[vavkamil/dvwp](https://github.com/vavkamil/dvwp))

**DO NOT EXPOSE THIS TO INTERNET!**
**This stack is intentionally vulnerable. It is for training/CTF purposes only.**

Exploitation playbooks are kept out of this repository on purpose.

## What's inside

| Component  | Version              | Notes                                       |
|------------|----------------------|---------------------------------------------|
| WordPress  | 7.1 (latest)         | `wordpress:7.1-php8.3-apache`               |
| PHP        | 8.3 (latest LTS-ish, official `latest` default) | `display_errors = On` (see `otherz/php.ini`) |
| MySQL      | 8.0                  | health-checked, waits for WP-CLI             |
| phpMyAdmin | 5.1.1 (vulnerable)   | see [phpMyAdmin section](#phpmyadmin)        |
| WP-CLI     | 2.x (`cli-php8.3`)   | runs setup automatically on `up`             |

There is **no Dockerfile anymore** — the base images are used as-is and the
vulnerable files/plugins are attached to the WordPress container via
docker-compose bind-mounts.

## Installation

```
$ git clone https://github.com/sheamm1/dvwp-vulnerable-lab.git
$ cd dvwp-vulnerable-lab/
$ docker-compose up -d             # starts everything, wp-cli installs & activates everything automatically
```

> The vulnerable plugins/themes are **vendored in this repository** (see
> `plugins/` and `themes/`). `bin/download-plugins.sh` is only needed if you
> want to (re)fetch them from wordpress.org at their pinned vulnerable versions.

> First pull of the images can take a while. **Upgrading from an older version
> (the previous Dockerfile-based setup)?** Run `docker-compose down -v` once to
> wipe the old named volumes, otherwise the outdated WordPress core / database
> from the old stack stays mounted and the new image will not be applied.

The `wp-cli` service runs `bin/install-wp.sh` automatically: installs
WordPress, imports the demo data (`editor` user + "Hack Me If You Can" post)
and activates the vulnerable plugins/themes. The container exits when done —
it is safe to re-run the whole stack (`docker-compose up -d` again).

## Usage

```
$ docker-compose up -d       # start
$ docker-compose down        # stop
$ docker-compose logs -f     # logs
```

## Shell

```
$ docker-compose exec wordpress bash
```

## Logs

```
$ bin/pull-logs.sh           # copies access.log + error.log from the WordPress container into ./logs/
```

## Interface

* [http://127.0.0.1:31337](http://127.0.0.1:31337)
* [http://127.0.0.1:31337/wp-login.php](http://127.0.0.1:31337/wp-login.php)
* [http://127.0.0.1:31338/phpmyadmin/](http://127.0.0.1:31338/phpmyadmin/)

## Credentials

* WordPress: `admin` / `admin`
* Editor:     `editor` / `editor`
* MySQL:      `root` / `password`  (DB `wordpress`, user `wordpress` / `wordpress`)
* phpMyAdmin: `root` / `password` (host `mysql`)

## Vulnerabilities

Feel free to contribute with pull requests ;)

All plugins and themes are vendored **at their exact vulnerable version** in
this repository (see `plugins/` and `themes/`), so the lab runs out of the box.
They were fetched from wordpress.org by `bin/download-plugins.sh` (via
`svn co`/`svn export`, with a zip fallback).

### Plugins

#### InfiniteWP Client `1.9.4.4` — Authentication Bypass (CVE-2020-8772)
Pulled in by `plugins/iwp-client`. An attacker can log into the site as an
administrator without a password via the `IWP_ADD_SITE` action (missing access
capability check).
* https://wpscan.com/vulnerability/10011

#### WordPress File Upload `4.12.2` — Directory Traversal to RCE (CVE-2020-10564)
Pulled in by `plugins/wp-file-upload`. A directory traversal in the file
rename feature lets an unauthenticated attacker move an uploaded file to an
arbitrary location, e.g. a `.php` file into the web root -> remote code
execution.
* https://wpscan.com/vulnerability/10132

#### WP Advanced Search `3.3.3` — Unauthenticated DB Access & RCE (no CVE)
Pulled in by `plugins/wp-advanced-search`. The search preview page contains an
unauthenticated blind SQL injection that can be escalated to full database
read/write and code execution.
* https://wpscan.com/vulnerability/10115

#### Social Warfare `3.5.2` — Unauthenticated Arbitrary Settings Update (CVE-2019-9978)
Pulled in by `plugins/social-warfare`. The options update call is accessible
without authentication (`swp_debug=load_options`), allowing an attacker to
modify arbitrary WordPress options and achieve RCE.
* https://wpscan.com/vulnerability/9238

#### Backup and Staging by WP Time Capsule `1.21.15` — Authentication Bypass (CVE-2020-8771)
Pulled in by `plugins/wp-time-capsule`. Bypass of the login cookie check
allows privilege escalation to administrator.
**NOT WORKING RIGHT NOW** — activation causes errors, plugin is installed but
stays disabled.
* https://wpscan.com/vulnerability/10010

#### File Manager `6.0` — Unauthenticated Arbitrary File Upload / RCE (CVE-2020-25213)
Pulled in by `plugins/wp-file-manager`. The bundled elFinder connector lets
unauthenticated attackers upload and execute PHP files. Massively exploited in
the wild in 2020.
* https://wpscan.com/vulnerability/10085

#### File Manager `6.0` — Exposed Backup Files (CVE-2020-24312)
Backups are stored world-readable at
`wp-content/uploads/wp-file-manager-pro/fm_backup/` (full DB dumps +
plugins/themes/uploads archives) with no access restriction, so unauthenticated
visitors can download them. Fixed in 6.5.
* https://wpscan.com/vulnerability/49533dc2-17cb-459c-af28-69a7b9b9512f/

#### Duplicator `1.3.26` — Directory Traversal / Arbitrary File Read (CVE-2020-11738)
Pulled in by `plugins/duplicator`. `../` in the `file` parameter of the
`duplicator_download` / `duplicator_init` actions allows reading arbitrary
files from the server (CISA KEV listed).
* https://wpscan.com/vulnerability/10037

#### Custom Content Type Manager `0.9.8.1` — Authenticated Admin+ RCE (CVE-2015-3173)
Pulled in by `plugins/custom-content-type-manager`. "Visibility Control"/hidden
field code slots are passed through `eval()`, letting an admin run arbitrary PHP
(fixed in 0.9.8.6). The plugin also carries a blind SQLi in `orderby_custom`
(reached via the `wp_ajax_get_posts` handler).

> The `CVE-2014-4659` label sometimes seen for this plugin is a misattribution —
> that ID belongs to Ansible, not this plugin.

### Themes

#### Twenty Twenty-Five `1.5`
Pulled in by `themes/twentytwentyfive`, activated as the default (homepage)
theme. Modern block theme from typofoto, gives the site its polished front end.

#### Shapely `1.2.7` — Unauthenticated Function Injection / RCE (CVE-2020-36708)
Pulled in by `themes/shapely`. The Epsilon framework's
`epsilon_framework_ajax_action` allows unauthenticated attackers to call
arbitrary functions -> remote code execution.

#### Sparkling `2.4.8` — Unauthenticated Function Injection / RCE (CVE-2020-36708)
Pulled in by `themes/sparkling`. Same Epsilon-framework flaw (part of the
15-theme chain fixed by colorlib).

### phpMyAdmin

phpMyAdmin is pinned to the known-vulnerable **5.1.1** image:

* **CVE-2022-0813** — pre-auth route confusion / authentication bypass
* **CVE-2022-23807, CVE-2022-23808** — stored/reflected XSS

### Otherz

Exposed in the web root as intentional misconfigurations:

* Directory listing
* `display_errors` (see `otherz/php.ini`)
* `info.php` — full `phpinfo()`
* `dump.sql` — DB dump with user data
* `adminer.php` — Adminer 4.6.2 database UI
* `search-replace-db` — (Search-Replace-DB v3.1.0) arbitrary DB manipulation
* `cross-domain` — Respond.js cross-domain proxy
* `compat.php` — PHP 8 compatibility shim (`create_function`, `each`) loaded via
  `auto_prepend_file` so the outdated plugins still run on modern PHP

## Publishing the image to Docker Hub

There is no Dockerfile in the repo, but you can build and push a ready-to-use
image (with plugins/themes baked in) with:

```
$ DOCKER_USER=<your-dockerhub-username> bin/publish.sh
```

This logs in, runs `bin/download-plugins.sh`, builds the image inline
(`wordpress:7.1-php8.3-apache` + `otherz/` + `plugins/` + `themes/`) and pushes
`<your-dockerhub-username>/dvwp:latest`.

> PHP 8.3 is used (the official `wordpress:latest` default) so the intentionally
> outdated plugins keep working. On PHP 8.5 several of them hit code that was
> removed in PHP 8 (`each()`, `create_function()`) and fatal.# Vulnerable_Wordpress
