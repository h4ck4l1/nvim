
-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- === Font definitions (kept from your original file) ===
local firacode_font = wezterm.font {
  family = "FiraCode Nerd Font",
  harfbuzz_features = {
    "cv01=1","cv02=1","cv06=1","cv11=1","cv14=1","cv16=1","cv17=1",
    "cv18=1","cv29=1","cv30=1","cv31=1","ss01=1","ss03=1","ss04=1","ss05=1",
  },
  weight = "Regular",
}

local jetbrains_mono_font = wezterm.font {
  family = "JetBrains Mono",
  harfbuzz_features = {
    "calt=1","zero=1","frac=0",
    "ss01=1","ss02=0","ss03=0","ss04=0","ss05=0","ss06=0","ss07=0","ss08=0",
    "ss09=0","ss10=0","ss11=0","ss12=0","ss13=0","ss14=0","ss15=0","ss16=0",
    "ss17=0","ss18=0","ss19=0","ss20=0",
    "cv01=0","cv02=0","cv03=0","cv04=0","cv05=0","cv06=0","cv07=0","cv08=0",
    "cv09=0","cv10=0",
  },
  weight = "Regular",
}

local spacemono_font = wezterm.font {
  family = "SpaceMono Nerd Font",
  weight = "Regular",
}

local victormono_font = wezterm.font {
  family = "VictorMono Nerd Font",
  harfbuzz_features = { "ss01=1", "ss02=1", "ss06=1", "ss07=1", "ss08=1" },
  weight = "Regular",
}

local codenewroman_font = wezterm.font {
  family = "CodeNewRoman Nerd Font",
  weight = "Regular",
}

local comicshans_font = wezterm.font {
  family = "ComicShannsMono Nerd Font",
  weight = "Regular",
}

local daddytime_font = wezterm.font {
  family = "DaddyTimeMono Nerd Font",
  weight = "Regular",
}

local envycoder_font = wezterm.font {
  family = "EnvyCodeR Nerd Font",
  weight = "Regular",
}

local fantasque_font = wezterm.font {
  family = "FantasqueSansMono Nerd Font",
  weight = "Regular",
}

-- === Keybindings ===
local my_keys = {
  {
    key = "t",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SpawnCommandInNewTab{
      domain = { DomainName = "WSL:Ubuntu-24.04" },
      cwd = "~",
    },
  },
}

-- === Apply your config choices using the builder-style config ===
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.animation_fps = 120

config.wsl_domains = {
  {
    name = "WSL:Ubuntu-24.04",
    distribution = "Ubuntu-24.04",
    default_cwd = "~",
  },
}

-- External Config
config.enable_tab_bar = false
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.use_fancy_tab_bar = true
config.tab_max_width = 25
config.win32_system_backdrop = "Acrylic"
config.win32_acrylic_accent_color = "#bee0ff"
config.color_scheme = "tokyonight_moon"
config.background = {
	{
		source = {
			File = "C:\\Users\\sohai\\image.png"
		},
		hsb = {
			hue = 1.0,
			saturation = 1.02,
			brightness = 0.02,
		},
		width = "100%",
		height = "100%",
	},
}


config.default_cwd = "/"
config.default_domain = "WSL:Ubuntu-24.04"

-- Font selection (choose the font value you want active)
config.font = victormono_font

config.font_size = 16.0
config.enable_scroll_bar = false
config.cursor_thickness = 3.5
config.audible_bell = "SystemBeep"

config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

config.keys = my_keys

return config
