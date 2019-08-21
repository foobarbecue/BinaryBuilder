#!/bin/sh

self=$$
trap 'exit 1' TERM

TOPLEVEL="$(cd $(dirname $0)/.. && pwd)"
LIBEXEC="${ASP_DEBUG_DIR:-${TOPLEVEL}/libexec}"
export ISISROOT=$TOPLEVEL

. "${LIBEXEC}/constants.sh"
. "${LIBEXEC}/libexec-funcs.sh"

check_isis
if [ "$(uname -s)" = "Linux" ]
then
    check_libc
fi

PROGRAM="${LIBEXEC}/$(basename $0)"

# Path to USGS CSM plugins
export CSM_PLUGIN_PATH="${TOPLEVEL}/plugins/usgscsm"

if [ "$(echo $PROGRAM | grep sparse_disp)" != "" ] &&
    [ "$ASP_PYTHON_MODULES_PATH" != "" ]; then
    # For sparse_disp we must not use ASP's libraries,
    # as those don't play well with Python
    export PYTHONPATH="$ASP_PYTHON_MODULES_PATH"
    case $(uname -s) in
        Linux)
        export LD_LIBRARY_PATH="$ASP_PYTHON_MODULES_PATH"
        ;;
        Darwin)
        export DYLD_FALLBACK_LIBRARY_PATH="$ASP_PYTHON_MODULES_PATH"
        export DYLD_FALLBACK_FRAMEWORK_PATH="$ASP_PYTHON_MODULES_PATH"
        ;;
        *)
        die "Unknown OS: $(uname -s)"
        ;;
    esac
else
    set_lib_paths "${TOPLEVEL}/lib"
fi

# Needed for stereo_gui to start quickly.  (Likely the conda Qt
# libraries have some misconfigured path).
if [ "$(echo $PROGRAM | grep stereo_gui)" != "" ] && [ -f "/etc/fonts/fonts.conf" ]; then 
    export FONTCONFIG_PATH=/etc/fonts
    export FONTCONFIG_FILE=fonts.conf
fi

if ! test -f "${PROGRAM}"; then
    msg "Could not find ${PROGRAM}"
    die "Is your Stereo Pipeline install incomplete?"
fi
exec "${PROGRAM}" "$@"
