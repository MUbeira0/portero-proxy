#!/usr/bin/env bash
# Crea un contenedor LXC de Debian en Proxmox VE con Portero instalado. Ejecútalo EN EL SERVIDOR PROXMOX (como root):
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/MUbeira0/portero-proxy/main/contrib/proxmox-lxc.sh)"
#
# Variables opcionales: CTID (por defecto el siguiente libre), CT_NAME, CT_STORAGE (donde va el disco),
# CT_TEMPLATE_STORAGE, CT_BRIDGE (vmbr0), CT_DISK (GB, 4), CT_RAM (MB, 512), CT_CORES (1), CT_IP (dhcp o 192.168.1.50/24),
# CT_GW (puerta de enlace si usas IP fija), INSTALL_SH (ruta local de install.sh, para probar), PORTERO_ARGS.
set -euo pipefail

command -v pct >/dev/null 2>&1 || { echo "Esto hay que ejecutarlo en un servidor Proxmox VE (no encuentro «pct»)." >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "Ejecútalo como root." >&2; exit 1; }

CTID="${CTID:-$(pvesh get /cluster/nextid)}"
CT_NAME="${CT_NAME:-portero}"
CT_STORAGE="${CT_STORAGE:-local-lvm}"
CT_TEMPLATE_STORAGE="${CT_TEMPLATE_STORAGE:-local}"
CT_BRIDGE="${CT_BRIDGE:-vmbr0}"
CT_DISK="${CT_DISK:-4}"
CT_RAM="${CT_RAM:-512}"
CT_CORES="${CT_CORES:-1}"
CT_IP="${CT_IP:-dhcp}"
REPO="${PORTERO_REPO:-MUbeira0/portero-proxy}"

if ! pvesm status | awk 'NR>1{print $1}' | grep -qx "$CT_STORAGE"; then
  echo "El almacenamiento «$CT_STORAGE» no existe. Disponibles:" >&2
  pvesm status | awk 'NR>1{print "  " $1}' >&2
  echo "Elige uno con: CT_STORAGE=nombre bash $0" >&2
  exit 1
fi

echo "==> Buscando la plantilla de Debian"
pveam update >/dev/null 2>&1 || true
TEMPLATE="$(pveam available --section system | awk '{print $2}' | grep -E '^debian-1[23]-standard' | sort -V | tail -n1)"
[ -n "$TEMPLATE" ] || { echo "No encuentro una plantilla de Debian 12/13." >&2; exit 1; }
pveam list "$CT_TEMPLATE_STORAGE" | grep -q "$TEMPLATE" || pveam download "$CT_TEMPLATE_STORAGE" "$TEMPLATE"

NET="name=eth0,bridge=${CT_BRIDGE},ip=${CT_IP}"
if [ "$CT_IP" != dhcp ] && [ -n "${CT_GW:-}" ]; then NET="${NET},gw=${CT_GW}"; fi

echo "==> Creando el contenedor $CTID ($CT_NAME)"
pct create "$CTID" "${CT_TEMPLATE_STORAGE}:vztmpl/${TEMPLATE}" \
  --hostname "$CT_NAME" --cores "$CT_CORES" --memory "$CT_RAM" --swap 256 \
  --rootfs "${CT_STORAGE}:${CT_DISK}" --net0 "$NET" \
  --unprivileged 1 --features nesting=1 --onboot 1 --start 1 \
  --description "Portero · proxy inverso con panel web (https://github.com/${REPO})"

echo "==> Esperando a la red del contenedor"
for _ in $(seq 1 60); do
  if pct exec "$CTID" -- sh -c 'getent hosts github.com >/dev/null 2>&1'; then break; fi
  sleep 2
done

echo "==> Instalando Portero"
pct exec "$CTID" -- sh -c 'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl ca-certificates openssl >/dev/null'
if [ -n "${INSTALL_SH:-}" ]; then
  pct push "$CTID" "$INSTALL_SH" /root/install.sh
  # shellcheck disable=SC2086
  pct exec "$CTID" -- bash /root/install.sh ${PORTERO_ARGS:-}
else
  pct exec "$CTID" -- bash -c "curl -fsSL https://raw.githubusercontent.com/${REPO}/main/install.sh | bash -s -- ${PORTERO_ARGS:-}"
fi
