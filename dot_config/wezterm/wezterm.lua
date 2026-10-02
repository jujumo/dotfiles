-- Minimal config for a fair GPU/image/decoration eval against Kitty and Konsole.
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- font DL at : https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/RobotoMono.zip
config.font = wezterm.font 'RobotoMono Nerd Font Mono'
config.font_size = 12.0

-- GPU-accelerated front end. WebGpu is the newer/faster path; if you hit
-- driver glitches on this box, switch to 'OpenGL' (also GPU-accelerated).
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'

-- WezTerm decodes Sixel, the iTerm2 protocol AND the kitty graphics protocol
-- -- the broadest coverage of the three terminals. All on by default; kept
-- explicit here since it's the headline feature under test.
config.enable_kitty_graphics = true

-- No wezterm-native tab bar (we multiplex via zellij); keep the OS titlebar.
-- config.enable_tab_bar = false

config.window_close_confirmation = 'NeverPrompt'

-- Catppuccin Mocha (official palette, same as the PuTTY port)
config.colors = {
  foreground = '#cdd6f4',
  background = '#1e1e2e',
  cursor_bg = '#f5e0dc',
  cursor_border = '#f5e0dc',
  cursor_fg = '#1e1e2e',
  selection_bg = '#585b70',
  selection_fg = '#cdd6f4',
  ansi = {
    '#45475a', '#f38ba8', '#a6e3a1', '#f9e2af',
    '#89b4fa', '#f5c2e7', '#94e2d5', '#bac2de',
  },
  brights = {
    '#585b70', '#f38ba8', '#a6e3a1', '#f9e2af',
    '#89b4fa', '#f5c2e7', '#94e2d5', '#a6adc8',
  },
}


-- 
config.mouse_bindings = {
  -- Keep mouse selection feeding PRIMARY, as expected on linux
  -- Single click selection
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelection 'PrimarySelection',
  },
  -- Double click selection (words)
  {
    event = { Up = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelection 'PrimarySelection',
  },
  -- Triple click selection (lines)
  {
    event = { Up = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelection 'PrimarySelection',
  },
}

-- config.window_background_opacity = 0.9
return config
