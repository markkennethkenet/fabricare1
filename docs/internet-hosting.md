# Internet API connection

The phone needs a public HTTPS Python API and that API needs a reachable MySQL
database. A USB reverse connection or a PC LAN address only supports local use.

The Flutter app now accepts a complete API URL at build time:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://YOUR-API-DOMAIN
```

Replace the placeholder with the verified hosted API domain. The URL takes
precedence over API_HOST and the local USB development setting. Install the
rebuilt APK on each phone. Database passwords belong in the server environment,
never in Flutter build arguments or the repository.

Hosting is not deployed or verified yet. The repository now includes a
Python 3.12 Dockerfile, requirements-hosting.txt, and railway.json. The Docker
build context includes only API source, configuration, and model files; local
.env files and development environments are excluded. The image build still
needs verification on Railway; Docker is not installed on this PC.

serve_api.py initializes the existing account schema and serves the API with
Waitress on Railway's PORT. Startup stops if MySQL initialization fails.
GET /health/ready returns 200 only when MySQL is reachable, and 503 otherwise.
Railway uses this route as its deployment health check.

Preserve Python 3.12 and scikit-learn 1.6.1 for the saved classifier. The existing
requirements-api.lock.txt was resolved on Windows and is not a verified Linux
deployment lock. requirements-hosting.txt uses the existing requirements.txt
plus Waitress. Linux dependency resolution and memory use still need a real
container build and runtime check.

Deploy the MySQL service and API in the same Railway project. Configure the
API's MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, and MYSQL_DATABASE
using references to that database's variables; keep MySQL on private networking.
Generate an HTTPS domain for the API once its health check passes.

For the browser app, restart Flutter with the hosted address (hot reload does
not change build-time definitions):

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://YOUR-API-DOMAIN
```

On October 24, 2026 the browser app was listening on localhost:50552, but no
API was listening on 5000. Railway connector reads returned "Unknown tool" and
the browser dashboard required sign-in, so no cloud deployment was performed.

Before distributing the APK, verify HTTPS, database readiness, new registration,
login, authenticated profile access, and garment analysis on a phone using
mobile data. Local unit tests do not establish hosted readiness.

## Diagnostics on October 22, 2026

The local API was not reachable on port 5000. ADB listed no connected devices.
The local .env selected MySQL port 3307, which was unreachable. MySQL80 was
running on 3306, but rejected the existing credentials with code 1045. No
credentials, existing database records, or schema were changed.

## References

- https://docs.railway.com/guides/flask
- https://docs.railway.com/databases/mysql
