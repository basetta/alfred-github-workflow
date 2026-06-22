on run argv
    set targetURL to item 1 of argv
    -- Always open in the user's default browser on the CURRENT Space.
    -- `open location` routes through LaunchServices, which opens a new
    -- tab in an existing browser window on the current Space when one
    -- exists, and otherwise creates a new window here. We deliberately
    -- do NOT search for an existing tab on another Space and switch to
    -- it — the user wants the repo to land where they currently are.
    open location targetURL
end run
