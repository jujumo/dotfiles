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

-- Solarized Dark (Ethan Schoonover canonical palette) -- same values as kitty.conf
config.colors = {
  foreground = '#839496',
  background = '#002b36',
  cursor_bg = '#93a1a1',
  cursor_border = '#93a1a1',
  cursor_fg = '#002b36',
  selection_bg = '#073642',
  selection_fg = '#93a1a1',
  ansi = {
    '#073642', '#dc322f', '#859900', '#b58900',
    '#268bd2', '#d33682', '#2aa198', '#eee8d5',
  },
  brights = {
    '#002b36', '#cb4b16', '#586e75', '#657b83',
    '#839496', '#6c71c4', '#93a1a1', '#fdf6e3',
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
