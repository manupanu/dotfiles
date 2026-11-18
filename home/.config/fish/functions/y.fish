# Yazi wrapper: changes the current directory to Yazi's last visited directory.
function y
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    command yazi $argv --cwd-file=$tmp
    if read -z cwd <$tmp; and test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- $cwd
    end
    command rm -f -- $tmp
end
