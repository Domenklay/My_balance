"""Production launcher. Refuse ephemeral databases on Railway."""
import os
from pathlib import Path
import sys

db = Path(os.environ.get("MYBALANCE_DB", "/data/community.sqlite3"))
if os.environ.get("RAILWAY_ENVIRONMENT_ID"):
    mount = os.environ.get("RAILWAY_VOLUME_MOUNT_PATH", "")
    if not mount or not Path(mount).is_dir() or not db.resolve().is_relative_to(Path(mount).resolve()):
        sys.exit("Attach a persistent Railway volume at /data before starting.")
if not db.parent.is_dir() or not os.access(db.parent, os.W_OK):
    sys.exit("Database directory is missing or not writable.")
os.environ["MYBALANCE_DB"] = str(db)
port = int(os.environ.get("PORT", "8000"))
os.execvp("gunicorn", ["gunicorn", "--bind", f"0.0.0.0:{port}",
    "--workers", "1", "--threads", "4", "--timeout", "30",
    "--access-logfile", "-", "--access-logformat", "%(m)s %(s)s %(L)s",
    "server:application"])
