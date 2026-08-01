# versions.sh - shared version/prefix constants, sourced by both install.sh
# and zsh/.zshenv so the two can't drift out of sync. Plain variable
# assignments only, valid under both bash and zsh.

QT_VERSION="6.7.2"
QT_PREFIX="$HOME/Qt/${QT_VERSION}-core"

CCACHE_MAXSIZE="40G"
