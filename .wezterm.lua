
local wezterm = require 'wezterm'

local firacode_font = wezterm.font {
	family = "FiraCode Nerd Font",
	harfbuzz_features = {
	  "cv01=1",
	  "cv02=1",
	  "cv06=1",
	  "cv11=1",
	  "cv14=1",
	  "cv16=1",
	  "cv17=1",
	  "cv18=1",
	  "cv29=1",
	  "cv30=1",
	  "cv31=1",
	  "ss01=1",
	  "ss03=1",
	  "ss04=1",
	  "ss05=1",
	},
	weight = "Regular"
}

local spacemono_font = wezterm.font {
	family = "SpaceMono Nerd Font",
	weight = "Regular"
}

local victormono_font = wezterm.font {
	family = "VictorMono Nerd Font",
	harfbuzz_features = {
		"ss01=1",
		"ss02=1",
		"ss06=1",
		"ss07=1",
		"ss08=1"
	},
	weight = "Regular"
}

local codenewroman_font = wezterm.font {
	family = "CodeNewRoman Nerd Font",
	weight = "Regular"
}

local comicshans_font = wezterm.font {
	family = "ComicShannsMono Nerd Font",
	weight = "Regular"
}

local daddytime_font = wezterm.font {
	family = "DaddyTimeMono Nerd Font",
	weight = "Regular"
}

local envycoder_font = wezterm.font {
	family = "EnvyCodeR Nerd Font",
	weight = "Regular"
}

local fantasque_font = wezterm.font {
	family = "FantasqueSansMono Nerd Font",
	weight = "Regular"
}

-- keybindings
local my_keys = {
  { key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnCommandInNewTab{
      domain = { DomainName = "WSL:Ubuntu-24.04" },
      cwd = "~",
    } },
}

return {
  front_end = "WebGpu",
  webgpu_power_preference = "HighPerformance",
  animation_fps = 144,

  wsl_domains = {
    {
      name = "WSL:Ubuntu-24.04",
      distribution = "Ubuntu-24.04",
      default_cwd = "~",
    },
  },
  default_cwd = "/",
  default_domain = "WSL:Ubuntu-24.04",

  -- Font Setting Here

  font = comicshans_font,

  -- Font Setting Here

  font_size = 18.0,
  enable_scroll_bar = false,
  cursor_thickness = 3.5,
  window_background_opacity = 1.0,
  audible_bell = "SystemBeep",

  window_padding = {
    left = 8,
    right = 8,
    top = 6,
    bottom = 6,
  },
  keys = my_keys,
}
