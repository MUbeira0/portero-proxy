# Cambios

## [0.2.0]
- **Asistente de instalación web**: si no hay configuración, Portero abre un asistente protegido por un código de un solo uso (administrador, acceso al panel, certificados, primer sitio y avisos).
- Instalador `install.sh` (verifica SHA256 y procedencia, usuario sin privilegios, servicio systemd endurecido, actualización y desinstalación), imagen Docker y script para LXC de Proxmox.
- Versiones publicadas por GitHub Actions (x86_64 y aarch64, estáticas) con `SHA256SUMS` y atestación de procedencia.
- DDNS (Cloudflare, DuckDNS, DynDNS2, webhook), avisos por correo/Telegram/Discord/webhook, DNS automático (AdGuard, Cloudflare), 2FA, auditoría, secretos cifrados, módulos Rhai, portal de inicio de sesión, modo mantenimiento, límites por regla, diagnóstico y copia completa.

## [0.1.0]
- Primera versión: proxy HTTP/TCP, balanceo, comprobaciones de salud, panel web y certificados.
