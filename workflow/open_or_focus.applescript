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
    -- First pass: find the matching window+tab without touching focus.
    -- Capture the window's title too — System Events needs it to raise
    -- across Spaces (AppleScript window ids aren't visible to AX).
    set matchWinId to missing value
    set matchTabIndex to 0
    set matchWinName to ""
    tell application "Google Chrome"
        repeat with w in windows
            set tabIndex to 0
            repeat with t in tabs of w
                set tabIndex to tabIndex + 1
                if (URL of t) starts with targetURL then
                    set matchWinId to id of w
                    set matchTabIndex to tabIndex
                    -- Select the tab now so the window's title updates
                    -- to reflect it before we read the title.
                    set active tab index of w to tabIndex
                    set matchWinName to title of w
                    exit repeat
                end if
            end repeat
            if matchWinId is not missing value then exit repeat
        end repeat
    end tell

    if matchWinId is missing value then return false

    -- Activate Chrome, then raise the specific window. On a single Space
    -- the Chrome-dictionary `index` reorder is enough; across Spaces we
    -- need System Events AXRaise to switch Spaces. AXRaise requires
    -- Accessibility permission for whatever runs this script (Alfred /
    -- osascript); if it's not granted the call errors and we fall back
    -- to the in-app reorder, which at least focuses Chrome correctly.
    tell application "Google Chrome"
        activate
        set targetWin to first window whose id is matchWinId
        set index of targetWin to 1
    end tell

    try
        tell application "System Events"
            tell process "Google Chrome"
                perform action "AXRaise" of (first window whose title is matchWinName)
            end tell
        end tell
    end try

    return true
end focusChromeTab

on focusSafariTab(targetURL)
    set matchWinId to missing value
    set matchTab to missing value
    set matchWinName to ""
    tell application "Safari"
        repeat with w in windows
            repeat with t in tabs of w
                if (URL of t) starts with targetURL then
                    set matchWinId to id of w
                    set matchTab to t
                    set current tab of w to t
                    set matchWinName to name of w
                    exit repeat
                end if
            end repeat
            if matchWinId is not missing value then exit repeat
        end repeat
    end tell

    if matchWinId is missing value then return false

    tell application "Safari"
        activate
        set targetWin to first window whose id is matchWinId
        set index of targetWin to 1
    end tell

    try
        tell application "System Events"
            tell process "Safari"
                perform action "AXRaise" of (first window whose title is matchWinName)
            end tell
        end tell
    end try

    return true
end focusSafariTab
