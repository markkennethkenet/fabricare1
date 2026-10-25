# FabriCare on Vercel

Target workspace: `markkennethkenets-projects`.
Repository: `markkennethkenet/fabricare1`.
Current source branch: `capstone/ai-skills-activity`.
No Vercel project or deployment has been created yet.

Vercel workspace access was verified on October 25, 2026. The connected
workspace is on the Hobby plan, with no existing FabriCare project or installed
database integration. The user selected Railway MySQL for persistence.

Railway's existing project `empathetic-hope` contains an offline MySQL service
and a persistent volume. Its dashboard reports "Trial expired" and requires a
plan upgrade to continue. No service, volume, existing data, or billing plan
was changed. Do not create a replacement database or assume an upgrade was
approved; the user must choose and activate the plan they want.

The deployment uses Vercel Services (beta) to ship two components together:

- `web`: Flutter 3.41.4, built from its pinned SDK revision into `web/dist`.
- `api`: the existing Python 3.12 API, built with `Dockerfile.vercel` and
  CPU-only PyTorch. Model versions and model files are preserved.

The browser calls `/api` on its own origin. Public `/api/...` requests route to
the API service, whose rewrite removes `/api` before Flask receives the request.
Other requests serve the Flutter web app. Deep links resolve to `index.html`.

Enable "Include source files outside of the Root Directory in the Build Step"
on the Vercel project: the web service's build needs the parent Flutter source
and build script. The deployment root is the repository root. Do not set the
project root to `web` or change its framework to Flask.

`.vercelignore` and `.dockerignore` allowlist application/build inputs and keep
local credentials, virtual environments, datasets, and build outputs out of the
deployment. Do not publish `.env` or place database passwords in Flutter.

## Database prerequisite

The existing authentication service requires MySQL. A hosted database must be
provisioned before this deployment can become ready. Configure these server
environment variables using the database provider's connection details:

`MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`.

For a Railway database, Vercel requires its external TCP proxy host/port rather
than a `railway.internal` address. Review the provider's encryption and
connection settings before production use. Database setup and provider costs
are not verified or approved by this document.

`serve_api.py` initializes the existing schema and stops startup if MySQL is
unavailable. Existing tables and records are preserved. `/api/health/ready`
returns 200 only when the API can reach MySQL.

## Review and verification

The working tree includes uncommitted authentication, scanning, assessment,
and history changes. Review the exact source snapshot before publishing. Do
not deploy the old remote default branch and assume it includes local changes.

Before this configuration was added, the current Flutter release build with
`API_BASE_URL=/api` succeeded, and all three existing Flutter tests passed.
The previous backend suite passed 25 tests. These checks do not establish
cloud readiness. Docker is not installed locally; the container build and
Vercel service routing still need a real deployment check.

The new vercel.json passed validation against the current official Vercel
schema constraints, and build_web_vercel.sh passed Bash syntax checking.
The official CPU-wheel index lists both pinned PyTorch packages for Python
3.12 on Linux x86_64. Ignore-rule checks verified that environment files,
virtual environments, agent files, Git metadata, and generated output are
excluded while the required source, model, and build inputs remain included.

After deployment, test signup, login, authenticated profile access, logout,
and garment analysis through the actual browser deployment. Verify history
remains scoped to the signed-in account. Do not report login as working until
the real hosted database and these flows have been tested.

Vercel Functions limit request bodies to 4.5 MB. The existing scanner accepts
larger combined photos locally; cloud photo uploads must be kept below this
limit or changed to an upload flow that avoids sending large files through a
Function. Web scanning also uses file-path APIs that need separate browser
verification; successful authentication tests do not establish scanner support.

References:

- https://vercel.com/docs/services
- https://vercel.com/docs/services/config-reference
- https://vercel.com/docs/functions/container-images
- https://docs.railway.com/databases/mysql
