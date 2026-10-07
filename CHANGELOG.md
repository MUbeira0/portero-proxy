# Cambios

## [0.4.0]
- **Edición Pro** con clave de licencia firmada (se comprueba sin conexión, con límites opcionales): la gratuita no cambia.
- **Clientes aislados (multiempresa)**: espacio propio por cliente con sus sitios, certificados, usuarios del portal, registro y consumo; dominios, entradas y redes permitidas; **ajustes y sitios fijos** que el cliente no puede cambiar; cuotas; suspensión; cuentas de cliente con panel reducido.
- **Consumo y cuotas mensuales** por cliente con informe CSV, **marca blanca** (global y por cliente), **tokens de API**, **6 módulos Pro** (WAF, clave de API, cabeceras estrictas, límite de tamaño, lista negra de IPs, redirecciones), **mantenimientos programados** y **exportar la auditoría**.

## [0.3.1]
- **Usuarios**: varias cuentas del panel con roles (administrador, operador, solo lectura), 2FA por cuenta, contraseñas restablecibles por un administrador, sesiones que se cierran al cambiar una cuenta y avisos de seguridad.
- **Directorio de usuarios del portal**: se definen una vez y se usan con `@nombre` en sitios y reglas; importación de los usuarios escritos a mano.
- **Portal de acceso más intuitivo**: botón mostrar/ocultar contraseña, aviso de mayúsculas, errores claros, página accesible directamente y tras cerrar sesión, bloqueo por intentos explicado en la propia página, tema claro/oscuro, título/mensaje/ayuda personalizables por sitio con vista previa, y selección de usuarios del directorio con casillas en el asistente de sitios y en las reglas.
- Los intentos fallidos del portal de los sitios ya no bloquean el acceso al panel desde la misma IP.
- Las actualizaciones nunca instalan una versión igual o anterior (protección contra repetir paquetes antiguos firmados).

## [0.3.0]
- **Actualizaciones desde el panel** con firma Ed25519 + SHA256, reverificación por un servicio aparte y vuelta atrás si la nueva versión no arranca.
- **Copias automáticas cifradas** (carpeta local con rotación y subida opcional a WebDAV) y `portero restore`.
- **Importar** desde Nginx / Nginx Proxy Manager y Caddyfile.
- **HTTP/3 (QUIC)** por entrada y soporte de **IPv6** comprobado de extremo a extremo.
- **Licencia**: claves firmadas que se comprueban sin conexión; hoy todo es gratuito (infraestructura lista para una edición de pago).
- Interfaz cifrada dentro del binario, versiones firmadas con clave propia (el instalador exige la firma) y nueva página «Sistema».

## [0.2.0]
- **Asistente de instalación web**: si no hay configuración, Portero abre un asistente protegido por un código de un solo uso (administrador, acceso al panel, certificados, primer sitio y avisos).
- Instalador `install.sh` (verifica SHA256 y procedencia, usuario sin privilegios, servicio systemd endurecido, actualización y desinstalación), imagen Docker y script para LXC de Proxmox.
- Versiones publicadas por GitHub Actions (x86_64 y aarch64, estáticas) con `SHA256SUMS` y atestación de procedencia.
- DDNS (Cloudflare, DuckDNS, DynDNS2, webhook), avisos por correo/Telegram/Discord/webhook, DNS automático (AdGuard, Cloudflare), 2FA, auditoría, secretos cifrados, módulos Rhai, portal de inicio de sesión, modo mantenimiento, límites por regla, diagnóstico y copia completa.

## [0.1.0]
- Primera versión: proxy HTTP/TCP, balanceo, comprobaciones de salud, panel web y certificados.
