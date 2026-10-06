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

## Protección del propio programa

- Portero se distribuye **solo compilado** (binario estático sin símbolos ni rutas de compilación). El código fuente no se publica.
- La licencia (`LICENSE`) **no permite modificarlo, descompilarlo ni redistribuirlo**.
- Un binario alterado se detecta: no coincidirá con `SHA256SUMS` ni con la atestación firmada, y el instalador se negará a instalarlo.
- Ningún programa distribuido puede ser matemáticamente inmune a la ingeniería inversa; la protección real es la combinación de no publicar el código, la licencia y la verificación de integridad.

## Recomendaciones

- Deja activada la opción **«solo desde mi red local»** del panel y activa la verificación en dos pasos.
- No expongas el puerto del panel (8404) a internet; publícalo a través de una regla de Portero con portal de inicio de sesión, o por VPN.
- Haz copia de `/etc/portero` (la configuración cifrada **y** `secret.key`) en un sitio seguro.

## Avisar de una vulnerabilidad

Usa **Security → Report a vulnerability** en la página del repositorio (aviso privado). Por favor no abras una incidencia pública con detalles de la vulnerabilidad.
