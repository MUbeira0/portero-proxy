#!/usr/bin/env bash
# Instalador de Portero (proxy inverso con panel web).
#
#   curl -fsSL https://raw.githubusercontent.com/MUbeira0/portero-proxy/main/install.sh | sudo bash
#
# Opciones (se pasan con `bash -s -- <opción>` si lo ejecutas por tubería):
#   --version X.Y.Z    instala esa versión en vez de la última
#   --update           actualiza el binario conservando la configuración
#   --uninstall        elimina el servicio y el binario (conserva /etc/portero)
#   --purge            con --uninstall: borra también la configuración y los certificados
#   --from-file RUTA   usa un binario o .tar.gz que ya tienes (sin descargar; para equipos sin internet)
#   --no-start         instala pero no arranca el servicio
#   --yes              no pregunta nada
#   --skip-signature   no exige la firma de SHA256SUMS (NO recomendado)
#
# Qué hace: descarga la versión publicada, comprueba su SHA256 (y su procedencia con `gh attestation verify`
# si tienes GitHub CLI), crea el usuario sin privilegios «portero», instala el binario en /usr/local/bin,
# crea un servicio systemd endurecido y arranca el asistente de configuración.
set -euo pipefail

REPO="${PORTERO_REPO:-MUbeira0/portero-proxy}"
BIN=/usr/local/bin/portero
CONF_DIR=/etc/portero
UNIT=/etc/systemd/system/portero.service
UPD_PATH=/etc/systemd/system/portero-update.path
UPD_UNIT=/etc/systemd/system/portero-update.service
# Clave pública con la que se firman las versiones oficiales (Ed25519)
RELEASE_PUB='-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAcCftl8zGs6fXlOV1oF90qUgYz6teP0OChssJe/pN2y4=
-----END PUBLIC KEY-----'
SVC_USER=portero

VERSION=""; ACTION=install; PURGE=0; FROM_FILE=""; START=1; YES=0; SKIP_SIG=0
while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="${2:-}"; shift 2 ;;
    --update) ACTION=update; shift ;;
    --uninstall) ACTION=uninstall; shift ;;
    --purge) PURGE=1; shift ;;
    --from-file) FROM_FILE="${2:-}"; shift 2 ;;
    --no-start) START=0; shift ;;
    --yes|-y) YES=1; shift ;;
    --skip-signature) SKIP_SIG=1; shift ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Opción desconocida: $1 (usa --help)" >&2; exit 2 ;;
  esac
done

if [ -t 1 ]; then B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; N=$'\e[0m'; else B=""; G=""; Y=""; R=""; N=""; fi
say()  { printf '%s\n' "${B}==>${N} $*"; }
ok()   { printf '%s\n' "${G}✓${N} $*"; }
warn() { printf '%s\n' "${Y}!${N} $*" >&2; }
die()  { printf '%s\n' "${R}✗ $*${N}" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Ejecuta este instalador como root (con sudo)."
[ "$(uname -s)" = "Linux" ] || die "Este instalador es solo para Linux."
command -v systemctl >/dev/null 2>&1 || die "Hace falta systemd. En Docker usa la imagen: docker compose up -d"

need() { command -v "$1" >/dev/null 2>&1 || die "Falta «$1». Instálalo (apt install $1) y vuelve a ejecutar."; }

stop_service() { systemctl stop portero >/dev/null 2>&1 || true; }

if [ "$ACTION" = uninstall ]; then
  say "Desinstalando Portero"
  systemctl disable --now portero-update.path >/dev/null 2>&1 || true
  systemctl disable --now portero >/dev/null 2>&1 || true
  rm -f "$UNIT" "$UPD_PATH" "$UPD_UNIT" "$BIN" "$BIN.prev"
  systemctl daemon-reload
  if [ "$PURGE" -eq 1 ]; then
    if [ "$YES" -ne 1 ] && [ -t 0 ]; then
      read -r -p "Se borrará $CONF_DIR (configuración, certificados y clave de cifrado). ¿Seguro? [s/N] " a
      [ "$a" = s ] || [ "$a" = S ] || die "Cancelado; no se ha borrado la configuración."
    fi
    rm -rf "$CONF_DIR"
    userdel "$SVC_USER" >/dev/null 2>&1 || true
    ok "Todo eliminado."
  else
    ok "Servicio y binario eliminados. La configuración sigue en $CONF_DIR (usa --purge para borrarla)."
  fi
  exit 0
fi

# --- arquitectura
case "$(uname -m)" in
  x86_64|amd64) ARCH=x86_64 ;;
  aarch64|arm64) ARCH=aarch64 ;;
  *) die "Arquitectura no soportada: $(uname -m) (hay versiones para x86_64 y aarch64)." ;;
esac

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
NEW_BIN=""

if [ -n "$FROM_FILE" ]; then
  [ -f "$FROM_FILE" ] || die "No existe $FROM_FILE"
  say "Usando $FROM_FILE"
  case "$FROM_FILE" in
    *.tar.gz|*.tgz) need tar; tar -xzf "$FROM_FILE" -C "$TMP"; NEW_BIN="$(find "$TMP" -type f -name portero | head -n1)" ;;
    *) NEW_BIN="$FROM_FILE" ;;
  esac
  [ -n "$NEW_BIN" ] || die "No encuentro el binario «portero» dentro del archivo."
else
  if command -v curl >/dev/null 2>&1; then dl() { curl -fsSL --retry 3 -o "$2" "$1"; }; dlq() { curl -fsSL "$1"; }
  elif command -v wget >/dev/null 2>&1; then dl() { wget -q -O "$2" "$1"; }; dlq() { wget -q -O - "$1"; }
  else die "Hace falta curl o wget."; fi
  need tar; need sha256sum
  if [ -z "$VERSION" ]; then
    say "Buscando la última versión"
    VERSION="$(dlq "https://api.github.com/repos/$REPO/releases/latest" | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -n1)" || true
    [ -n "$VERSION" ] || die "No pude saber cuál es la última versión. Indica una con --version X.Y.Z o mira https://github.com/$REPO/releases"
  fi
  VERSION="${VERSION#v}"
  FILE="portero-${VERSION}-linux-${ARCH}.tar.gz"
  BASE="https://github.com/$REPO/releases/download/v${VERSION}"
  say "Descargando Portero $VERSION ($ARCH)"
  dl "$BASE/$FILE" "$TMP/$FILE" || die "No se pudo descargar $BASE/$FILE"
  dl "$BASE/SHA256SUMS" "$TMP/SHA256SUMS" || die "No se pudo descargar SHA256SUMS"
  if [ "$SKIP_SIG" -eq 1 ]; then
    warn "Firma de SHA256SUMS omitida por --skip-signature."
  else
    dl "$BASE/SHA256SUMS.sig" "$TMP/SHA256SUMS.sig" || die "Esta versión no tiene firma (SHA256SUMS.sig). No se instala; usa --skip-signature solo si sabes lo que haces."
    if ! command -v openssl >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
      DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openssl >/dev/null 2>&1 || true
    fi
    command -v openssl >/dev/null 2>&1 || die "Hace falta openssl para comprobar la firma (apt install openssl)."
    printf '%s\n' "$RELEASE_PUB" > "$TMP/release.pub"
    if openssl pkeyutl -verify -pubin -inkey "$TMP/release.pub" -rawin -in "$TMP/SHA256SUMS" -sigfile "$TMP/SHA256SUMS.sig" >/dev/null 2>&1 \
      || openssl pkeyutl -verify -pubin -inkey "$TMP/release.pub" -in "$TMP/SHA256SUMS" -sigfile "$TMP/SHA256SUMS.sig" >/dev/null 2>&1; then
      ok "Firma de MilServices correcta"
    else
      die "La FIRMA de SHA256SUMS no es válida: este paquete no es una versión oficial. No se instala."
    fi
  fi
  EXPECT="$(grep " $FILE\$" "$TMP/SHA256SUMS" | awk '{print $1}')"
  [ -n "$EXPECT" ] || die "$FILE no aparece en SHA256SUMS"
  GOT="$(sha256sum "$TMP/$FILE" | awk '{print $1}')"
  [ "$EXPECT" = "$GOT" ] || die "La suma SHA256 NO coincide (esperada $EXPECT, obtenida $GOT). No se instala."
  ok "SHA256 correcto: $GOT"
  if command -v gh >/dev/null 2>&1; then
    if gh attestation verify "$TMP/$FILE" --repo "$REPO" >/dev/null 2>&1; then ok "Procedencia verificada (compilado por GitHub Actions en $REPO)"
    else warn "No se pudo verificar la procedencia con gh (¿sin sesión de gh?). El SHA256 sí es correcto."; fi
  else
    warn "Para verificar también la procedencia: gh attestation verify $FILE --repo $REPO"
  fi
  tar -xzf "$TMP/$FILE" -C "$TMP"
  NEW_BIN="$(find "$TMP" -type f -name portero | head -n1)"
  [ -n "$NEW_BIN" ] || die "El paquete no contiene el binario."
fi

chmod 755 "$NEW_BIN"
"$NEW_BIN" version >/dev/null 2>&1 || die "El binario no se puede ejecutar en este sistema."
NEWV="$("$NEW_BIN" version | awk '{print $2}')"

# --- instalación
UPDATING=0; [ -x "$BIN" ] && UPDATING=1
if [ "$ACTION" = update ] && [ "$UPDATING" -eq 0 ]; then die "Portero no está instalado; ejecuta el instalador sin --update."; fi

if [ "$UPDATING" -eq 1 ]; then
  say "Actualizando $("$BIN" version 2>/dev/null | awk '{print $2}') → $NEWV"
  [ -f "$CONF_DIR/portero.json" ] && cp -p "$CONF_DIR/portero.json" "$CONF_DIR/portero.json.antes-de-$NEWV" 2>/dev/null || true
  # de estas copias del instalador solo se conservan las 5 más recientes (cada actualización dejaba una más)
  ls -1t "$CONF_DIR"/portero.json.antes-de-* 2>/dev/null | tail -n +6 | while read -r old; do rm -f -- "$old"; done
  stop_service
else
  say "Instalando Portero $NEWV"
fi

install -m 755 "$NEW_BIN" "$BIN"

if ! id "$SVC_USER" >/dev/null 2>&1; then
  useradd --system --home-dir "$CONF_DIR" --shell /usr/sbin/nologin "$SVC_USER" 2>/dev/null || useradd -r -d "$CONF_DIR" -s /bin/false "$SVC_USER"
fi
install -d -m 700 -o "$SVC_USER" -g "$SVC_USER" "$CONF_DIR"
chown -R "$SVC_USER:$SVC_USER" "$CONF_DIR"

cat > "$UNIT" <<'EOF'
[Unit]
Description=Portero (proxy inverso con panel web)
Documentation=https://github.com/MUbeira0/portero-proxy
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=portero
Group=portero
ExecStart=/usr/local/bin/portero run -c /etc/portero/portero.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=2
LimitNOFILE=65535
# Puertos bajos (80/443) sin ser root
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
# Endurecimiento
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=/etc/portero
ProtectHome=true
PrivateTmp=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
ProtectClock=true
ProtectHostname=true
RestrictSUIDSGID=true
RestrictRealtime=true
RestrictNamespaces=true
LockPersonality=true
MemoryDenyWriteExecute=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallArchitectures=native
UMask=0077

[Install]
WantedBy=multi-user.target
EOF
chmod 644 "$UNIT"

# Servicio que aplica las actualizaciones que el panel deja preparadas (verifica de nuevo la firma, instala y reinicia)
cat > "$UPD_UNIT" <<'EOF'
[Unit]
Description=Portero · aplicar actualización preparada desde el panel

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/portero apply-update -c /etc/portero/portero.json
ProtectSystem=strict
ReadWritePaths=/usr/local/bin /etc/portero
ProtectHome=true
PrivateTmp=true
EOF
cat > "$UPD_PATH" <<'EOF'
[Unit]
Description=Portero · vigilar actualizaciones preparadas

[Path]
PathExists=/etc/portero/update/ready
Unit=portero-update.service

[Install]
WantedBy=multi-user.target
EOF
chmod 644 "$UPD_UNIT" "$UPD_PATH"
systemctl daemon-reload
systemctl enable portero >/dev/null 2>&1
systemctl enable --now portero-update.path >/dev/null 2>&1 || warn "No se pudo activar portero-update.path (las actualizaciones desde el panel no estarán disponibles)."

if [ "$START" -eq 0 ]; then ok "Instalado. Arranca con: systemctl start portero"; exit 0; fi
systemctl restart portero

# --- resultado
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"; IP="${IP:-IP-del-servidor}"
for _ in $(seq 1 40); do
  if systemctl is-active --quiet portero && { [ -f "$CONF_DIR/setup-token" ] || [ -f "$CONF_DIR/portero.json" ]; }; then break; fi
  sleep 0.25
done
systemctl is-active --quiet portero || { journalctl -u portero -n 20 --no-pager >&2 || true; die "El servicio no arrancó; mira: journalctl -u portero"; }

echo
if [ -f "$CONF_DIR/setup-token" ]; then
  TOKEN="$(cat "$CONF_DIR/setup-token")"
  ok "Portero $NEWV instalado."
  echo
  echo "  ${B}Termina la configuración en tu navegador:${N}"
  echo "     ${B}http://$IP:8404/${N}"
  echo "     Código de instalación: ${B}$TOKEN${N}"
  echo
  echo "  (el código es de un solo uso y solo vale hasta que completes el asistente)"
else
  ok "Portero $NEWV listo. Panel: http://$IP:8404/  (la configuración existente se ha conservado)"
fi
echo
echo "  Estado:      systemctl status portero"
echo "  Registro:    journalctl -u portero -f"
echo "  Actualizar:  curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | sudo bash -s -- --update"
