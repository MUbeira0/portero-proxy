# Seguridad

## Cómo se protege Portero por defecto

- **Contraseñas con hash bcrypt**: la del panel y las de los usuarios de las reglas. Nunca se guardan ni se muestran en claro.
- **Secretos cifrados en disco** con AES-256-GCM (tokens DNS, contraseña SMTP, tokens de Telegram/Discord…). La clave está en `secret.key` (permisos 600) junto a la configuración; **haz copia de esa clave** o no podrás leer los secretos si restauras la configuración.
- **El navegador nunca recibe los secretos** (el panel los muestra enmascarados).
- Panel: verificación en dos pasos (TOTP), sesiones con caducidad, protección CSRF, cabeceras de seguridad (CSP, X-Frame-Options…), registro de auditoría, redes permitidas y límite de intentos de acceso.
- El asistente de instalación solo se abre si **no hay configuración** y exige un **código de un solo uso** que solo ve quien tiene acceso a la consola o al archivo `setup-token`; se limita a 6 intentos cada 5 minutos y se cierra al terminar.
- El servicio se ejecuta como usuario sin privilegios (`portero`) con un servicio systemd endurecido (sin nuevos privilegios, sistema de archivos de solo lectura salvo `/etc/portero`, llamadas restringidas).

## Versiones verificables

Cada versión publicada se compila en GitHub Actions y trae:

- `SHA256SUMS` con la suma de cada paquete (el instalador la comprueba siempre y se niega a instalar si no coincide).
- **Atestación de procedencia firmada** (Sigstore / SLSA): demuestra que el binario lo compiló el flujo de publicación de este repositorio a partir de un commit concreto del código fuente (que es privado).
  Compruébalo tú mismo:

  ```bash
  gh attestation verify portero-X.Y.Z-linux-x86_64.tar.gz --repo MUbeira0/portero-proxy
  ```

- Imagen Docker en `ghcr.io/mubeira0/portero-proxy` con su propia atestación.

## Cuentas y roles

- Roles: **administrador**, **operador** y **solo lectura**; los permisos los aplica el servidor en cada petición (no solo la interfaz) y una cuenta desactivada o borrada pierde sus sesiones al instante.
- Las cuentas adicionales **no se pueden crear ni modificar desde la configuración general** (solo desde la página Usuarios, que exige la contraseña —y el código 2FA— de quien lo hace).
- Cada cuenta tiene su propia verificación en dos pasos y sus códigos de recuperación; el propietario no puede borrarse ni degradarse.
- Los inicios de sesión de cuentas inexistentes tardan lo mismo que los de cuentas reales (no se puede averiguar qué usuarios existen).

## Licencias

- Las claves van firmadas con Ed25519 y se comprueban sin conexión; no se pueden fabricar ni alterar. Pueden **caducar**, **atarse a un equipo** y exigir **conexión cada N días**.
- **Revocación**: el propietario publica una lista de claves revocadas, también firmada. Las instalaciones la bajan solas (cada pocas horas), la guardan y la vuelven a verificar al arrancar; una lista falsa, alterada o más antigua que la que ya tienen se ignora. Una clave con «exigir conexión» se bloquea además si no se puede comprobar la lista en ese plazo, así que cortarle internet no la salva.
- La licencia se reevalúa cada pocos minutos (caducidad, revocación, reloj). Retrasar el reloj no alarga una licencia; borrar las marcas de comprobación tampoco.
- Límite honesto: quien controla su propio equipo y no tiene «exigir conexión» puede impedir que le llegue una revocación; por eso las claves de clientes deben emitirse con caducidad y/o «exigir conexión».

## Clientes (edición Pro)

- Cada cuenta de cliente solo puede usar la interfaz de **su espacio** (/api/tenant); el servidor rechaza el resto aunque se pida a mano, y un cliente no puede pedir los datos de otro (el identificador viene siempre de su cuenta).
- Lo que sube un cliente se **valida entero** antes de aplicarse: dominios dentro de los permitidos y no usados por otro, destinos que no pueden ser esta máquina ni el panel (ni salirse de las redes que le hayas dado), cuotas, y campos desconocidos rechazados. Los ajustes **fijos** se aplican siempre y los sitios fijos no se pueden cambiar ni borrar.
- Los usuarios del portal de un cliente solo valen en los sitios de ese cliente; sus contraseñas se guardan con hash y nunca se muestran.
- Los tokens de API se guardan solo como hash, se muestran una vez, caducan si quieres y se pueden revocar; un token nunca gestiona cuentas, tokens, licencia ni descarga copias completas.
- El logo de la marca blanca se limpia (sin scripts ni referencias externas).
- Los destinos de un cliente nunca pueden ser esta máquina ni la red de enlace local: se comprueba al escribirlos y otra vez **al conectar** (nombres que resuelven a 127.0.0.1, IPv4 mapeadas en IPv6…). Un comodín de un cliente no puede pisar el dominio de otro ni los tuyos.
- Topes duros por cliente (sitios, servidores, dominios, usuarios, cabeceras) contra abusos.

## Actualizaciones y copias

- Las actualizaciones desde el panel exigen la **contraseña** (y el código 2FA si lo tienes), verifican la **firma Ed25519** de `SHA256SUMS` con una clave pública incrustada en el programa y comprueban el SHA256 del paquete. Un servicio aparte (root, solo para esto) **vuelve a verificarlo todo** antes de instalar, y si la versión nueva no arranca restaura la anterior.
- El panel solo consulta la página de versiones de GitHub; no envía datos de tu instalación. Se puede desactivar en Sistema.
- Las copias automáticas van **cifradas** (PBKDF2-HMAC-SHA256 + AES-256-GCM); sin la frase de paso no se pueden abrir y cualquier alteración se detecta.

## Protección del propio programa

- Portero se distribuye **solo compilado** (binario estático sin símbolos ni rutas de compilación). El código fuente no se publica.
- La licencia (`LICENSE`) **no permite modificarlo, descompilarlo ni redistribuirlo**.
- Un binario alterado se detecta: no coincidirá con `SHA256SUMS` ni con la atestación firmada, y el instalador se negará a instalarlo.
- Los archivos de la interfaz (HTML, JS, CSS) van **cifrados y comprimidos dentro del binario** y se descifran solo en memoria.
- Ningún programa distribuido puede ser matemáticamente inmune a la ingeniería inversa; la protección real es la combinación de no publicar el código, la licencia y la verificación de integridad.

## Recomendaciones

- Deja activada la opción **«solo desde mi red local»** del panel y activa la verificación en dos pasos.
- No expongas el puerto del panel (8404) a internet; publícalo a través de una regla de Portero con portal de inicio de sesión, o por VPN.
- Haz copia de `/etc/portero` (la configuración cifrada **y** `secret.key`) en un sitio seguro.

## Avisar de una vulnerabilidad

Usa **Security → Report a vulnerability** en la página del repositorio (aviso privado). Por favor no abras una incidencia pública con detalles de la vulnerabilidad.
