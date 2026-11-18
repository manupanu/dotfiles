# Keep noisy commands out of history.
function fish_should_add_to_history
    string match -qr '^\s' -- $argv; and return 1
    switch (string trim -- $argv)
        case '&' bg fg c clear history exit q pwd '* --help'
            return 1
    end
    return 0
end
