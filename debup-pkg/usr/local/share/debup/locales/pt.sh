#!/usr/bin/env bash

# General
MSG_ENTER_PAT="Insira seu GitHub Personal Access Token (PAT):"
MSG_ERR_EMPTY_TOKEN="[X] Erro: O token não pode estar vazio."
MSG_TOKEN_SUCCESS="[✓] GITHUB_TOKEN configurado com sucesso!"

# check_and_update
MSG_PINNED_SKIPPED="[FIXADO] O pacote %s está retido. Ignorando atualização."
MSG_ERR_FETCH_RELEASE="[X] Erro: Não foi possível obter informações do release para %s"
MSG_ERR_GH_API="[X] Resposta da API do GitHub: %s"
MSG_PACKAGE_HEADER="==> Pacote:"
MSG_NEW_PACKAGE="Novo pacote"
MSG_NOT_INSTALLED="Não instalado"
MSG_LATEST_VERSION="Última versão:   %s"
MSG_ALREADY_UP_TO_DATE="[✓] O pacote já está na versão mais recente!"
MSG_ERR_NO_COMPAT_DEB="[X] Erro: Nenhum arquivo .deb compatível encontrado para a arquitetura (%s)."
MSG_DRY_WOULD_DOWNLOAD="[SIMULAÇÃO] Baixaria: %s"
MSG_DRY_WOULD_INSTALL="[SIMULAÇÃO] Instalaria e monitoraria: %s (%s)"
MSG_PROMPT_CONFIRM_INSTALL="[?] Deseja baixar e instalar? [s/N]: "
MSG_OP_CANCELED="[X] Operação cancelada."
MSG_DOWNLOADING="[*] Baixando: %s"
MSG_ERR_DOWNLOAD_FAILED="[X] Falha no download."
MSG_INSTALLING_PKG="[*] Instalando pacote (sudo necessário)..."
MSG_SUCCESS_INSTALLED="[✓] %s (%s) instalado/atualizado com sucesso!"
MSG_ERR_INSTALL_FAILED="[X] Falha na instalação."

# debup_search
MSG_USAGE_SEARCH="[!] Erro: Uso: dbp -s|search <nome_da_ferramenta>"
MSG_SEARCHING_GH=":: Buscando '%s' no GitHub..."
MSG_NO_REPOS_FOUND="[!] Nenhum repositório encontrado para '%s'."
MSG_VERIFYING_DEBS=":: Verificando releasescom .deb para os candidatos..."
MSG_NO_DESC="Nenhuma descrição fornecida"
MSG_NO_DEB_IN_REPOS="[!] Repositórios encontrados para '%s', mas nenhum possui releases .deb."
MSG_REPOS_FOUND_HEADER="Repositórios encontrados com releases .deb:"
MSG_PROMPT_SELECT_PKG="Selecione um pacote para instalar [1-%d] (Pressione Enter para cancelar): "
MSG_INSPECTING_ASSETS=":: Inspecionando arquivos do último release para %s..."
MSG_ERR_NO_DEB_IN_RELEASE="[X] Erro: Nenhum pacote .deb encontrado no último release deste repositório."
MSG_CANNOT_INSTALL="Não é possível instalar via debup."
MSG_WARN_NO_ARCH_MATCH="[!] Aviso: Pacotes .deb existem, mas nenhum parece corresponder à sua arquitetura (%s)."
MSG_PROMPT_FORCE_INSTALL="Ainda deseja prosseguir com a instalação? [s/N]: "
MSG_INSTALL_CANCELED="Instalação cancelada."
MSG_COMPAT_PKG_DETECTED="[✓] Pacote compatível detectado. Adicionando repositório..."

# debup_info
MSG_USAGE_INFO="[!] Erro: Uso: dbp -i|nfo <proprietario/repo>"
MSG_FETCHING_METADATA=":: Obtendo metadados para %s..."
MSG_ERR_REPO_NOT_FOUND="[X] Erro: Repositório '%s' não encontradono GitHub."
MSG_WARN_NO_RELEASES="[!] O repositório existe, mas não possui releases publicados."
MSG_INFO_NO_DESC="Nenhuma descrição fornecida."
MSG_INFO_NONE="Nenhum"
MSG_INFO_PKG="Pacote:"
MSG_INFO_LATEST="Último:"
MSG_INFO_STARS="Estrelas:"
MSG_INFO_LICENSE="Licença:"
MSG_INFO_DESC="Descrição:"
MSG_INFO_COMPAT_DEBS="Compatível .deb (%s):"
MSG_WARN_NO_ARCH_DEBS="[!] .deb encontrado, mas NENHUM corresponde à sua arquitetura (%s):"
MSG_ERR_NO_DEB_IN_REL="[X] Nenhum pacote .deb encontrado neste release."

# case / CLI Commands
MSG_USAGE_ADD="Uso: dbp -a|add[-y] <proprietario/repo | url_github>"
MSG_NO_TRACKED_PACKAGES="[!]Nenhum pacote gerenciado pelo debup ainda."
MSG_DRY_UPGRADE_SUMMARY="[SIMULAÇÃO] %d pacote(s) seriam atualizados de %d."
MSG_UPGRADE_SUMMARY="[✓] Concluído! %d pacote(s) atualizados de %d."
MSG_NO_PKGS_REGISTERED="[!] Nenhum pacote registrado."

# list
MSG_COL_PACKAGE="PACOTE"
MSG_COL_REPO="REPOSITÓRIO"
MSG_COL_STATUS="STATUS"
MSG_STATUS_ACTIVE="ativo"
MSG_STATUS_PINNED="fixado"

# remove
MSG_USAGE_REMOVE="[!]Uso: dbp -r|remove [-d|--dry-run] <nome_do_pacote>"
MSG_DRY_REMOVE_TRACK="[SIMULAÇÃO] Removeria %s do monitoramento (%s)."
MSG_DRY_REMOVE_APT="[SIMULAÇÃO] Executaria: sudo apt-get remove --purge -y %s"
MSG_REMOVE_TRACK_SUCCESS="[✓] %s removido do monitoramento do debup."
MSG_PROMPT_PURGE_APT="Deseja também purgar o pacote do sistema usando o apt? [s/N]: "

# pin / unpin
MSG_USAGE_PIN="[!] Uso: dbp -p|pin <nome_do_pacote>"
MSG_DRY_PIN="[SIMULAÇÃO] Executaria: sudo apt-mark hold%s"
MSG_PIN_SUCCESS="[✓] %s fixado com sucesso (atualizações bloqueadas)."
MSG_USAGE_UNPIN="[!] Uso: dbp -n|unpin <nome_do_pacote>"
MSG_DRY_UNPIN="[SIMULAÇÃO] Executaria: sudo apt-mark unhold %s"
MSG_UNPIN_SUCCESS="[✓] %s liberado com sucesso(atualizações permitidas)."

# Help / Usage
MSG_HELP_SEC_PKG="Operações de pacotes:"
MSG_HELP_ADD="Instalar pacote a partir de repo ou URL"
MSG_HELP_UPGRADE="Atualizar todos os pacotes monitorados"
MSG_HELP_REMOVE="Desmonitorar (e opcionalmente purgar) um pacote"
MSG_HELP_PIN="Bloquear ou desbloquear versão do pacote"

MSG_HELP_SEC_DISCOVERY="Descoberta e Informações:"
MSG_HELP_SEARCH="Buscar repositórios interativamente"
MSG_HELP_INFO="Exibir metadados do pacote e da arquitetura"
MSG_HELP_LIST="Listar pacotes monitorados e status"

MSG_HELP_SEC_CONFIG="Configuração:"
MSG_HELP_AUTH="Definir GitHub Personal Access Token"

MSG_HELP_SEC_OPTIONS="Opções:"
MSG_HELP_DRY="Simular operações sem fazer alterações"
MSG_HELP_HELP="Exibir esta mensagem de ajuda"

# Default fallback
MSG_ERR_UNKNOWN_CMD="[X] Comando desconhecido: %s"
MSG_RUN_HELP_HINT="Execute '%s' para instruções de uso."