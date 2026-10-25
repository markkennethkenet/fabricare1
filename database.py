import time
from contextlib import contextmanager

import mysql.connector
from mysql.connector import Error as MySqlError

from db_config import DbConfig


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
