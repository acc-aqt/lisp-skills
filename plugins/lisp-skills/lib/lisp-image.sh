# Sourced by bin/lisp-image and bin/lisp-eval, after they set $name.
# Sets lisp, lib, project and state (the directory holding the image's pid,
# port and log), and provides give_up and running.
#
# There is one image per project: the git repository around the current
# directory, or the current directory outside one. LISP_IMAGE_DIR overrides
# the state directory.

lisp=${LISP_BIN:-alisp}
lib=$(cd "$(dirname "$0")/../lib" && pwd)
project=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
state=${LISP_IMAGE_DIR:-${TMPDIR:-/tmp}/lisp-image-$(id -u)-$(printf '%s' "$project" | cksum | cut -d ' ' -f 1)}

give_up() {
    echo "$name: $1"
    echo FAIL
    exit 2
}

# running: true if the image is up; sets pid and port.
running() {
    pid=$(cat "$state/pid" 2>/dev/null) && port=$(cat "$state/port" 2>/dev/null) \
        && [ -n "$pid" ] && [ -n "$port" ] && kill -0 "$pid" 2>/dev/null
}
