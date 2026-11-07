-- File ini dihasilkan otomatis oleh Quickshell Settings (Hyprland GUI)
hl.config({
    general = {
        layout = "dwindle",
        gaps_in = 5,
        gaps_out = 15,
        border_size = 3,
        resize_on_border = true,
        extend_border_grab_area = 15,
        hover_icon_on_border = true,
        allow_tearing = true,

    },
    decoration = {
        rounding = 20,
        rounding_power = 2.5,
        active_opacity = 1,
        inactive_opacity = 1.0,
        dim_inactive = true,
        dim_strength = 0.05,
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            noise = 0.0117,
            xray = true,
            popups = false,
        },
        shadow = {
            enabled = true,
            range = 22,
            render_power = 3,
        }
    },
    animations = {
        enabled = true,
    },
    input = {
        follow_mouse = 1,
        sensitivity = 0.5,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            disable_while_typing = false,
        }
    },
    misc = {
        animate_manual_resizes = false,
        animate_mouse_windowdragging = false,
    }
})

hl.layer_rule({ match = { namespace = "quickshell:bar" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:bar" }, ignore_alpha = 0.0 })
hl.layer_rule({ match = { namespace = "quickshell:celestialBezel" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:celestialBezel" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" }, ignore_alpha = 0.0 })
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" }, ignore_alpha = 0.0 })
