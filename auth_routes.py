import secrets
import time

from flask import Blueprint, jsonify, request
from werkzeug.security import check_password_hash, generate_password_hash

from database import get_connection

auth_bp = Blueprint("auth", __name__, url_prefix="/auth")


def _user_row_to_dict(row):
    return {
        "id": row[0],
        "full_name": row[1],
        "email": row[2],
        "phone": row[3] or "",
        "location": row[4] or "",
        "created_at": row[5],
    }


def _fetch_user_by_id(user_id):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT id, full_name, email, phone, location, created_at
            FROM users WHERE id = %s
            """,
            (user_id,),
        )
        row = cursor.fetchone()
        cursor.close()
    if row is None:
        return None
    return _user_row_to_dict(row)


def _fetch_user_by_email(email):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT id, full_name, email, phone, location, created_at
            FROM users WHERE email = %s
            """,
            (email.lower().strip(),),
        )
        row = cursor.fetchone()
        cursor.close()
    if row is None:
        return None
    return _user_row_to_dict(row)


def _create_token(user_id):
    token = secrets.token_urlsafe(32)
    now = int(time.time() * 1000)
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            INSERT INTO auth_tokens (token, user_id, created_at, expires_at)
            VALUES (%s, %s, %s, NULL)
            """,
            (token, user_id, now),
        )
        cursor.close()
    return token


def _delete_token(token):
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM auth_tokens WHERE token = %s", (token,))
        cursor.close()


def _user_id_from_token(token):
    if not token:
        return None
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT user_id FROM auth_tokens WHERE token = %s
            """,
            (token,),
        )
        row = cursor.fetchone()
        cursor.close()
    if row is None:
        return None
    return row[0]


def _auth_user():
    auth_header = request.headers.get("Authorization", "")
    token = None
    if auth_header.startswith("Bearer "):
        token = auth_header[7:].strip()
    user_id = _user_id_from_token(token)
    if user_id is None:
        return None, token
    user = _fetch_user_by_id(user_id)
    if user is None:
        if token:
            _delete_token(token)
        return None, token
    return user, token


def _require_auth():
    user, token = _auth_user()
    if user is None:
        return None, (jsonify({"error": "Unauthorized."}), 401)
    return user, None


@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}
    full_name = (data.get("full_name") or "").strip()
    email = (data.get("email") or "").lower().strip()
    password = data.get("password") or ""

    if not full_name or not email or not password:
        return jsonify({"error": "Full name, email, and password are required."}), 400

    if _fetch_user_by_email(email):
        return jsonify({"error": "An account with this email already exists."}), 409

    password_hash = generate_password_hash(password)
    created_at = int(time.time() * 1000)

    try:
        with get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO users (full_name, email, password_hash, phone, location, created_at)
                VALUES (%s, %s, %s, '', '', %s)
                """,
                (full_name, email, password_hash, created_at),
            )
            user_id = cursor.lastrowid
            cursor.close()
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    user = _fetch_user_by_id(user_id)
    token = _create_token(user_id)
    return jsonify({"token": token, "user": user}), 201


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").lower().strip()
    password = data.get("password") or ""

    if not email or not password:
        return jsonify({"error": "Email and password are required."}), 400

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT id, full_name, email, phone, location, created_at, password_hash
            FROM users WHERE email = %s
            """,
            (email,),
        )
        row = cursor.fetchone()
        cursor.close()

    if row is None:
        return jsonify({"error": "No account found with this email."}), 401

    stored_hash = row[6]
    if not check_password_hash(stored_hash, password):
        return jsonify({"error": "Incorrect password."}), 401

    user = _user_row_to_dict(row[:6])
    token = _create_token(user["id"])
    return jsonify({"token": token, "user": user})


@auth_bp.route("/logout", methods=["POST"])
def logout():
    _, token = _auth_user()
    if token:
        _delete_token(token)
    return jsonify({"message": "Logged out."})


@auth_bp.route("/me", methods=["GET"])
def me():
    user, error = _require_auth()
    if error:
        return error
    return jsonify({"user": user})


@auth_bp.route("/profile", methods=["PUT"])
def update_profile():
    user, error = _require_auth()
    if error:
        return error

    data = request.get_json(silent=True) or {}
    full_name = (data.get("full_name") or "").strip()
    email = (data.get("email") or "").lower().strip()
    phone = (data.get("phone") or "").strip()
    location = (data.get("location") or "").strip()

    if not full_name or not email:
        return jsonify({"error": "Full name and email are required."}), 400

    if email != user["email"]:
        existing = _fetch_user_by_email(email)
        if existing and existing["id"] != user["id"]:
            return jsonify({"error": "This email is already used by another account."}), 409

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            UPDATE users
            SET full_name = %s, email = %s, phone = %s, location = %s
            WHERE id = %s
            """,
            (full_name, email, phone, location, user["id"]),
        )
        cursor.close()

    updated = _fetch_user_by_id(user["id"])
    return jsonify({"user": updated})


@auth_bp.route("/password", methods=["PUT"])
def change_password():
    user, error = _require_auth()
    if error:
        return error

    data = request.get_json(silent=True) or {}
    current_password = data.get("current_password") or ""
    new_password = data.get("new_password") or ""

    if not current_password or not new_password:
        return jsonify({"error": "Current and new password are required."}), 400

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT password_hash FROM users WHERE id = %s",
            (user["id"],),
        )
        row = cursor.fetchone()
        cursor.close()

    if row is None or not check_password_hash(row[0], current_password):
        return jsonify({"error": "Current password is incorrect."}), 401

    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE users SET password_hash = %s WHERE id = %s",
            (generate_password_hash(new_password), user["id"]),
        )
        cursor.close()

    return jsonify({"message": "Password updated."})
