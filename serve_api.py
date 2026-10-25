"""Production API entry point for Railway and other container hosts."""
import logging
import os


def main():
    from database import init_schema
    from fabricare_api import app
    from waitress import serve

    port = int(os.environ.get("PORT", "5000"))
    try:
        init_schema()
    except Exception:
        # Do not expose connection details or credentials in hosted logs.
        logging.error("MySQL initialization failed. Check the server's MYSQL_* variables.")
        raise SystemExit(1) from None

    # A single worker serializes access to the shared inference models.
    serve(app, host="0.0.0.0", port=port, threads=1,
          max_request_body_size=app.config["MAX_CONTENT_LENGTH"])


if __name__ == "__main__":
    main()
