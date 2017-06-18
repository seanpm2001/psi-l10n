#!/bin/sh

# Author:  Boris Pek <tehnick-8@yandex.ru>
# License: GPLv2 or later
# Created: 2017-06-16
# Updated: 2017-06-18
# Version: N/A

set -e

export CUR_DIR="$(dirname $(realpath -s ${0}))"
export MAIN_DIR="${CUR_DIR}/.."
export PSI_DIR="${MAIN_DIR}/psi"
export PLUGINS_DIR="${MAIN_DIR}/plugins"
export PSIPLUS_L10N_DIR="${MAIN_DIR}/psi-plus-l10n"

cd "${CUR_DIR}"

case "${1}" in
"up")
    # Pulling changes from GitHub repo.

    git pull --all

;;
"cm")
    # Creating correct git commit.

    git commit -a -m 'Sync translations with Psi+ project.'

;;
"tag")
    # Creating correct git tag.

    PSI_TAG="1.0.1"
    DEF_COMMIT=2812a0af876f47b9001fcd3a4af9ad89e2ccb1ea

    PSI_HASH="$(cd ${PSI_DIR} && git show -s --pretty='format:%h')"
    PSI_NUM="$(cd ${PSI_DIR} && git rev-list --count ${DEF_COMMIT}..HEAD)"

    CUR_TAG="${PSI_TAG}.${PSI_NUM}-${PSI_HASH}"

    cd "${CUR_DIR}"
    echo "git tag \"${CUR_TAG}\""
    git tag "${CUR_TAG}"

    echo ;
    echo "Last tags:"
    git tag | sort -V | tail -n10

;;
"push")
    # Pushing changes into GitHub repo.

    git push
    git push --tags

;;
"make")
    # Making precompiled localization files.

    rm translations.pro

    echo "TRANSLATIONS = \\" >> translations.pro
    echo translations/*.ts >> translations.pro

    lrelease ./translations.pro

    mkdir -p out
    mv translations/*.qm out/

;;
"install")
    # Installing precompiled localization files into default directory.

    if [ ${USER} != "root" ]; then
        echo "You are not a root now!"
        exit 1
    fi

    mkdir -p /usr/share/psi/translations/
    cp out/*.qm /usr/share/psi/translations/

;;
"tarball")
    # Generating tarball with precompiled localization files.

    CUR_TAG="$(git tag -l  | sort -r -V | head -n1)"

    rm -rf psi-translations-*
    mkdir psi-translations-${CUR_TAG}
    cp out/*.qm psi-translations-${CUR_TAG}

    tar -cJf psi-translations-${CUR_TAG}.tar.xz psi-translations-${CUR_TAG}
    echo "Tarball with precompiled translation files is ready for upload:"
    [ ! -z "$(which realpath)" ] && echo "$(realpath ${CUR_DIR}/psi-translations-${CUR_TAG}.tar.xz)"
    echo "https://sourceforge.net/projects/psi/files/Translations/"

;;
"tr")
    # Pulling updates from Psi+ project.

    # Test Internet connection:
    host github.com > /dev/null

    git status

    if [ -d "${PSIPLUS_L10N_DIR}" ]; then
        echo "Updating ${PSIPLUS_L10N_DIR}"
        cd "${PSIPLUS_L10N_DIR}"
        git pull --all --prune
        echo;
    else
        echo "Creating ${PSIPLUS_L10N_DIR}"
        cd "${MAIN_DIR}"
        git clone https://github.com/psi-plus/psi-plus-l10n.git
        echo;
    fi

    cp -a "${PSIPLUS_L10N_DIR}/translations"/*.ts "${CUR_DIR}/translations/"
    cp -a "${PSIPLUS_L10N_DIR}/desktop-file"/*.desktop "${CUR_DIR}/desktop-file/"

    cp -a "${PSIPLUS_L10N_DIR}/AUTHORS" "${CUR_DIR}/"
    cp -a "${PSIPLUS_L10N_DIR}/COPYING" "${CUR_DIR}/"

    # find "${CUR_DIR}/translations/" -type f -exec sed -i "s|Psi+|Psi|g" {} \;
    find "${CUR_DIR}/desktop-file/" -type f -exec sed -i "s|Psi+|Psi|g" {} \;
    find "${CUR_DIR}/desktop-file/" -type f -exec sed -i "s|Psi-plus|Psi|g" {} \;
    find "${CUR_DIR}/desktop-file/" -type f -exec sed -i "s|psi-plus|psi|g" {} \;

    cd "${CUR_DIR}"
    git status

;;
"tr_up")
    # Full update of localization files.

    git status

    if [ -d "${PSI_DIR}" ]; then
        echo "Updating ${PSI_DIR}"
        cd "${PSI_DIR}"
        git pull --all --prune
        git submodule init
        git submodule update
        echo;
    else
        echo "Creating ${PSI_DIR}"
        cd "${MAIN_DIR}"
        git clone https://github.com/psi-im/psi.git
        cd "${PSI_DIR}"
        git submodule init
        git submodule update
        echo;
    fi

    if [ -d "${PLUGINS_DIR}" ]; then
        echo "Updating ${PLUGINS_DIR}"
        cd "${PLUGINS_DIR}"
        git pull --all --prune
        echo;
    else
        echo "Creating ${PLUGINS_DIR}"
        cd "${MAIN_DIR}"
        git clone https://github.com/psi-im/plugins.git
        echo;
    fi

    # beginning of magical hack
    cd "${CUR_DIR}"
    rm -fr tmp
    mkdir tmp
    cd tmp/

    mkdir src
    mkdir src/plugins
    cp -a "${PLUGINS_DIR}"/* "src/plugins/"

    cd "${PSI_DIR}/src"
    python ../admin/update_options_ts.py ../options/default.xml > \
        "${CUR_DIR}/tmp/option_translations.cpp"
    # ending of magical hack

    cd "${CUR_DIR}"
    rm translations.pro

    echo "HEADERS = \\" >> translations.pro
    find "${PSI_DIR}/iris" "${PSI_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.h" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done

    echo "SOURCES = \\" >> translations.pro
    find "${PSI_DIR}/iris" "${PSI_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.cpp" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ${CUR_DIR}/tmp/*.cpp" >> translations.pro

    echo "FORMS = \\" >> translations.pro
    find "${PSI_DIR}/iris" "${PSI_DIR}/src" "${CUR_DIR}/tmp" -type f -name "*.ui" | \
        while read var; do echo "  ${var} \\" >> translations.pro; done
    echo "  ${CUR_DIR}/tmp/*.ui" >> translations.pro

    echo "TRANSLATIONS = \\" >> translations.pro
    echo translations/*.ts >> translations.pro

    lupdate -verbose ./translations.pro

    cp "${PSI_DIR}"/*.desktop "${CUR_DIR}/desktop-file/"

    git status

;;
"tr_fu")
    # Fast update of localization files.

    git status

    lupdate -verbose ./translations.pro

    cp "${PSI_DIR}"/*.desktop "${CUR_DIR}/desktop-file/"

    git status

;;
"tr_cl")
    # Cleaning update of localization files.

    git status

    lupdate -verbose -no-obsolete ./translations.pro

    cp "${PSI_DIR}"/*.desktop "${CUR_DIR}/desktop-file/"

    git status

;;
"tr_sync")
    # Syncing of Guthub repos.

    "${0}" tr
    "${0}" tr_up

    if [ "$(git status | grep 'translations/' | wc -l)" -gt 0 ]; then
        "${0}" cm
    fi
    echo ;
;;
*)
    # Help.

    echo "Usage:"
    echo "  up cm tag push make install tarball"
    echo "  tr tr_up tr_fu tr_cl tr_co tr_sync"
    echo ;
    echo "Examples:"
    echo "  ./update-translations.sh tr"
    echo "  ./update-translations.sh tr_up"
    echo "  ./update-translations.sh cm"
    echo "  ./update-translations.sh push"
    echo "  or"
    echo "  ./update-translations.sh tr_sync"
    echo "  ./update-translations.sh push"

;;
esac

exit 0
