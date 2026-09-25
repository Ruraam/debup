<div align="center">

<img src="https://api.iconify.design/lucide:package-check.svg?color=%23d70a53&width=130&height=130" alt="debup logo" />
<h1>debup</h1>
<p><strong>debup gestor de paquetes : El eslabón perdido entre GitHub y APT para distribuciones basadas en Debian/Ubuntu, Raspberry Pi, Docker, WSL y terminales Linux de Android (AVF, Proot Debian/Ubuntu).</strong></p>
<p>Busca, descubre, rastrea, instala y actualiza paquetes <code>.deb</code> directamente desde GitHubReleases a través de <strong>APT</strong>.</p>
<p><em>Sin PPAs, sin sandboxes pesados, sin repositorios de terceros — solo binarios <code>.deb</code> nativos descargados directamente desde la fuente original.
Instalación sencilla con el <a href="#opción-1-repositorio-apt-recomendado">repositorio APT</a> o el<a href="#opción-2-instalador-rápido-de-una-sola-línea">instalador deuna sola línea</a>.</em></p>

</div>

<br/>

<div align="center">
<a href="LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-blue.svg" alt="GPL v3"></a> &nbsp;
<a href="https://debian.org"><img src="https://img.shields.io/badge/Platform-Debian%20%7C%20Ubuntu-red.svg" alt="Plataforma"></a> &nbsp;
<a href="#"><img src="https://img.shields.io/badge/Arch-all%20(any)-orange.svg" alt="Arquitectura"></a> &nbsp;
<a href="https://www.gnu.org/software/bash/"><img src="https://img.shields.io/badge/Language-Bash-4EAA25.svg" alt="Bash"></a>
</div>

<div align="center">
<a href="https://github.com/Ruraam/debup/releases"><img src="https://img.shields.io/github/v/release/Ruraam/debup?color=brightgreen" alt="Versión"></a> &nbsp;
<a href="#"><img src="https://img.shields.io/badge/Package_Size-6.24_Ko-success.svg" alt="Tamaño"></a> &nbsp;
<a href="https://github.com/Ruraam/debup/releases"><img src="https://img.shields.io/github/downloads/Ruraam/debup/total?color=blueviolet"alt="Descargas Totales"></a>
</div>

<br/>

<div align="center">

<a href="README.md"><img src="https://api.iconify.design/circle-flags:gb.svg" width="16" height="16" alt="English" style="vertical-align: middle;"> English</a> &nbsp;•&nbsp;
<a href="README.fr.md"><img src="https://api.iconify.design/circle-flags:fr.svg" width="16" height="16" alt="Français" style="vertical-align: middle;"> Français</a> &nbsp;•&nbsp;
<a href="README.es.md"><img src="https://api.iconify.design/circle-flags:es.svg" width="16" height="16" alt="Español" style="vertical-align: middle;"> Español</a>

</div>

<div align="center">

| [Uso](https://github.com/Ruraam/debup/tree/main#%EF%B8%8F-usage) | [Token de GitHub](https://github.com/Ruraam/debup/blob/main/README.md#-configure-a-github-token-optionnal--dbp-token-) |[Buscar e Instalar](https://github.com/Ruraam/debup/tree/main#-discover-search--install-packages--dbp-search) | [Desinstalación](https://github.com/Ruraam/debup/tree/main#%EF%B8%8F-uninstallation) |
| :---: | :---: | :---: | :---: |
| [Configuración](https://github.com/Ruraam/debup/blob/main/README.md#%EF%B8%8F-configuration) | [Capturas de pantalla](https://github.com/Ruraam/debup/tree/main#screenshots) | [Registro de cambios](https://github.com/Ruraam/debup/releases) | [Licencia](LICENSE) |
</div>

---

## <img src="https://camo.githubusercontent.com/2d3f8510295d6086cf513dc08de9138bcab9ddfd73e45368011bee2a5a44bd84/68747470733a2f2f6170692e69636f6e6966792e64657369676e2f6c75636964653a7061636b6167652d636865636b2e7376673f636f6c6f723d2532336437306135332677696474683d313330266865696768743d313330" width="27"> debup [ `dbp` ] - El puente que faltaba entre GitHub y APT

¿Echas de menos la comodidad de AUR enDebian/Ubuntu? **debup** convierte GitHub Releases en tu repositorio personal de terceros estilo rolling-release.
**Descubre, inspecciona, instala y actualiza paquetes Debian directamente desde GitHub Releases con la simplicidad de `apt`.**

## ✨ Características principales
🔍 **Descubrir** [`dbp -s <consulta>`] :
* Encuentra herramientas y aplicaciones directamente en GitHub sin salirde tu terminal, prefiltradas para repositorios compatibles con Debian.
* Soporte para apuntar a versiones específicas durantela búsqueda e inspección: consulta y obtén etiquetas exactas directamente mediante el endpoint `/releases/tags/...` de la API de GitHub.

📦 **Añadir directo** [`dbp -a <propietario/repo>`]:
* Sin necesidad de buscar las URLs delanzamiento. Apunta a cualquier repositorio y debup detectará, comparará con tu arquitectura (`amd64` / `arm64`), descargará e instalará el paquete `.deb` correcto.
* Permite fijar versiones en la instalación: `dbp -a propietario/repo@vX.Y.Z`

ℹ️ **Inspeccionar** [`dbp -i <propietario/repo>`]:
* Previsualiza los metadatos antes de tocar tu sistema (estrellas, licencia, descripción, última versión, compatibilidad de arquitectura del archivo).

🔄 **Ciclo de vida nativo con APT**:
* Instala, actualiza[`dbp -u `] y desinstala [`dbp -r`] paquetes rastreados de forma transparente usando el motor nativo APT de tu sistema.

⚡ **Rastreo de API de alta tasa** [`dbp -t`]:
* Almacena de formasegura un token personal de GitHub (`chmod 600`) para desbloquear un límite de 5.000 peticiones/hora para búsquedas intensivas y comprobaciones automáticas de actualizaciones en segundo plano.

**Autocompletado nativo en Bash**:
* Soporte de autocompletado tanto para `debup` como para el alias `dbp`, con sugerencias dinámicas y contextuales de paquetes para `remove`, `pin` y `unpin`.

**🛡️ Fijación de paquetes** (`apt-mark hold`)
* **Congelar actualizaciones :** Bloquea paquetes específicos en su versión actual con el comando `pin` (o `hold`) para evitar actualizaciones no deseadas.
* **Descongelar actualizaciones :** Restaura las actualizaciones automáticas en cualquier momento con `unpin` (o `unhold`).
* **Integración nativa con APT :** Basado directamente en el mecanismo estándar `apt-mark` de Debian entre bastidores, garantizando una consistencia del 100% con las herramientas nativas del sistema.

## 🎯 Detección inteligente de archivos

`debup` selecciona automáticamente el binario `.deb` adecuado desde GitHub Releases sin margen de error:

***Arquitecturas flexibles:** Coincidencia con nombres estándar y alias:
* **x86_64:** `amd64`, `x86_64`, `x86-64`, `x64`, `all`
***ARM64:** `arm64`, `aarch64`, `armv8`, `arm64v8`, `all`
* **Protección entre arquitecturas :** Filtra activamente archivos incompatibles (por ejemplo, evita descargar `arm64` en equipos `amd64`).
* **Priorización de distribuciones :** Prefiere compilaciones específicas para la distro (`debian` vs `ubuntu`) cuando hay múltiples paquetes compatibles disponibles.
* **Respaldo seguro :** Cancela la ejecución limpiamente con una advertencia explícita si no existe ningún paquete compatible con la arquitectura de tu procesador.

---

## 📦 Instalación

### ⚡ Instalación Rápida Interactiva / No Interactiva
**Instalador Zero-Trust:** Cuenta con validación estricta de huella GPG (fail-closed), verificación de integridad SHA-256 y soporte completo para instalación interactiva o desatendida sin intervención (`-y` / CI/CD).

Ejecuta el asistente interactivo para elegir tu método preferido (Repositorio APT, Última Release o Compilación desde fuentes):
```bash
curl -sSL https://raw.githubusercontent.com/Ruraam/debup/main/install.sh | bash
```
&nbsp; 

Usa la opción `-y` para una instalación totalmente automatizada (instala el repositorio oficial APT por defecto sin confirmaciones):
```bash
curl -sSLhttps://raw.githubusercontent.com/Ruraam/debup/main/install.sh | bash -s -- -y
```
<div align="center">
<img src="assets/installer_menu1.jpg" width="200">

</div>

---

### 🔑 Configurar un Token de GitHub (opcional) [ `dbp -t` ]

Por defecto, GitHub limita las solicitudes anónimas a 60 peticiones/hora. Añadir un token eleva este límite a5.000 peticiones/hora.

**1. Generar un token:**
Ve a GitHub > Settings > Developer settings >Personal access tokens > Tokens (classic) > Generate new token (no se requieren alcances/permisos, deja todo sin marcar).

**2.Vincularlo a debup:**

dbp -t <token>

Pega tu token y confirma. ¡Esoes todo!

`debup` lo detectará y utilizará automáticamente, aumentando tu límite a 5.000 peticiones por hora.

> ***🔒 Nota de seguridad:** Tu token se almacena de forma segura en `/etc/debup/debup.conf` con permisos restringidos (`chmod 600`), asegurando que solo el usuario root pueda leerlo.*

---

##🛠️ Uso

### Gestión de paquetes
**Añadir un repositorio para instalar el `.deb` y rastrearlo:**
```bash
dbp -a <propietario>/<repo>por 
```
ejemplo:[ `dbp -a Ruraam/Uraam` ]

**Listar repositorios rastreados**
```bash
dbp -l
```
**Eliminar un repositorio rastreado**
```bash
dbp -r <nombre-del-paquete>
```
**Evitar que una aplicación se actualice**
```bash
dbp -p <nombre-del-paquete>**
```
Permitir nuevamente las actualizaciones de una aplicación**
```bash
dbp -n <nombre-del-paquete>
```

### Actualizaciones de paquetes
**Descargar y actualizar los paquetes rastreados conconfirmación (con y sin repositorio APT)**
```bash
dbp -u [-y]**
```
Actualizar debup a través del repositorioAPT:**
```bash
sudo apt update && sudo apt upgrade debup
```
### 🔍 Descubrir, Buscar e Instalar Paquetes [ `dbp search`]

Encuentra y descubre cualquier proyecto de GitHub que proporcione paquetes .deb compatiblescon tu arquitectura e instálalos con un solo clic:
Buscar información sobre un repositorio
```bash
dbp-i <propietario>/<repo> 
```
**Ejemplo:** [ `dbp -i Ruraam/Uraam` ]
```bash
dbp -s <palabra-clave>
```
**Ejemplo:** [ `dbp -s uraam` ]

**Cómo funciona:**

Introduce el número de paquete de la lista y pulsa Enter. debup descarga el archivo.deb correspondiente, lo instala a través de apt y lo añade automáticamente a tu lista de seguimiento para futuras actualizaciones.

<p align="center">
<img src="/assets/debup_search1.png" width="200"> <img src="/assets/debup_search2.png" width="200"> <img src="/assets/debup_search3.png" width="200"></p>

---

## Alias cortos de la CLI:Opciones estándar POSIX de una sola letra para flujos de trabajo optimizados en la terminal:

[-a|add : añadir / instalar] [-u|upgrade : actualizar / upgrade] [-r|remove : eliminar] [-p|pin : fijar / pin][-n|unpin : desfijar / unpin] [-s|search : buscar] [-i|info : información / mostrar] [-l|list : listar] [-t|token : token / auth]

>|
>**💡 Consejo:** Combina repositorios oficiales y lanzamientos de GitHub creando un alias con `sudo apt update && sudo apt upgrade-y && dbp upgrade` en tu `~/.bashrc`.
>|

---

## ⚙️ Configuración

**Las fuentes rastreadas se almacenan en:** [ `/etc/debup/sources.list` ]

**Formato:** [ `<nombre-del-paquete>|<usuario-github>/<repo-github>` ]

**El Tokende GitHub se almacena en:** [ `/etc/debup/debup.conf` ]

---

## 🗑️ Desinstalación
**Eliminar paquete**
```bash
dbp -r debup [-y]
```
Sete preguntará si deseas purgar la configuración o no.

o
```bash
sudo apt remove debup[-y]**
```
Eliminar paquete y limpiar configuración**
```bash
sudo apt --purge debup [-y]
```

---

## Capturas de pantalla
<p align="center">
<img src="/assets/debup_1.png" width="400"> <img src="/assets/debup_2.png"width="400"> <img src="/assets/debup3.png" width="400"> <img src="/assets/debup4.png" width="400"></p>

---

## 📄 Licencia

Este proyectoestá bajo la licencia [GNU General Public License v3.0](LICENSE).

---
> Cómo instalar paquetes .deb descargados de GitHub en sistemas basados ​​en Debian o Ubuntu
>
> > Cómo actualizar automáticamente paquetes .deb descargados de GitHub en sistemas basados ​​en Debian o Ubuntu
