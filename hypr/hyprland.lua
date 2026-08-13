-- Live Hyprland config. Home Manager links this file out-of-store to
-- ~/.config/hypr/hyprland.lua so Hyprland can reload changes on save.

local main_mod = "SUPER"
local secondary = "SHIFT"
local tertiary = "CTRL"

local function mods(keys)
    return table.concat(keys, " + ")
end

local function key(modifiers, key_name)
    if modifiers == "" then
        return key_name
    end

    return modifiers .. " + " .. key_name
end

local main_shift = mods({ main_mod, secondary })
local main_ctrl = mods({ main_mod, tertiary })
local main_alt = mods({ main_mod, "ALT" })
local main_shift_ctrl = mods({ main_mod, secondary, tertiary })

local rice_enabled = os.getenv("DOTFILES_RICE_ENABLE") == "1"
local quickshell = "quickshell"

local function toggle(program)
    local prog = string.sub(program, 1, 14)
    return "pkill " .. prog .. " || uwsm app -- " .. program
end

local function run_once(program)
    return "pgrep " .. program .. " || uwsm app -- " .. program
end

local function launch(program)
    return "uwsm app -- " .. program
end

local function shell_single_quote(value)
    return "'" .. string.gsub(value, "'", "'\\''") .. "'"
end

local function rice_ipc(target, action)
    return quickshell .. " -c rice ipc call " .. target .. " " .. action
end

local function rice_osd(action, fallback)
    local command = rice_ipc("osd", action) .. " >/dev/null 2>&1 || " .. fallback
    return "sh -c " .. shell_single_quote(command)
end

local function bind(keys, dispatcher)
    hl.bind(keys, dispatcher)
end

local function bind_with(keys, dispatcher, flags)
    hl.bind(keys, dispatcher, flags)
end

local function bind_exec(keys, command)
    bind(keys, hl.dsp.exec_cmd(command))
end

local function bezier_curve(name, points)
    hl.curve(name, {
        type = "bezier",
        points = {
            { points[1], points[2] },
            { points[3], points[4] },
        },
    })
end

local function animation(leaf, speed, bezier, style)
    local config = {
        leaf = leaf,
        enabled = true,
        speed = speed,
        bezier = bezier,
    }

    if style ~= nil then
        config.style = style
    end

    hl.animation(config)
end

local style = {
    rounding = 16,
    gaps_inner = 7,
    gaps_outer = 7,
    border_width = 2,
    opacity_active = 1.0,
    opacity_inactive = 0.95,
    blur_size = 8,
    blur_passes = 4,
    blur_contrast = 1.1,
    blur_brightness = 1.0,
    blur_noise = 0.02,
    font_size_small = 10,
    cursor_name = "capitaine-cursors-white",
    cursor_size = 16,
}

local colors = {
    active_border = "rgb(cba6f7)",
    inactive_border = "rgb(313244)",
}

hl.config({
    general = {
        gaps_in = style.gaps_inner,
        gaps_out = style.gaps_outer,
        border_size = style.border_width,
        allow_tearing = true,
        resize_on_border = true,
        col = {
            active_border = colors.active_border,
            inactive_border = colors.inactive_border,
        },
        hover_icon_on_border = true,
        extend_border_grab_area = 15,
    },

    cursor = {
        inactive_timeout = 3,
        no_hardware_cursors = 0,
        enable_hyprcursor = true,
    },

    decoration = {
        rounding = style.rounding,
        blur = {
            enabled = true,
            size = style.blur_size,
            passes = style.blur_passes,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false,
            contrast = style.blur_contrast,
            brightness = style.blur_brightness,
            noise = style.blur_noise,
        },
        active_opacity = style.opacity_active,
        inactive_opacity = style.opacity_inactive,
        fullscreen_opacity = 1.0,
    },

    animations = {
        enabled = true,
    },

    input = {
        kb_layout = "no",
        follow_mouse = 1,
        mouse_refocus = true,
        sensitivity = 0.0,
        accel_profile = "adaptive",
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            tap_to_click = true,
            middle_button_emulation = true,
        },
    },

    group = {
        groupbar = {
            font_size = style.font_size_small,
            gradients = true,
            render_titles = true,
            scrolling = true,
        },
        col = {
            border_active = colors.active_border,
            border_inactive = colors.inactive_border,
        },
    },

    dwindle = {
        preserve_split = true,
        force_split = 1,
        default_split_ratio = 1.2,
        smart_split = false,
        smart_resizing = false,
        use_active_for_splits = true,
    },

    misc = {
        disable_autoreload = false,
        force_default_wallpaper = 0,
        animate_mouse_windowdragging = true,
        animate_manual_resizes = true,
        vrr = 1,
        focus_on_activate = false,
        mouse_move_focuses_monitor = true,
        enable_swallow = true,
        swallow_regex = "^(foot|alacritty|kitty)$",
    },

    xwayland = {
        force_zero_scaling = true,
    },

    debug = {
        disable_logs = false,
    },
})

local env = {
    { "GRIMBLAST_NO_CURSOR", "0" },
    { "HYPRCURSOR_THEME", style.cursor_name },
    { "HYPRCURSOR_SIZE", tostring(style.cursor_size) },
    { "QT_WAYLAND_DISABLE_WINDOWDECORATION", "1" },
}

for _, entry in ipairs(env) do
    hl.env(entry[1], entry[2])
end

local exec_once = {
    "wallpaper-restore",
    "hyprctl setcursor " .. style.cursor_name .. " " .. tostring(style.cursor_size),
    "wl-clip-persist --clipboard both",
    "wl-paste --watch cliphist store",
    "uwsm finalize",
    "thunderbolt-wait && setup-monitors",
    "handle-monitor",
}

if rice_enabled then
    table.insert(exec_once, "uwsm app -- " .. quickshell .. " -c rice")
end

hl.on("hyprland.start", function()
    for _, command in ipairs(exec_once) do
        hl.exec_cmd(command)
    end
end)

bezier_curve("wind", { 0.05, 0.9, 0.1, 1.05 })
bezier_curve("winIn", { 0.1, 1.1, 0.1, 1.1 })
bezier_curve("winOut", { 0.3, -0.3, 0, 1 })
bezier_curve("liner", { 1, 1, 1, 1 })
bezier_curve("overshot", { 0.13, 0.99, 0.29, 1.1 })

animation("windows", 6, "wind", "slide")
animation("windowsIn", 6, "winIn", "slide")
animation("windowsOut", 5, "winOut", "slide")
animation("windowsMove", 5, "wind", "slide")
animation("border", 10, "liner")
animation("fade", 10, "default")
animation("layers", 4, "wind", "slide")
animation("layersIn", 4, "winIn", "slide")
animation("layersOut", 3, "winOut", "fade")
animation("workspaces", 6, "overshot", "slidevert")
animation("specialWorkspace", 6, "default", "slidevert")

hl.workspace_rule({ workspace = "special:magic", gaps_in = 20, gaps_out = 40 })

local function blurred_layer(namespace)
    hl.layer_rule({
        match = { namespace = namespace },
        blur = true,
        ignore_alpha = 0,
    })
end

blurred_layer("^(wofi)$")
blurred_layer("^(waybar)$")
blurred_layer("^(swaync-notification-window)$")
blurred_layer("^(swaync-control-center)$")

hl.window_rule({
    name = "block-activation-focus-steal",
    match = { class = ".*" },
    suppress_event = "activate activatefocus",
    focus_on_activate = false,
})

hl.window_rule({
    name = "alert-dialogs-no-initial-focus",
    match = { title = ".*([Aa]lert|[Dd]ialog|[Nn]otification|[Pp]opup).*" },
    no_initial_focus = true,
})

bind_exec(key(main_mod, "Return"), launch("foot"))
bind_exec(key(main_mod, "B"), toggle("foot -T btop -e btop"))
bind_exec(key(main_mod, "R"), toggle("foot -T yazi -e yazi"))
bind_exec(key(main_mod, "S"), launch("spotify"))
bind_exec(key(main_shift, "D"), run_once("pcmanfm"))
bind_exec(key(main_shift, "W"), launch("foot -T theme-switcher -e theme-switcher"))
bind_exec(key(main_shift, "L"), "lock-screen")
bind_exec(key(main_shift, "P"), run_once("grimblast --notify copy area"))
bind(key(main_shift, "T"), hl.dsp.window.move({ workspace = "special" }))
bind(key(main_mod, "t"), hl.dsp.workspace.toggle_special(""))
bind_exec(key(main_shift_ctrl, "Q"), "uwsm stop")
bind(key(main_mod, "Q"), hl.dsp.window.close())
bind(key(main_mod, "F"), hl.dsp.window.float({ action = "toggle" }))
bind(key(main_mod, "G"), hl.dsp.window.fullscreen({ action = "toggle" }))
bind(key(main_mod, "P"), hl.dsp.layout("togglesplit"))
bind(key(main_mod, "k"), hl.dsp.focus({ direction = "u" }))
bind(key(main_mod, "j"), hl.dsp.focus({ direction = "d" }))
bind(key(main_mod, "l"), hl.dsp.focus({ direction = "r" }))
bind(key(main_mod, "h"), hl.dsp.focus({ direction = "l" }))
bind(key(main_mod, "left"), hl.dsp.focus({ workspace = "e-1" }))
bind(key(main_mod, "right"), hl.dsp.focus({ workspace = "e+1" }))
bind(key(main_shift, "right"), hl.dsp.window.move({ workspace = "e+1" }))
bind(key(main_shift, "left"), hl.dsp.window.move({ workspace = "e-1" }))
bind_exec("XF86AudioPlay", "playerctl play-pause")
bind_exec("XF86AudioNext", "playerctl next")
bind_exec("XF86AudioPrev", "playerctl previous")

for workspace = 1, 9 do
    bind(key(main_mod, tostring(workspace)), hl.dsp.focus({ workspace = workspace }))
    bind(key(main_shift, tostring(workspace)), hl.dsp.window.move({ workspace = workspace }))
end

if rice_enabled then
    bind_exec("XF86AudioRaiseVolume", rice_osd("volumeUp", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
    bind_exec("XF86AudioLowerVolume", rice_osd("volumeDown", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
    bind_exec("XF86AudioMute", rice_osd("toggleMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
    bind_exec("XF86MonBrightnessUp", rice_osd("brightnessUp", "brightnessctl set +10%"))
    bind_exec("XF86MonBrightnessDown", rice_osd("brightnessDown", "brightnessctl set 10%-"))
    bind_exec(key(main_mod, "Space"), rice_ipc("shell", "toggleLauncher"))
    bind_exec(key(main_mod, "D"), rice_ipc("shell", "toggleDashboard"))
    bind_exec(key(main_alt, "T"), rice_ipc("shell", "toggleSwitcher"))
    bind_exec(key(main_mod, "W"), rice_ipc("shell", "toggleWallpapers"))
    bind_exec(key(main_alt, "W"), rice_ipc("wallpapers", "next"))
    bind_exec(key(main_mod, "V"), rice_ipc("shell", "toggleSatchel"))
    bind_exec(key(main_mod, "N"), rice_ipc("notifications", "toggleCenter"))
    bind_exec(key(main_shift_ctrl, "N"), rice_ipc("notifications", "clearAll"))
else
    bind_exec("XF86AudioRaiseVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
    bind_exec("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
    bind_exec("XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
    bind_exec("XF86MonBrightnessUp", "brightnessctl set +10%")
    bind_exec("XF86MonBrightnessDown", "brightnessctl set 10%-")
    bind_exec(key(main_mod, "W"), launch("foot -T wallpaper-picker -e wallpaper-picker"))
    bind_exec(key(main_mod, "N"), "swaync-client -t -sw")
    bind_exec(key(main_shift, "N"), "swaync-client -d -sw")
    bind_exec(key(main_shift_ctrl, "N"), "swaync-client -C -sw")
end

bind_with(key(main_ctrl, "k"), hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
bind_with(key(main_ctrl, "j"), hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })
bind_with(key(main_ctrl, "l"), hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
bind_with(key(main_ctrl, "h"), hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
bind_with(key(main_alt, "k"), hl.dsp.window.swap({ direction = "u" }), { repeating = true })
bind_with(key(main_alt, "j"), hl.dsp.window.swap({ direction = "d" }), { repeating = true })
bind_with(key(main_alt, "l"), hl.dsp.window.swap({ direction = "r" }), { repeating = true })
bind_with(key(main_alt, "h"), hl.dsp.window.swap({ direction = "l" }), { repeating = true })

bind_with(key(main_mod, "mouse:272"), hl.dsp.window.drag(), { mouse = true })
bind_with(key(main_mod, "mouse:273"), hl.dsp.window.resize(), { mouse = true })

local floating_class_rules = {
    "^(Rofi)$",
    "^(eww)$",
    "^(Gimp-2.10)$",
    "^(org.gnome.Calculator)$",
    "^(org.gnome.Calendar)$",
    "^(gnome-system-monitor)$",
    "^(pavucontrol)$",
    "^(nm-connection-editor)$",
    "^(Color Picker)$",
    "^(Network)$",
    "^(pcmanfm)$",
    "^(com.github.flxzt.rnote)$",
    "^(xdg-desktop-portal)$",
    "^(xdg-desktop-portal-gnome)$",
    "^(transmission-gtk)$",
    "^(org.kde.kdeconnect-settings)$",
    "^(org.pulseaudio.pavucontrol)$",
}

local floating_title_rules = {
    "^(Spotify Premium)$",
    "^(Spotify)$",
    "^(spotify_player)$",
    "^(yazi)$",
    "^(btop)$",
}

local function floating_class(pattern, width, height)
    hl.window_rule({
        match = { class = pattern },
        float = true,
        size = { width, height },
        center = true,
    })
end

local function floating_title(pattern, width, height)
    hl.window_rule({
        match = { title = pattern },
        float = true,
        size = { width, height },
        center = true,
    })
end

for _, pattern in ipairs(floating_class_rules) do
    floating_class(pattern, "monitor_w*0.5", "monitor_h*0.7")
end

for _, pattern in ipairs(floating_title_rules) do
    floating_title(pattern, "monitor_w*0.5", "monitor_h*0.7")
end

floating_title("^(theme-switcher)$", "monitor_w*0.4", "monitor_h*0.7")
floating_title("^(wallpaper-picker)$", "monitor_w*0.6", "monitor_h*0.8")

local workspace_rules = {
    { match = "class", pattern = "^(code|Code)$", workspace = "1 silent" },
    { match = "class", pattern = "^(Alacritty|alacritty|foot)$", workspace = "2 silent" },
    { match = "class", pattern = "^(zen|ZenBrowser)$", workspace = "3 silent" },
    { match = "class", pattern = "^(Slack)$", workspace = "4 silent" },
    { match = "class", pattern = "^(discord)$", workspace = "4 silent" },
    { match = "class", pattern = "^(spotify)$", workspace = "5 silent" },
    { match = "class", pattern = "^(btop|htop|nvtop|MissionCenter)$", workspace = "6 silent" },
}

for _, rule in ipairs(workspace_rules) do
    hl.window_rule({ match = { [rule.match] = rule.pattern }, workspace = rule.workspace })
end

hl.window_rule({ match = { class = "^(zen|ZenBrowser)$" }, opacity = "1.0 override 1.0 override" })
