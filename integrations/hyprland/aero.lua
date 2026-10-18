-- Load from hyprland.lua after your appearance configuration:
-- dofile(os.getenv("HOME") .. "/.config/quickshell/integrations/hyprland/aero.lua")
-- Requires decoration.blur.enabled = true in your compositor configuration.
hl.layer_rule({
    name = "quickshell-aero-glass",
    match = { namespace = "^quickshell-bar$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.01,
})
