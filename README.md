# Portero

Proxy inverso y balanceador de carga **L4/L7** escrito en Rust, pensado como alternativa
sencilla a HAProxy / Nginx Proxy Manager para un homelab: un solo binario, un archivo de
configuración y un **panel web completo** para gestionarlo todo sin tocar el JSON.

By **MilServices** · Licencia: software propietario gratuito (ver LICENSE) · [Seguridad](SECURITY.md) · [Cambios](CHANGELOG.md)

## Qué hace

**Proxy y balanceo**
- Modo **HTTP** (HTTP/1.1 y HTTP/2 con los clientes, WebSocket y cualquier `Upgrade`) y modo **TCP** (cualquier protocolo, con enrutado por SNI sin descifrar TLS).
- Reglas por **dominio, ruta, método, cabecera, cookie, parámetro, IP de origen, TLS/SNI** con `and / or / not` y paréntesis:
  `host(*.casa.lan) and not path_prefix(/admin) or src(192.168.0.0/16)`.
- Acciones: enviar a un backend, **bloquear**, **redirigir**, reescribir ruta (quitar/añadir prefijo), añadir/quitar cabeceras de petición y respuesta, **usuario y contraseña** por regla.
- Algoritmos: `roundrobin` (con pesos), `leastconn`, `source`, `uri`, `random`, `first`; servidores de reserva (`backup`), `max_conn`, **sesión pegajosa** por cookie.
- **Comprobaciones de salud** TCP o HTTP con umbrales `rise`/`fall`; reintentos con otro servidor; modo mantenimiento y **drenaje** en caliente.
- Redirección automática a HTTPS, cabeceras `X-Forwarded-*`, backends por HTTPS.
- **Conexiones keep-alive** hacia los servidores (se reutilizan; si una conexión libre ya no sirve, las peticiones GET/HEAD se reintentan solas).
- **Modo mantenimiento** por sitio (página 503 con el estilo de MilServices) y **límite de peticiones por regla** (por ejemplo solo para `/login`, sin bloquear a nadie).
- **IP real del visitante** detrás de proxies de confianza (Cloudflare Tunnel: `CF-Connecting-IP`; otros: `X-Forwarded-For`).
- **Recarga en caliente** sin cortar conexiones, validación completa, rollback si algo falla y copia de seguridad en cada cambio.

**Certificados automáticos**
- **CA interna** propia: emite certificados (comodines incluidos) para tu red local; instalas la CA una vez y todo se ve seguro.
- **Let's Encrypt** (ACME) con reto **HTTP-01** o **DNS-01** (comodines `*.midominio.com`).
- Proveedores DNS: **Cloudflare, DuckDNS, DigitalOcean, Hetzner, GoDaddy, deSEC, Porkbun**, **webhook** genérico (Route 53, OVH, scripts…) y modo **manual**.
- Renovación automática, varios certificados por entrada (selección por SNI) y subida de PEM propios.

**Seguridad**
- **Límite de peticiones por IP con cubo de fichas**: admite ráfagas (una página con cientos de recursos no es abuso) y solo **bloquea temporalmente** ante abuso sostenido (rechazos en varios periodos distintos, no por unas pocas peticiones seguidas). Límite de conexiones por IP. Pantalla de bloqueo con la imagen de MilServices que se recarga sola.
- **Redes de confianza**: la red local (192.168.x.x, 10.x.x.x, 172.16-31.x.x, 100.64.x.x, localhost) y las IPs que añadas **nunca se limitan ni se bloquean automáticamente**. Un bloqueo manual sí se respeta.
- **Portal de inicio de sesión** para rutas protegidas (sesión por cookie, cierre de sesión, bloqueo tras intentos fallidos); los usuarios se guardan con **hash bcrypt**.
- Panel de administración endurecido: contraseñas con **hash bcrypt** (nunca en claro), **verificación en dos pasos (TOTP)** con QR y códigos de recuperación, sesiones con caducidad e inactividad que se pueden ver y cerrar, **registro de auditoría** (quién hizo qué y desde dónde), lista de **redes permitidas** con protección contra quedarte fuera, panel opcional por **HTTPS**, protección CSRF, cabeceras de seguridad (CSP, X-Frame-Options…) y política de contraseñas.
- **Secretos cifrados en disco** (AES-256-GCM, clave en `secret.key`): tokens DNS, contraseña SMTP, tokens de Telegram/Discord… El navegador nunca los recibe (se muestran enmascarados).
- Avisos de seguridad: IP bloqueada, accesos nuevos al panel, intentos fallidos repetidos, cambios de contraseña y de 2FA.

**Avisos** (correo SMTP —Gmail con contraseña de aplicación, Outlook, OVH u otro—, Telegram, Discord o webhook)
- Servidor caído/recuperado, backend sin servidores, certificados que fallan, se renuevan o están a punto de caducar, eventos de seguridad y, opcionalmente, cada cambio de configuración.
- Sin ruido: el mismo problema no se repite antes del tiempo de espera y se avisa también de la recuperación. Correos con la plantilla de MilServices.

**DDNS**: Portero averigua tu IP pública (en varios servicios a la vez; deben coincidir al menos dos, y se rechazan IPs privadas y de CGNAT) y mantiene al día los registros que indiques en **Cloudflare** (A/AAAA, con o sin proxy), **DuckDNS**, cualquier servicio **DynDNS2** (No-IP, Dynu…) o un **webhook**. Avisa de los cambios de IP y de los fallos, y el diagnóstico lo revisa.

**Sistema** (página «Sistema» del panel)
- **Actualizaciones desde el panel**: avisa de las versiones nuevas y las instala con un botón. Cada versión se verifica con una **firma Ed25519 de MilServices** y su SHA256 antes de instalarse; si la nueva no arranca, se restaura la anterior. (En Docker: `docker compose pull && docker compose up -d`.)
- **Copias automáticas cifradas** (AES-256-GCM con tu frase de paso) de la configuración, claves y certificados: carpeta local con rotación y, si quieres, subida a un **WebDAV** (Nextcloud, NAS…). Se restauran con `portero restore`.
- **Importar sitios** desde **Nginx** (también los archivos de **Nginx Proxy Manager**) y **Caddyfile**: pegas el archivo y Portero crea los sitios.
- **HTTP/3 (QUIC)** opcional por entrada con HTTPS, y **IPv6** (entradas y servidores en `[::1]:80`, redes IPv6 permitidas).
- **Licencia**: Portero es gratuito y lo incluye todo; la edición de pago futura se activará con una clave firmada que se comprueba sin conexión.

**DNS automático**: al publicar un sitio, Portero crea el nombre en tu **AdGuard Home** (reescrituras DNS), en **Cloudflare** (registro A) o por **webhook**, comprueba si el nombre resuelve a esta máquina y puede borrar los registros al quitar el sitio.

**Módulos instalables**
- Scripts [Rhai](https://rhai.rs) en entorno aislado (sin disco ni red, con límites de tiempo y memoria) que modifican peticiones y respuestas.
- Se instalan desde el catálogo integrado, desde una URL, pegando el JSON o desde un catálogo remoto. Incluidos: cabeceras de seguridad, CORS, bloqueo de bots, lista blanca de IPs, modo mantenimiento, ID de petición, redirección www, bloqueo de rutas sospechosas, caché del navegador y cabeceras personalizadas.

**Panel web** (puerto `8404` por defecto): página **Sitios** con asistente (dominio → servidor, HTTPS, certificado, contraseña y registros DNS en un solo paso), **probador de rutas** que explica qué haría Portero con cualquier petición, **vista previa de cambios** antes de aplicarlos, página de **Avisos**, seguridad del panel (2FA, sesiones, auditoría), actividad en vivo (servidores que caen o se recuperan), búsqueda rápida con `Ctrl+K`, lista de primeros pasos, gráficas, editores visuales de entradas, reglas, backends y servidores, gestor de certificados, módulos, bloqueos, registro de accesos con filtros, copias de seguridad, editor JSON avanzado, página de **Diagnóstico** (revisa la configuración y dice qué arreglar), **historial de disponibilidad** de cada servidor (24 h / 7 días y cortes), estadísticas por sitio (latencia p95/p99, rutas y clientes), modo mantenimiento y «solo red local» por sitio, copia completa descargable, acciones rápidas en el registro (bloquear / confiar en una IP, exportar CSV), tema claro/oscuro y diseño adaptable al móvil. También expone `/metrics` (Prometheus) y `/health`.

## Instalación

### En un servidor Linux (Debian, Ubuntu…) — una línea

```bash
curl -fsSL https://raw.githubusercontent.com/MUbeira0/portero-proxy/main/install.sh | sudo bash
```

El instalador descarga la última versión, **comprueba su SHA256** (y su procedencia si tienes `gh`), crea el usuario sin privilegios `portero`, instala un servicio systemd endurecido y arranca. Al terminar te muestra una dirección y un **código de instalación**: ábrela en el navegador y el **asistente de configuración** te guía (administrador, acceso al panel, certificados, primer sitio y avisos).

Actualizar: `curl -fsSL …/install.sh | sudo bash -s -- --update` · Desinstalar: `… --uninstall` (`--purge` borra también la configuración).
Sin internet: `sudo bash install.sh --from-file portero-X.Y.Z-linux-x86_64.tar.gz`.

### En Proxmox (contenedor LXC nuevo)

En la consola del servidor Proxmox:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/MUbeira0/portero-proxy/main/contrib/proxmox-lxc.sh)"
```

Crea un LXC de Debian (4 GB de disco, 512 MB de RAM), instala Portero y te dice qué abrir. Se puede ajustar con variables (`CT_STORAGE`, `CT_IP`, `CTID`…; mira la cabecera del script).

### Con Docker

```bash
curl -fsSLO https://raw.githubusercontent.com/MUbeira0/portero-proxy/main/docker-compose.yml
docker compose up -d
docker compose logs portero      # ahí está el código de instalación
```

Luego abre `http://IP-DEL-SERVIDOR:8404/`. La imagen (`ghcr.io/mubeira0/portero-proxy`) es multiarquitectura (amd64/arm64) y está verificada con atestación.

### Verificar lo que descargas

Cada versión lleva `SHA256SUMS` y una atestación de procedencia firmada (Sigstore):

```bash
sha256sum -c SHA256SUMS --ignore-missing
gh attestation verify portero-X.Y.Z-linux-x86_64.tar.gz --repo MUbeira0/portero-proxy
```

Más en [SECURITY.md](SECURITY.md).

Otras órdenes: `portero check -c config.json` valida sin arrancar; `portero hash-password <clave>` genera un hash bcrypt; `kill -HUP <pid>` recarga desde disco.

Si olvidas la contraseña del panel: edita el archivo de configuración, escribe la nueva en `admin.password` (en claro, borrando `password_hash`) y reinicia el servicio; al arrancar se convierte en hash y desaparece del archivo. Al primer arranque de una versión con cifrado, las contraseñas y tokens en claro del archivo se migran solos.

### Servicio systemd (a mano; el instalador ya lo crea, más endurecido)

```ini
[Unit]
Description=Portero (proxy inverso)
After=network-online.target

[Service]
ExecStart=/usr/local/bin/portero run -c /etc/portero/portero.json
AmbientCapabilities=CAP_NET_BIND_SERVICE
Restart=always
RestartSec=2
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Los datos (certificados, CA, módulos, copias, estado de mantenimiento) se guardan junto al archivo de configuración.

## Configuración

Ejemplo mínimo:

```json
{
  "admin": { "bind": "0.0.0.0:8404", "user": "admin", "password": "cambia-esto" },
  "frontends": [
    {
      "name": "web", "bind": "0.0.0.0:80", "https_redirect": true,
      "default_backend": "jellyfin",
      "rules": [
        { "if": "host(juegos.casa.lan)", "backend": "juegos" },
        { "if": "path_prefix(/admin) and not src(192.168.0.0/16)", "deny": 403, "comment": "Solo desde la red local" }
      ]
    },
    {
      "name": "seguro", "bind": "0.0.0.0:443", "tls": { "certs": ["casa"] },
      "default_backend": "jellyfin",
      "modules": [ { "id": "security-headers", "config": {} } ]
    }
  ],
  "backends": [
    { "name": "jellyfin", "balance": "leastconn", "sticky": true,
      "health": { "type": "http", "path": "/health", "interval_secs": 5, "fall": 3, "rise": 2, "expect": "200-399" },
      "servers": [ { "name": "jf1", "addr": "192.168.1.108:8096" } ] },
    { "name": "juegos", "servers": [ { "name": "j1", "addr": "192.168.1.225:80" } ] }
  ],
  "acme": { "email": "tu@correo.com", "directory": "letsencrypt" },
  "dns_providers": [ { "name": "mi-cloudflare", "kind": "cloudflare", "token": "..." } ],
  "certificates": [
    { "name": "casa", "domains": ["*.casa.lan", "casa.lan"], "method": "internal" },
    { "name": "publico", "domains": ["midominio.com", "*.midominio.com"], "method": "acme-dns", "dns_provider": "mi-cloudflare" }
  ]
}
```

### Seguridad de red y registro

```json
{
  "security": { "trust_private": true, "trusted_nets": ["203.0.113.5"], "trusted_proxies": ["192.168.1.104"] },
  "logging": { "stdout": false, "file": "accesos.log", "max_mb": 20, "keep": 3 }
}
```

- `rate_limit` (por entrada): `requests` = ritmo y tamaño de la ráfaga, `per_seconds` = periodo; con `ban_minutes` la IP se bloquea ese tiempo si supera el ritmo en `ban_after` periodos distintos de los últimos 10 minutos. Las redes de confianza quedan fuera.
- Regla con `"limit": {"requests": 10, "per_seconds": 60}`: límite solo para esa regla. Regla con `"maintenance": "mensaje"`: página de mantenimiento.
- `logging.stdout` escribe cada petición en el diario de systemd (desactivado por defecto); `logging.file` guarda una línea JSON por petición con rotación.

### Actualizaciones, copias y HTTP/3

```json
{
  "updates": { "check": true },
  "backup": { "enabled": true, "every_hours": 24, "keep": 7, "dir": "copias", "passphrase": "una frase larga", "webdav_url": "https://nube.midominio.com/remote.php/dav/files/yo/Portero", "webdav_user": "yo", "webdav_password": "..." },
  "frontends": [ { "name": "seguro", "bind": "[::]:443", "tls": { "certs": ["casa"] }, "http3": true } ]
}
```

- `http3: true` abre también el puerto **UDP** de la entrada (déjalo pasar en tu cortafuegos) y anuncia `Alt-Svc`. Solo con TLS.
- Restaurar una copia: `PORTERO_BACKUP_PASSPHRASE='tu frase' portero restore copia.pbk --to /etc/portero --force` (y reiniciar el servicio).
- Comprobar una licencia: `portero license verify <clave>`.

### Condiciones

`host() path() path_prefix() path_end() path_regex() method() header(nombre[=patrón]) query(clave[=patrón]) cookie(nombre[=patrón]) src(CIDR,…) tls sni() always`

Los patrones aceptan comodín `*`. En las redirecciones se pueden usar `{scheme} {host} {path} {query}`.

### Escribir un módulo

Un módulo es un JSON con `id`, `name`, `version`, `description`, `config` (campos del formulario del panel) y `script`:

```rhai
fn on_request(req, cfg) {
  if req.path.starts_with("/secreto") && !cidr(req.ip, "192.168.0.0/16") {
    return #{ action: "deny", status: 403, body: "Solo desde casa" };
  }
  #{ response_headers: #{ "X-Powered-By": "Portero" } }
}
```

`req` trae `method path query host ip tls headers`. El resultado puede incluir `action` (`deny`, `respond`, `redirect`), `status`, `body`, `location`, `set_headers`, `remove_headers`, `set_path`, `response_headers`, `remove_response_headers` y `backend`. Funciones: `glob() cidr() now() rand_hex() html_escape()`.

## Limitaciones conocidas

- El modo TCP abre una conexión por cliente (no hay pool); el pool keep-alive es solo para HTTP.
- El reto ACME contra Let's Encrypt y los proveedores DNS se han escrito contra sus APIs documentadas pero dependen de servicios externos: usa primero el servidor de **pruebas** (`staging`).
- Route 53 y OVH (firmas propias) se pueden usar mediante el proveedor `webhook`.
