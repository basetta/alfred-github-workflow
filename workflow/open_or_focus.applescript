on run argv
    set targetURL to item 1 of argv
    set focused to false

    -- Try Chrome first (user mentioned Chrome is current default)
    if appIsRunning("Google Chrome") then
        set focused to focusChromeTab(targetURL)
    end if

    -- Try Safari if not yet focused
    if not focused and appIsRunning("Safari") then
        set focused to focusSafariTab(targetURL)
    end if

    -- Fall back to system default browser
    if not focused then
        open location targetURL
    end if
end run

on appIsRunning(appName)
    tell application "System Events" to (name of processes) contains appName
end appIsRunning

on focusChromeTab(targetURL)
    tell application "Google Chrome"
        set winIndex to 0
        repeat with w in windows
            set winIndex to winIndex + 1
            set tabIndex to 0
            repeat with t in tabs of w
                set tabIndex to tabIndex + 1
                if (URL of t) starts with targetURL then
                    set active tab index of w to tabIndex
                    set index of w to 1
                    activate
                    return true
                end if
            end repeat
        end repeat
    end tell
    return false
end focusChromeTab

on focusSafariTab(targetURL)
    tell application "Safari"
        repeat with w in windows
            repeat with t in tabs of w
                if (URL of t) starts with targetURL then
                    set current tab of w to t
                    set index of w to 1
                    activate
                    return true
                end if
            end repeat
        end repeat
    end tell
    return false
end focusSafariTab
