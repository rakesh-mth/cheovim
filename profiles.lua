--[[
     /  /\         /__/\         /  /\         /  /\          ___        ___          /__/\
    /  /:/         \  \:\       /  /:/_       /  /::\        /__/\      /  /\        |  |::\
   /  /:/           \__\:\     /  /:/ /\     /  /:/\:\       \  \:\    /  /:/        |  |:|:\
  /  /:/  ___   ___ /  /::\   /  /:/ /:/_   /  /:/  \:\       \  \:\  /__/::\      __|__|:|\:\
 /__/:/  /  /\ /__/\  /:/\:\ /__/:/ /:/ /\ /__/:/ \__\:\  ___  \__\:\ \__\/\:\__  /__/::::| \:\
 \  \:\ /  /:/ \  \:\/:/__\/ \  \:\/:/ /:/ \  \:\ /  /:/ /__/\ |  |:|    \  \:\/\ \  \:\~~\__\/
  \  \:\  /:/   \  \::/       \  \::/ /:/   \  \:\  /:/  \  \:\|  |:|     \__\::/  \  \:\
   \  \:\/:/     \  \:\        \  \:\/:/     \  \:\/:/    \  \:\__|:|     /__/:/    \  \:\
    \  \::/       \  \:\        \  \::/       \  \::/      \__\::::/      \__\/      \  \:\
     \__\/         \__\/         \__\/         \__\/           ~~~~                   \__\/

	A config switcher written in Lua by NTBBloodbath and Vhyrro.
--]]

-- Defines the profiles you want to use
local profiles = {
	--[[
	Here's an example:

		<name_of_config> = { <path_to_config>, {
				plugins = "packer", -- Where to install plugins under site/pack
				preconfigure = "packer:opt" -- Whether or not to preconfigure a plugin manager for you
			}
		}

	More in-depth information can be found in cheovim's README on GitHub.
	--]]
	my_config = { "~/.config/nvim.bak", {
			plugins = "packer",
			preconfigure = "packer",
		}
	},
    minimal = { "~/.config/minimal", {
            plugins = "packer",
            preconfigure = "packer",
        }
    },
    svim = { "~/.config/nvim-config/svim", {
          plugins = "packer",
          preconfigure = "packer:start",
        }
    },
    LunarVim = { "~/.config/nvim-config/LunarVim", {
            plugins = "packer",
            setup = function()
                local path = vim.fn.expand("~/.config/nvim-config/LunarVim")
                local dir, err_message = vim.loop.fs_scandir(path)
                if not dir then -- Check whether we already have a pulled repo in that location
                    vim.cmd("!git clone https://github.com/LunarVim/LunarVim.git" .. " " .. path)
                end
            end,
            preconfigure = "lunarvim"
        }
    },
    DoomNvim = { "~/.config/nvim-config/doom-nvim", {
            plugins = "packer",
            setup = function()
                local path = vim.fn.expand("~/.config/nvim-config/doom-nvim")
                -- vim.cmd(("echom \"%s\""):format(path))
                local dir, err_message = vim.loop.fs_scandir(path)
                if not dir then -- Check whether we already have a pulled repo in that location
                    vim.cmd("!git clone --depth 1 https://github.com/NTBBloodbath/doom-nvim.git" .. " " .. path)
                end
            end,
            preconfigure = "doom-nvim"
        }
    }
}

function add_profile(selected_profile, profiles)
    -- if selected profile does not exist then add it
    if profiles[selected_profile] == nil then
        print("profile " .. selected_profile .. " is not found. adding this profile...")
        profiles[selected_profile] = { "~/.config/nvim-config/" .. selected_profile, {
              plugins = "packer",
              preconfigure = "packer:start",
            }
        }
    end
end

-- how to use - nvim command line
-- nvim --cmd "lua load_profile='LunarVim'"
-- nvim --cmd "lua load_profile='DoomNvim'"

-- return <name_of_config>, <list_of_profiles>
local default_profile = 'my_config'
local selected_profile = load_profile or default_profile
add_profile(selected_profile, profiles)
return selected_profile, profiles
