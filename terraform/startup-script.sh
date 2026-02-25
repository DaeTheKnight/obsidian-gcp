#!/bin/bash

#
# GCP VM Startup Script for Ubuntu 22.04 LTS
# - Installs Xfce + XRDP for GUI/RDP access
# - Installs Docker and docker compose plugin
# - Runs CouchDB in Docker for Obsidian sync
#

set -e

# Create Log folder
mkdir -p log

# Log everything to both a file and syslog
exec > >(tee ./log/startup-script.log | logger -t startup-script) 2>&1

echo "=== Startup script: begin ==="

# Make all apt/dpkg operations non-interactive
export DEBIAN_FRONTEND=noninteractive

# ===========================
#  DETECT / CHOOSE MAIN USER
# ===========================
# If you ever want to force a specific user, set TARGET_USER_OVERRIDE
# e.g. TARGET_USER_OVERRIDE="wally"
TARGET_USER_OVERRIDE=""

if [ -n "$TARGET_USER_OVERRIDE" ]; then
  TARGET_USER="$TARGET_USER_OVERRIDE"
else
  # Auto-pick the first non-system user (uid >= 1000 and < 65534)
  TARGET_USER="$(awk -F: '$3>=1000 && $3<65534 {print $1; exit}' /etc/passwd)"
fi

if [ -z "$TARGET_USER" ]; then
  echo "[FATAL] Could not determine a non-system user (uid >= 1000)."
  exit 1
fi

# Derive home directory for that user
TARGET_HOME="/home/$TARGET_USER"

# Ensure the user exists (safe even if OS Login or the image already created it)
if ! id "$TARGET_USER" &>/dev/null; then
  echo "[INFO] User $TARGET_USER does not exist yet, creating..."
  useradd -m -s /bin/bash "$TARGET_USER"
fi

echo "Using TARGET_USER=$TARGET_USER, TARGET_HOME=$TARGET_HOME"

echo "=== Setting password for $TARGET_USER ==="
# NOTE: change this to something appropriate for your environment
echo "$TARGET_USER:lizzoparty" | chpasswd

# --- 1. System update & upgrade ---

echo "=== Updating system packages ==="
apt-get update
apt-get upgrade -y

# --- 2. Install Xfce desktop + XRDP (and avoid gdm3 interactive prompt) ---

echo "=== Preconfiguring display manager to avoid interactive gdm3 dialog ==="
# Pre-seed debconf answers so the gdm3/lightdm selection won't hang in a headless environment
echo "gdm3 shared/default-x-display-manager select lightdm" | debconf-set-selections
echo "lightdm shared/default-x-display-manager select lightdm" | debconf-set-selections

echo "=== Installing Xfce (Xubuntu desktop) and XRDP ==="
apt-get install -y xubuntu-desktop xrdp

### Fix xfce
echo "=== Configuring XRDP startup script ==="

# Backup original script
mv /etc/xrdp/startwm.sh /etc/xrdp/startwm.sh.bak

# Create new startup script that forces Xfce and unsets DBUS variables
# (This fixes the "Oh no! Something has gone wrong" crash)
cat <<EOF > /etc/xrdp/startwm.sh
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
unset DBUS_SESSION_BUS_ADDRESS
unset XDG_RUNTIME_DIR
startxfce4
EOF

# Make it executable
chmod +x /etc/xrdp/startwm.sh

echo "=== Enabling and restarting xrdp ==="
systemctl enable xrdp
systemctl restart xrdp

echo "=== Configuring Xfce session for $TARGET_USER ==="
mkdir -p "$TARGET_HOME"
echo "startxfce4" > "$TARGET_HOME/.xsession"
chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.xsession"

# --- Install Google Chrome ---
echo "=== Installing Google Chrome (Stable) ==="
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# --- 3. Install Docker and docker compose plugin ---

echo "=== Installing Docker engine and docker compose plugin ==="

# We already did a global apt-get update earlier; this one is mainly to pick up the Docker repo.
# Make it resilient to temporary mirror issues.
echo "=== apt-get update (Docker section) with retries ==="
for i in 1 2 3; do
  if apt-get update; then
    echo "apt-get update succeeded on attempt $i"
    break
  fi
  echo "apt-get update failed on attempt $i, sleeping 10s..."
  sleep 10
  if [ "$i" -eq 3 ]; then
    echo "apt-get update still failing after 3 attempts; continuing with possibly stale indexes"
  fi
done

apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
fi

if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
fi

# Run update again, but don't let it kill the script if the mirror is flaky
if ! apt-get update; then
  echo "[WARN] apt-get update (with Docker repo) failed; trying to install using existing indexes"
fi

apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add main user to docker group (so they can use Docker later)
usermod -aG docker "$TARGET_USER" || true

# Don't fail the whole startup script if these sanity checks ever fail
docker --version || true
docker compose version || true

# --- 4. Create CouchDB project and docker-compose.yml ---

echo "=== Setting up CouchDB docker-compose project ==="
PROJECT_DIR="$TARGET_HOME/obsidian-sync"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

COUCH_USER=$(gcloud secrets versions access latest --secret="obsidian-user")
COUCH_PASS=$(gcloud secrets versions access latest --secret="obsidian-password")

cat > docker-compose.yml << EOF
services:
  couchdb:
    image: couchdb:latest
    container_name: couchdb-for-ols
    user: "5984:5984"
    environment:
      - COUCHDB_USER=${COUCH_USER}        
      - COUCHDB_PASSWORD=${COUCH_PASS}    
    volumes:
      - ./couchdb-data:/opt/couchdb/data
      - ./couchdb-etc:/opt/couchdb/etc/local.d
    ports:
      - "5984:5984"
    restart: unless-stopped
    networks:
      - obsidian-network

volumes:
  couchdb-data:
  couchdb-config:

networks:
  obsidian-network:
    driver: bridge
EOF

# Give ownership of the project to the main user so they can edit files later
chown -R "$TARGET_USER:$TARGET_USER" "$PROJECT_DIR"

# Ensure CouchDB directories exist and give permissions to run docker as uid/gid 5984
mkdir -p ./couchdb-data ./couchdb-etc
chown -R 5984:5984 ./couchdb-data
chown -R 5984:5984 ./couchdb-etc

# --- 5. Launch CouchDB ---

echo "=== Launching CouchDB via docker compose ==="
docker compose -f "$PROJECT_DIR/docker-compose.yml" up -d
docker compose -f "$PROJECT_DIR/docker-compose.yml" ps || true

# --- 6. Done ---

echo "=== Startup script finished successfully ==="
echo "RDP: connect to this VM's external IP on port 3389."
echo "CouchDB: http://<VM-EXTERNAL-IP>:5984/_utils/"