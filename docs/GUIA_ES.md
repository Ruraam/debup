# debup — Guía de usuario y administración

**El puente entre GitHub Releases y APT.** Esta guía cubre la instalación, los comandos, la configuración, la verificación de paquetes y la publicación del repositorio APT.

- Proyecto: https://github.com/Ruraam/debup
- Releases: https://github.com/Ruraam/debup/releases
- Incidencias: https://github.com/Ruraam/debup/issues
- Licencia: GPL-3.0

## 1. Descripción general

debup es una herramienta CLI escrita en Bash para Debian y Ubuntu. Conecta:
- **APT:** los repositorios configurados en el sistema.
- **GitHub Releases:** proyectos que publican archivos Debian `.deb` compatibles.

Permite buscar en ambas fuentes, instalar paquetes mediante las herramientas nativas de Debian, registrar proyectos GitHub y comprobar si existen nuevas versiones.

**Importante:** debup no es un contenedor ni un sandbox. Un archivo `.deb` se instala como paquete nativo y sus scripts de mantenimiento pueden ejecutarse con privilegios de root.

## 2. Instalación

### Requisitos

El paquete declara Bash (>= 4.0), curl y jq. El funcionamiento también utiliza las herramientas Debian (APT, dpkg, dpkg-deb, apt-mark) y utilidades comunes como sha256sum y awk.

Se necesita un sistema Debian/Ubuntu con APT y dpkg. Las operaciones administrativas requieren root, normalmente mediante sudo o doas.

### Instalador interactivo

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash
```

### Instalación no interactiva

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash -s -- --yes
```

El instalador presenta los métodos disponibles. Lee las opciones y advertencias de confianza antes de continuar. Para automatización de producción, revisa el script y fija una revisión verificada en lugar de ejecutar una rama cambiante sin inspección.

### Actualizar

Instalación desde APT:

```bash
sudo apt update
sudo apt upgrade debup
```

Instalación desde una release o desde fuentes:

```bash
dbp upgrade
```

Comprobar:

```bash
command -v dbp
command -v debup
dbp help
```

## 3. Primeros pasos

```bash
# Buscar en APT y GitHub Releases
dbp search terminal

# Consultar metadatos e inspeccionar el paquete
dbp info Ruraam/Uraam
dbp inspect Ruraam/Uraam

# Instalar y registrar un proyecto GitHub
dbp install Ruraam/Uraam

# Instalar un paquete APT nativo
dbp install ripgrep

# Comprobar actualizaciones (también es la acción predeterminada)
dbp

# Aplicar actualizaciones APT y GitHub registradas
dbp upgrade

# Previsualizar una operación
dbp upgrade --dry-run

# Listar fuentes registradas
dbp list
```

Para seleccionar una release concreta:

```bash
dbp install propietario/repositorio@vX.Y.Z
```

## 4. Referencia de comandos

| Comando | Alias | Descripción |
|---|---|---|
| `install <owner/repo>` | `-i`, `-a` | Instala un paquete GitHub y registra su fuente |
| `install <paquete>` | `-i`, `-a` | Instala un paquete APT nativo |
| `install <owner/repo>@<tag>` | — | Instala una release concreta |
| `search <consulta>` | `-s` | Busca en APT y GitHub |
| `info <owner/repo>` | `-f` | Muestra metadatos y assets compatibles |
| `inspect <owner/repo>` | `-I` | Inspecciona archivos y scripts de mantenimiento |
| `update` | `-v`, sin argumento | Comprueba actualizaciones |
| `upgrade` | `-u` | Aplica las actualizaciones disponibles |
| `list` | `-l` | Lista fuentes registradas |
| `remove <paquete>` | `-r` | Purga el paquete y elimina su registro |
| `pin <paquete>` | `-p` | Bloquea un paquete con APT |
| `unpin <paquete>` | `-n` | Elimina un bloqueo APT |
| `stats` | `-S` | Muestra el estado de paquetes y cachés |
| `token [PAT]` | `-t` | Configura un token GitHub |
| `clean` | `-c` | Limpia cachés compatibles |
| `help` | `-h` | Muestra la ayuda |

Opciones comunes:
- `-d`, `--dry-run`: previsualiza acciones compatibles sin aplicar los cambios correspondientes.
- `-y`, `--yes`: acepta confirmaciones compatibles para uso no interactivo.

El soporte de opciones depende del comando. Consulta `dbp help` en la versión instalada.

## 5. Seguimiento de fuentes GitHub

Las asociaciones entre paquetes y fuentes GitHub se guardan en:

```text
/etc/debup/sources.list
```

Formato:

```text
<nombre-paquete>|<propietario-github>/<repositorio-github>
```

Utiliza `dbp list` para revisar proyectos registrados, `dbp update` para comprobar nuevas versiones y `dbp upgrade` para aplicar las actualizaciones. `dbp remove <paquete>` purga el paquete mediante APT y elimina su registro. Lee la confirmación; utiliza `--yes` solo cuando la operación sea intencionada.

## 6. Inspección e integridad

### Scripts de mantenimiento

Los paquetes Debian pueden contener `preinst`, `postinst`, `prerm` y `postrm`. Estos scripts pueden ejecutarse con privilegios administrativos durante la instalación, actualización o eliminación.

Inspecciona los paquetes desconocidos:

```bash
dbp info propietario/repositorio
dbp inspect propietario/repositorio
```

La inspección ayuda a revisar el paquete, pero no certifica que sea seguro.

### Checksums SHA-256

Para las descargas GitHub Releases, debup busca assets de checksum compatibles y verifica el paquete descargado antes de instalarlo. El instalador también verifica checksums en la ruta de instalación directa desde una release.

Un checksum correcto detecta corrupción o diferencias frente al checksum publicado. No autentica por sí solo al editor si un atacante puede sustituir tanto el paquete como el checksum. Da preferencia a proyectos upstream de confianza y firmas autenticadas de forma independiente cuando estén disponibles.

### Selección de arquitectura

La selección utiliza la arquitectura indicada por dpkg y alias habituales:

| Arquitectura dpkg | Alias habituales |
|---|---|
| `amd64` | `amd64`, `x86_64`, `x64` |
| `arm64` | `arm64`, `aarch64`, `arm64v8` |
| `armhf` | `armhf`, `armv7l` |
| `i386` | `i386`, `i686` |

También pueden seleccionarse paquetes independientes de arquitectura llamados `all`. Si los assets son ambiguos, debup debe detenerse en lugar de adivinar.

## 7. Dry-run y seguridad de transacciones

Ejemplos:

```bash
dbp install propietario/repositorio --dry-run
dbp upgrade --dry-run
dbp remove nombre-paquete --dry-run
dbp clean --dry-run
```

Dry-run puede realizar solicitudes de red/API de solo lectura. No es una simulación completamente offline. En paquetes GitHub no descarga el paquete y, por tanto, no resuelve todas sus dependencias.

Para las transacciones APT relevantes, debup simula el plan y rechaza operaciones que eliminen paquetes instalados. La ruta de instalación real también utiliza la protección `--no-remove` cuando corresponde. Revisa siempre el plan y conserva copias de seguridad.

## 8. Configuración y rutas

| Ruta | Función |
|---|---|
| `/etc/debup/sources.list` | Asociaciones de paquetes GitHub registrados |
| `${XDG_CONFIG_HOME:-$HOME/.config}/debup/token` | Token GitHub del usuario |
| `/etc/debup/debup.conf` | Configuración/token root cuando se configura desde root |
| `${XDG_CACHE_HOME:-$HOME/.cache}/debup/api` | Caché de respuestas de GitHub API |
| `/usr/share/debup/locales` | Traducciones CLI instaladas |
| `/usr/local/share/debup/locales` | Traducciones locales/personalizadas, si existen |

El token GitHub es opcional; las solicitudes anónimas tienen un límite menor. No compartas tokens en logs, capturas o informes. Para consultar metadatos públicos, evita permisos innecesarios.

## 9. Publicación del repositorio APT

El pipeline de release tiene dos etapas:

1. Construir el paquete Debian y adjuntarlo a GitHub Release.
2. Para una release estable (no prerelease), llamar al workflow reutilizable de publicación APT después de finalizar la compilación.

El publicador importa la clave de firma configurada y publica los metadatos del repositorio. El secreto `GPG_PRIVATE_KEY` debe contener la clave privada esperada por el workflow. Su huella primaria debe coincidir con la fijada en el instalador.

El disparo manual sigue disponible, pero la publicación normal de releases estables ya no depende de una solicitud separada `gh workflow run`.

**La validación integral sigue siendo necesaria:** una CI verde no demuestra por sí sola que el despliegue real de GitHub Pages, los metadatos firmados y la instalación APT desde un cliente hayan funcionado. Tras la próxima release estable, comprueba el job publicador, Pages, los metadatos, la firma y una instalación limpia desde un cliente.

## 10. Solución de problemas

### No se encuentra el comando

```bash
command -v dbp
command -v debup
```

Si no aparece ninguno, comprueba que la instalación terminó y que el directorio de binarios está en `PATH`. Vuelve a abrir el shell si es necesario.

### Límite de GitHub API

Configura un token opcional:

```bash
dbp token
```

Sigue el indicador y no compartas el token.

### No hay un asset compatible

Consulta la release upstream. Comprueba que publique un archivo `.deb` para tu arquitectura o un paquete independiente `all`, con un nombre reconocido. debup evita adivinar si existe ambigüedad.

### Falta el checksum o no coincide

No ignores el error sin investigar. Comprueba que la release publique un checksum para el nombre exacto del archivo descargado. Si el problema continúa, detente y contacta con el mantenedor upstream.

### Transacción APT rechazada

Revisa el plan simulado. Si APT propone eliminar paquetes instalados, debup rechaza la operación como medida de seguridad. Resuelve los conflictos de repositorios o dependencias en lugar de forzar una eliminación inesperada.

### No hay terminal interactivo

Algunos indicadores responden negativamente por defecto cuando no hay TTY. Utiliza `--yes` solo para operaciones que ya hayas revisado.

## 11. Límites y seguridad

- debup está dirigido a sistemas APT/dpkg; no es un gestor de paquetes para RPM, Arch o Alpine.
- El alojamiento en GitHub no significa que un proyecto sea fiable o esté auditado.
- Un paquete Debian nativo puede modificar archivos del sistema, instalar servicios y ejecutar scripts como root.
- SHA-256 verifica los datos frente al checksum publicado, pero no autentica por sí solo al editor.
- La firma APT autentica los metadatos frente a la clave configurada. Protege la clave privada y verifica la huella fijada.
- debup no crea un sandbox para las aplicaciones instaladas.
- La disponibilidad de binarios depende de los mantenedores upstream y del nombre de sus assets.

Si tienes dudas: inspecciona el paquete, verifica el proyecto upstream, revisa la transacción APT y conserva una copia de seguridad recuperable.

---

*Esta guía describe el comportamiento documentado del repositorio. Consulta siempre `dbp help` y las notas de versión para los cambios específicos de la versión instalada.*
