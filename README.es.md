<div align="center">

<img src="assets/debup-animated.svg" alt="Logo animado de debup" width="560">

# debup

### El puente entre GitHub Releases y APT.

**Descubrir · Inspeccionar · Instalar · Seguir · Actualizar**

Un gestor de paquetes ligero en Bash que conecta los paquetes Debian nativos con archivos `.deb` compatibles publicados en GitHub Releases.

<p>
<a href="https://github.com/Ruraam/debup/releases"><img src="https://img.shields.io/github/v/release/Ruraam/debup?style=for-the-badge&color=16a34a" alt="Última versión"></a>
<a href="https://github.com/Ruraam/debup/actions"><img src="https://img.shields.io/github/actions/workflow/status/Ruraam/debup/installer-validation.yml?branch=main&style=for-the-badge&label=CI" alt="CI"></a>
<a href="LICENSE"><img src="https://img.shields.io/badge/licencia-GPL--3.0-2563eb?style=for-the-badge" alt="GPL-3.0"></a>
<a href="https://www.gnu.org/software/bash/"><img src="https://img.shields.io/badge/shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash"></a>
</p>

[English](README.md) · [Français](README.fr.md) · [Español](README.es.md)

**[📘 Guía en español](docs/GUIA_ES.md)** · [User guide](docs/USER_GUIDE.md) · [Guía francesa](docs/GUIDE_FR.md) · [Versiones](https://github.com/Ruraam/debup/releases)

</div>

---

## ¿Por qué debup?

Debian ofrece un ecosistema de paquetes fiable. GitHub Releases aloja miles de proyectos upstream. debup conecta ambos mundos en un flujo de trabajo basado en APT: permite descubrir paquetes compatibles, inspeccionarlos, instalarlos de forma nativa y seguir sus actualizaciones.

> **No es un sandbox:** los paquetes GitHub `.deb` se instalan como paquetes nativos del sistema. Sus scripts de mantenimiento pueden ejecutarse con privilegios de root.

## ✨ Funciones principales

| Función | Descripción |
|---|---|
| **Búsqueda unificada** | Busca paquetes APT y assets compatibles de GitHub Releases. |
| **Instalación directa** | Instala desde APT o desde un repositorio `owner/repo`. |
| **Versión específica** | Permite elegir una release con `owner/repo@tag`. |
| **Inspección** | Examina metadatos, archivos y scripts de mantenimiento antes de instalar. |
| **Integridad** | Verifica checksums SHA-256 publicados para las descargas compatibles. |
| **Protección APT** | Simula transacciones y rechaza planes que eliminarían paquetes instalados. |
| **Seguimiento** | Comprueba nuevas versiones de proyectos GitHub registrados. |
| **Dry-run** | Previsualiza las operaciones compatibles. |
| **Bloqueo de paquetes** | Usa `apt-mark hold/unhold`. |
| **Idiomas** | Mensajes CLI en inglés, francés, alemán, español, italiano y portugués. |

## Instalación

### Instalador interactivo

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash
```

### Instalación no interactiva

```bash
curl -fsSL https://raw.githubusercontent.com/Ruraam/debup/main/installer.sh | bash -s -- --yes
```

Revisa las opciones y advertencias del instalador antes de continuar. Para automatización de producción, inspecciona el script y fija una revisión que hayas verificado.

### Actualizar

Desde el repositorio APT:

```bash
sudo apt update
sudo apt upgrade debup
```

Desde una instalación de release o fuentes:

```bash
dbp upgrade
```

## Inicio rápido

```bash
# Buscar en APT y GitHub Releases
dbp search terminal

# Consultar e inspeccionar un proyecto
dbp info Ruraam/Uraam
dbp inspect Ruraam/Uraam

# Instalar y registrar un paquete GitHub
dbp install Ruraam/Uraam

# Instalar un paquete APT nativo
dbp install ripgrep

# Comprobar actualizaciones
dbp

# Aplicar actualizaciones
dbp upgrade

# Simular una operación
dbp upgrade --dry-run

# Mostrar fuentes registradas
dbp list
```

Para instalar una release concreta:

```bash
dbp install propietario/repositorio@vX.Y.Z
```

## Referencia de comandos

| Comando | Alias | Descripción |
|---|---|---|
| `install <owner/repo>` | `-i`, `-a` | Instala un paquete GitHub y registra su fuente |
| `install <paquete>` | `-i`, `-a` | Instala un paquete APT nativo |
| `install <owner/repo>@<tag>` | — | Instala una release específica |
| `search <consulta>` | `-s` | Busca en APT y GitHub |
| `info <owner/repo>` | `-f` | Muestra metadatos y assets compatibles |
| `inspect <owner/repo>` | `-I` | Inspecciona archivos y scripts de mantenimiento |
| `update` | `-v`, sin argumento | Comprueba actualizaciones |
| `upgrade` | `-u` | Aplica actualizaciones disponibles |
| `list` | `-l` | Lista fuentes registradas |
| `remove <paquete>` | `-r` | Purga un paquete y elimina su registro |
| `pin <paquete>` | `-p` | Bloquea un paquete con APT |
| `unpin <paquete>` | `-n` | Libera un bloqueo APT |
| `stats` | `-S` | Muestra el estado de paquetes y cachés |
| `token [PAT]` | `-t` | Configura un token GitHub |
| `clean` | `-c` | Limpia cachés compatibles |
| `help` | `-h` | Muestra la ayuda |

Añade `--dry-run` o `-d` a los comandos compatibles para previsualizar acciones. Añade `--yes` o `-y` a los flujos compatibles para aceptar confirmaciones de forma no interactiva. El soporte depende del comando: consulta `dbp help`.

## Seguridad y confianza

- **Repositorio APT:** los paquetes se distribuyen mediante un repositorio firmado. El instalador fija la huella primaria GPG esperada antes de confiar en la clave.
- **GitHub Releases:** debup verifica checksums SHA-256 compatibles. Un checksum detecta diferencias respecto al archivo publicado, pero por sí solo no autentica al editor.
- **Privilegios:** los scripts de mantenimiento Debian pueden ejecutarse como root. Inspecciona paquetes desconocidos con `dbp inspect`.
- **Transacciones APT:** debup simula las operaciones relevantes y rechaza planes que eliminen paquetes instalados; utiliza `--no-remove` cuando corresponde.
- **Sin sandbox:** las aplicaciones se integran en el sistema anfitrión. debup no proporciona aislamiento como Flatpak.

## Publicación del repositorio APT

Las releases estables de GitHub llaman al workflow reutilizable de publicación APT después de construir el paquete Debian. Las pre-releases quedan excluidas. El workflow necesita el secreto `GPG_PRIVATE_KEY` y una huella de clave pública coincidente con la fijada por el instalador.

La CI verde valida los trabajos ejecutados, pero una publicación real todavía debe comprobarse con una release estable: despliegue Pages, metadatos firmados e instalación APT desde un cliente.

## Compatibilidad

debup está diseñado para Debian y Ubuntu y sistemas derivados que utilicen APT y dpkg. El paquete debup es independiente de la arquitectura; la selección de binarios GitHub comprueba la arquitectura del equipo y los nombres de assets admitidos. La compatibilidad con otras distribuciones derivadas puede variar.

## Documentación y enlaces

- **[Guía completa en español](docs/GUIA_ES.md)** — instalación, comandos, configuración, seguridad y solución de problemas.
- [Guía en inglés](docs/USER_GUIDE.md)
- [Guide français](docs/GUIDE_FR.md)
- [Releases](https://github.com/Ruraam/debup/releases)
- [CI](https://github.com/Ruraam/debup/actions)
- [Problemas y sugerencias](https://github.com/Ruraam/debup/issues)

## Contribuir

Son bienvenidos los informes reproducibles, casos de prueba y pull requests centradas. Incluye la distribución, arquitectura, versión de debup y el comando/salida exactos al informar de un problema.

## Licencia

debup se distribuye bajo la [GNU General Public License v3.0](LICENSE).

<div align="center">

**Hecho para Debian. Conectado al upstream.** 🐧

</div>
