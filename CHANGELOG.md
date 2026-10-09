# Cambios

## [0.6.6]
- **Arreglo del botón «Mantenimiento» de los sitios**: ponía la página de mantenimiento solo en la entrada HTTPS del sitio. Los sitios detrás de Cloudflare en modo Flexible entran por el puerto 80 (regla «host(x) and header(cf-visitor…)»), así que sus visitantes se la saltaban y veían el sitio normal. Ahora se añade delante de todas las reglas del sitio, en todas las entradas. Además el cuadro avisa de que, con «Dejar pasar a la red local» marcado, quien prueba desde casa sigue viendo el sitio normal.

## [0.6.5]
- **Categorías en «Sitios»**: ordena y filtra tus sitios por categoría (Domótica, Multimedia, Administración… las que quieras). La página gana buscador, filtros por categoría y por estado (en línea, con problemas, con login, solo red local), grupos que se pliegan, el botón 🏷 en cada sitio, «✨ Sugerir categorías» (propone una según el nombre; tú decides) y «🏷 Categorías» para renombrarlas. También hay campo de categoría en el asistente de sitio. Es solo organización: no cambia cómo se publica ningún sitio. El resumen de «Aplicar cambios» ahora cuenta también estos cambios.

## [0.6.4]
- **Arreglo importante de la interfaz Pro**: con licencia activa, las páginas y campos de las funciones Pro (Tráfico, bloqueo automático, países, llaves de acceso, cabeceras, caché, cuentas del panel en sitios, cuentas temporales, sustituir CNAME) seguían saliendo bloqueados («Función Pro: se activa con una licencia») porque la comprobación de licencia de la interfaz no llegaba a las demás páginas. También recupera el campo «Mantenimiento programado» de las reglas, que estaba oculto por lo mismo. Con una prueba nueva para que no vuelva a pasar.

## [0.6.3]
- **Diagnóstico**: los sitios publicados por Cloudflare con la nube naranja ya no salen como «apunta a otra IP». Su DNS devuelve las IPs de Cloudflare a propósito; ahora se reconocen y se resumen como correctos (y avisa solo si un sitio marcado con la nube naranja deja de resolver a Cloudflare).

## [0.6.2]
- **Diagnóstico y estado del DNS de los sitios**: ya no salen avisos falsos de «no resuelve». Portero comprobaba el DNS de todos los sitios a la vez y los DNS locales como AdGuard (que por defecto aceptan 20 consultas por segundo contando toda la red local junta) rechazaban la mitad. Ahora las consultas van espaciadas (unas 8 por segundo), se recuerdan 60 segundos y un fallo suelto se reintenta antes de darlo por malo.

## [0.6.1]
- **Webs con mucho tráfico**: el bloqueo automático ya no cuenta como ataque los 404 de visitas con sesión (con cookie o Authorization): una app que consulta mucho no es un escáner. Nueva lista «Sitios que no se vigilan» (`skip_hosts`) para exentar dominios concretos. Las subidas grandes y lentas ya no se cortan por el tiempo de espera de la respuesta (se cuenta aparte, hasta 30 min).
- **DDNS**: si cambias los ajustes de un registro (nube naranja de Cloudflare, TTL, IPv6, «Sustituir el CNAME») se actualiza en el proveedor aunque la IP no haya cambiado. Antes había que esperar hasta 6 horas.

## [0.6.0]
- **Edición Pro**: las funciones de la 0.5 (bloqueo automático de IPs y avisos de ataques, países por IP, tráfico y búsqueda en el registro, caché, cabeceras de seguridad, cuentas del panel delante de los sitios, llaves de acceso, cuentas temporales y las dos ayudas para Cloudflare) pasan a ser funciones con licencia. Sin licencia quedan cerradas **sin dejar nada abierto**: una zona con «cuentas del panel» sigue protegida (nadie entra) y los países no bloquean a nadie. Los bloqueos manuales, el arreglo de la IP real en el panel y todo lo anterior siguen siendo gratuitos.
- **Nodos (Pro)**: gestiona varios Porteros desde un solo panel. Añade otros Porteros en la página «Nodos» (dirección y un token de API creado en ellos, guardado cifrado) y elígelos en el selector de la cabecera: todas las páginas pasan a ser del Portero elegido. No se pueden gestionar desde fuera las cuentas, tokens, licencia, contraseñas ni actualizaciones de un nodo, y todo queda en la auditoría de los dos.
- Nueva condición `peer(CIDR)`: coincide con quien abre la conexión, no con la IP real del visitante (sirve para que un Portero interno solo acepte a otro Portero que lo precede).

## [0.5.2]
- **Cloudflare en modo «Flexible»**: si la conexión llega desde un proxy de confianza (tus rangos de Cloudflare en `trusted_proxies`) y su cabecera `CF-Visitor` dice que el visitante usó HTTPS, Portero lo trata como HTTPS. Antes la entrada del puerto 80 lo mandaba a HTTPS una y otra vez (bucle de redirección). De fuera de los proxies de confianza no se cree la cabecera.

## [0.5.1]
- **DDNS con Cloudflare**: nueva opción «Sustituir el CNAME» en cada registro. Si el nombre ya existe como CNAME (por ejemplo, de un túnel de Cloudflare), Portero lo quita y crea el registro A con tu IP; el CNAME anterior queda anotado en el mensaje del registro por si hay que volver atrás. Sin la opción, avisa y no toca nada.

## [0.5.0]
- **Bloqueo automático de IPs** (activado por defecto): bloquea solas, en todo Portero, las IP que fallan varias veces el inicio de sesión (panel o portales), piden rutas típicas de escáneres (`/.env`, `/wp-login.php`…) o provocan ráfagas de 404/400. El bloqueo se duplica con cada reincidencia, se guarda al reiniciar, avisa por tus canales y se gestiona en Seguridad. Tu red local y las IP de confianza nunca se bloquean. Los bloqueos manuales ahora valen para todo Portero.
- **Países (GeoIP)**: base gratuita DB-IP Lite descargada y actualizada sola. Nuevas condiciones `country(ES)` y `country_not(ES)` (esta nunca bloquea si no se conoce el país). El país aparece en el Registro y se puede buscar por él.
- **Tráfico**: página nueva con gráfica por sitio (48 h), errores 4xx/5xx, visitantes y rutas más frecuentes, y búsqueda en el registro de accesos (por texto, IP, dominio, país o código; en memoria o en el archivo del registro).
- **Caché de contenido estático** por regla (en memoria, con `X-Portero-Cache`), solo para peticiones sin identificar; se vacía desde Tráfico.
- **Cabeceras de seguridad** con un clic por regla («básicas» o «estrictas»).
- **Cuentas del panel delante de cualquier sitio**: una regla con portal puede aceptar las cuentas del panel y su verificación en dos pasos, para poner un inicio de sesión seguro delante de apps que no tienen.
- **Llaves de acceso (passkeys / WebAuthn)** como alternativa al código de 6 cifras (que sigue funcionando siempre): huella, cara, PIN del móvil o llave de seguridad. Se registran en Seguridad (HTTPS y un dominio).
- **Avisos nuevos**: un sitio que devuelve errores 5xx en la mayoría de sus peticiones, entrada al panel desde un país nuevo, y cuando un cliente llega al 80 % de su cuota.
- **Cuentas temporales**: fecha de caducidad en las cuentas del panel.

## [0.4.4]
- **Seguridad (importante si publicas el panel por Portero)**: el panel ahora ve la IP real del visitante y no la del propio Portero. Antes, quien intentaba entrar desde internet aparecía con la IP local, así que unos pocos intentos fallidos de un atacante bloqueaban el inicio de sesión a todo el mundo (también a ti), y la auditoría y los avisos de «nuevo acceso» mostraban la IP equivocada. La cabecera que lo permite es propia, solo se envía al panel de esta máquina y el proxy descarta la que intente poner un cliente.

## [0.4.3]
- **Diagnóstico**: la comprobación de DNS ahora compara el nombre con tu IP pública real. Si apunta a ella lo da por correcto (en verde) en vez de dejar un aviso; si es un nombre gestionado por el DDNS y no coincide, avisa de que está desactualizado.

## [0.4.2]
- **Arreglo importante del panel**: un error en la página de Seguridad (un selector mal escrito) hacía que, al activar la verificación en dos pasos, **no se mostraran los códigos de recuperación** (el 2FA sí quedaba activado), y que varios ajustes de esa página no se guardaran al editarlos. Arreglado, con una prueba que vigila que no vuelva a pasar.
- **Códigos de recuperación nuevos**: botón en Seguridad (pide contraseña y un código actual de la aplicación; los anteriores dejan de valer).
- **Seguridad**: la pantalla de bloqueo ya no enseña a los visitantes de fuera la nota interna de la regla (solo la ve la red local de confianza).

## [0.4.1]
- **Revocar claves**: lista pública firmada de licencias revocadas que las instalaciones recogen solas (con caché sin conexión); `portero-tools revoke/unrevoke/issued` y `scripts/revoke-license.sh`.
- Claves con **«exigir conexión»** (se bloquean si no se puede comprobar la lista), **atadas a un equipo** y con registro de lo emitido.
- **Arreglos de licencias**: la caducidad y la revocación ahora se aplican con el servicio en marcha (antes solo al reiniciar); retrasar el reloj o borrar las marcas ya no alarga una licencia; al activar o quitar una clave se regeneran al momento los clientes, la marca y los módulos Pro; el panel se refresca solo y muestra por qué una clave está bloqueada.
- **Seguridad**: los destinos de los clientes se comprueban también al conectar (nombres que resuelven a esta máquina); un comodín no puede pisar los dominios de otro cliente; topes duros por cliente; el «HTTPS obligatorio» fijo ahora se aplica de verdad a todos sus sitios; los tokens ya no los lista un usuario de solo lectura.
- Pruebas nuevas: licencias (12), matriz de permisos con todas las rutas y roles, y destinos prohibidos.

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
