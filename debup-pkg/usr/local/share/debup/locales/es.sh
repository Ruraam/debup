#!/usr/bin/env bash

# General
MSG_ENTER_PAT="Introduce tu token de acceso personal de GitHub (PAT):"
MSG_ERR_EMPTY_TOKEN="[X] Error: El token no puede estar vacío."
MSG_TOKEN_SUCCESS="[✓] ¡GITHUB_TOKEN configurado correctamente!"

# check_and_update
MSG_PINNED_SKIPPED="[FIJADO] El paquete %s está bloqueado (held). Omitiendo actualización."
MSG_ERR_FETCH_RELEASE="[X] Error: No se pudo obtener la información del release para %s"
MSG_ERR_GH_API="[X] Respuesta de la API de GitHub:%s"
MSG_PACKAGE_HEADER="==> Paquete:"
MSG_NEW_PACKAGE="Nuevo paquete"
MSG_NOT_INSTALLED="No instalado"
MSG_LATEST_VERSION="Última versión:  %s"
MSG_ALREADY_UP_TO_DATE="[✓] ¡El paquete ya está actualizado!"
MSG_ERR_NO_COMPAT_DEB="[X]Error: No se encontró ningún archivo .deb compatible con la arquitectura (%s)."
MSG_DRY_WOULD_DOWNLOAD="[DRY-RUN] Descargaría: %s"
MSG_DRY_WOULD_INSTALL="[DRY-RUN] Instalaría y rastrearía: %s (%s)"
MSG_PROMPT_CONFIRM_INSTALL="[?] ¿Deseas descargarlo e instalarlo? [s/N]:"
MSG_OP_CANCELED="[X] Operación cancelada."
MSG_DOWNLOADING="[*] Descargando: %s"
MSG_ERR_DOWNLOAD_FAILED="[X] Falló la descarga."
MSG_INSTALLING_PKG="[*] Instalando paquete (se requiere sudo)..."
MSG_SUCCESS_INSTALLED="[✓] ¡%s (%s) instalado/actualizado correctamente!"
MSG_ERR_INSTALL_FAILED="[X]Falló la instalación."

# debup_search
MSG_USAGE_SEARCH="[!] Error: Uso: dbp -s|search <nombre_herramienta>"
MSG_SEARCHING_GH=":: Buscando '%s' en GitHub..."
MSG_NO_REPOS_FOUND="[!] No se encontraron repositorios para '%s'."
MSG_VERIFYING_DEBS=":: Verificando releases con .deb para los candidatos..."
MSG_NO_DESC="Sin descripción proporcionada"
MSG_NO_DEB_IN_REPOS="[!] Se encontraron repositorios para'%s', pero ninguno contiene archivos .deb."
MSG_REPOS_FOUND_HEADER="Repositorios encontrados con paquetes .deb:"
MSG_PROMPT_SELECT_PKG="Selecciona un paquete para instalar [1-%d] (Presiona Enter para cancelar): "
MSG_INSPECTING_ASSETS=":: Inspeccionando archivos del último release para%s..."
MSG_ERR_NO_DEB_IN_RELEASE="[X] Error: No se encontraron paquetes .deb enel último release de este repositorio."
MSG_CANNOT_INSTALL="No se puede instalar mediante debup."
MSG_WARN_NO_ARCH_MATCH="[!] Advertencia: Existen paquetes .deb, pero ninguno parece coincidir con tu arquitectura (%s)."
MSG_PROMPT_FORCE_INSTALL="¿Aún deseas continuar con la instalación? [s/N]: "
MSG_INSTALL_CANCELED="Instalación cancelada."
MSG_COMPAT_PKG_DETECTED="[✓] Paquete compatible detectado. Añadiendo repositorio..."

# debup_info
MSG_USAGE_INFO="[!] Error: Uso: dbp -i|info <propietario/repositorio>"
MSG_FETCHING_METADATA=":: Obteniendo metadatos para %s..."
MSG_ERR_REPO_NOT_FOUND="[X] Error: Repositorio '%s' no encontrado en GitHub."
MSG_WARN_NO_RELEASES="[!] El repositorio existe, pero no tiene releases publicados."
MSG_INFO_NO_DESC="Sin descripción proporcionada."
MSG_INFO_NONE="Ninguna"
MSG_INFO_PKG="Paquete:"
MSG_INFO_LATEST="Última:"
MSG_INFO_STARS="Estrellas:"
MSG_INFO_LICENSE="Licencia:"
MSG_INFO_DESC="Descripción:"
MSG_INFO_COMPAT_DEBS="Archivos .deb compatibles (%s):"
MSG_WARN_NO_ARCH_DEBS="[!] Se encontraron archivos .deb, pero NINGUNO coincide con tu arquitectura(%s):"
MSG_ERR_NO_DEB_IN_REL="[X] No se encontraronpaquetes .deb en este release."

# case / CLI Commands
MSG_USAGE_ADD="Uso: dbp -a|add [-y] <propietario/repositorio | url_github>"
MSG_NO_TRACKED_PACKAGES="[!] Todavía no hay paquetes gestionados por debup."
MSG_DRY_UPGRADE_SUMMARY="[DRY-RUN] Se actualizarían %d paquete(s) de %d."
MSG_UPGRADE_SUMMARY="[✓] ¡Listo! Se actualizaron %d paquete(s) de %d."
MSG_NO_PKGS_REGISTERED="[!] No hay paquetes registrados."

# list
MSG_COL_PACKAGE="PAQUETE"
MSG_COL_REPO="REPOSITORIO"
MSG_COL_STATUS="ESTADO"
MSG_STATUS_ACTIVE="activo"
MSG_STATUS_PINNED="fijado"

# remove
MSG_USAGE_REMOVE="[!] Uso: dbp -r|remove [-d|--dry-run] <nombre_paquete>"
MSG_DRY_REMOVE_TRACK="[DRY-RUN] Eliminaría %s del rastreo (%s)."
MSG_DRY_REMOVE_APT="[DRY-RUN] Ejecutaría:sudo apt-get remove --purge -y %s"
MSG_REMOVE_TRACK_SUCCESS="[✓]%s eliminado del rastreo de debup."
MSG_PROMPT_PURGE_APT="¿Deseas purgar tambiénel paquete del sistema usando apt? [s/N]: "

# pin / unpin
MSG_USAGE_PIN="[!] Uso: dbp -p|pin <nombre_paquete>"
MSG_DRY_PIN="[DRY-RUN] Ejecutaría: sudo apt-mark hold %s"
MSG_PIN_SUCCESS="[✓] %s fijado correctamente (actualizaciones bloqueadas)."
MSG_USAGE_UNPIN="[!] Uso: dbp -n|unpin <nombre_paquete>"
MSG_DRY_UNPIN="[DRY-RUN] Ejecutaría: sudo apt-mark unhold %s"
MSG_UNPIN_SUCCESS="[✓] %s desfijado correctamente (actualizaciones permitidas)."

# Help / Usage
MSG_HELP_SEC_PKG="Operaciones de paquetes:"
MSG_HELP_ADD="Instalar paquete desde repositorio o URL"
MSG_HELP_UPGRADE="Actualizar todos los paquetes rastreados"
MSG_HELP_REMOVE="Dejar derastrear (y opcionalmente purgar) un paquete"
MSG_HELP_PIN="Bloquear o desbloquear la versión deun paquete"

MSG_HELP_SEC_DISCOVERY="Búsqueda e Información:"
MSG_HELP_SEARCH="Buscar repositorios deforma interactiva"
MSG_HELP_INFO="Mostrar metadatos del paquete y arquitectura"
MSG_HELP_LIST="Listar paquetes rastreados y su estado"

MSG_HELP_SEC_CONFIG="Configuración:"
MSG_HELP_AUTH="Establecer token de acceso personal de GitHub"

MSG_HELP_SEC_OPTIONS="Opciones:"
MSG_HELP_DRY="Simular operaciones sin aplicar cambios"
MSG_HELP_HELP="Mostrar este mensaje de ayuda"

# Default fallback
MSG_ERR_UNKNOWN_CMD="[X] Comando desconocido: %s"
MSG_RUN_HELP_HINT="Ejecuta '%s' para ver las instrucciones de uso."