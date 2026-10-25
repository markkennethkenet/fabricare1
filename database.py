import time
import tempfile
from contextlib import contextmanager
from functools import lru_cache

import mysql.connector
from mysql.connector import Error as MySqlError

from db_config import DbConfig


@lru_cache(maxsize=1)
def _ca_file(pem):
    # Aiven's CA is public, but keep deployment configuration out of source.
    with tempfile.NamedTemporaryFile(mode="w", suffix=".pem", delete=False,
                                     encoding="ascii") as certificate:
        certificate.write(pem)
        return certificate.name


def _connect(use_database=True):
    kwargs = {
        "host": DbConfig.host,
        "port": DbConfig.port,
        "user": DbConfig.user,
        "password": DbConfig.password,
        "connection_timeout": 5,
    }
    if use_database:
        kwargs["database"] = DbConfig.database
    ca = _ca_file(DbConfig.ssl_ca_pem) if DbConfig.ssl_ca_pem else DbConfig.ssl_ca
    if ca:
        kwargs.update(ssl_ca=ca, ssl_verify_cert=True, ssl_verify_identity=True,
                      ssl_disabled=False)
    elif DbConfig.host.endswith(".aivencloud.com"):
        raise ValueError("Configure MYSQL_SSL_CA_PEM or MYSQL_SSL_CA for Aiven TLS verification.")
    return mysql.connector.connect(**kwargs)


@contextmanager
def get_connection(use_database=True):
    conn = _connect(use_database=use_database)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def ensure_database_exists():
    with get_connection(use_database=False) as conn:
        cursor = conn.cursor()
        cursor.execute(
            f"CREATE DATABASE IF NOT EXISTS `{DbConfig.database}` "
            "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
        )
        cursor.close()


def init_schema():
    ensure_database_exists()
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                full_name VARCHAR(255) NOT NULL,
                email VARCHAR(255) NOT NULL UNIQUE,
                password_hash VARCHAR(255) NOT NULL,
                phone VARCHAR(50) NOT NULL DEFAULT '',
                location VARCHAR(255) NOT NULL DEFAULT '',
                created_at BIGINT NOT NULL
            ) ENGINE=InnoDB
            """
        )
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS auth_tokens (
                token VARCHAR(64) PRIMARY KEY,
                user_id INT NOT NULL,
                created_at BIGINT NOT NULL,
                expires_at BIGINT NULL,
                CONSTRAINT fk_auth_user
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
                INDEX idx_auth_user_id (user_id)
            ) ENGINE=InnoDB
            """
        )
        cursor.close()


def ping_database():
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT 1")
        cursor.fetchone()
        cursor.close()
    return True


def db_error_message(exc):
    if isinstance(exc, MySqlError):
        return str(exc)
    return str(exc)
