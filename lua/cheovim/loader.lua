-- Loader for neovim configurations

-- Initialize the loader and logger
local loader, log = {

	selected_profile = nil,
	profiles = nil,
    profile_changed = false,

}, require('cheovim.logger')

function loader.get_profiles(path)
	-- No pcall or error checking here because we need to be as speedy as possible
	local selected_profile, profiles = dofile(path)

	-- If the profile exists add it to the current path and return it
	if profiles[selected_profile] then
        if not profiles[selected_profile][2].useVimFile then
            package.path = package.path .. ";" .. profiles[selected_profile][1] .. "/lua/?.lua"
        end
		return selected_profile, profiles
	end
end

function loader.create_plugin_manager_symlinks(selected_profile, profiles)

	local profile_path = vim.fn.expand(profiles[selected_profile][1])

    -- Construct a default configuration
	local default_config = {
		url = false,
		plugins = "packer",
		preconfigure = nil,
	}

    -- Override all the default values with the user's options
	local profile_config = vim.tbl_deep_extend("force", default_config, profiles[selected_profile][2])
	local root_plugin_dir = loader.stdpath_data_orig .. "/site/pack"

    -- Delete all symlinks present inside of site/pack
	for _, symlink in ipairs(vim.fn.glob(root_plugin_dir .. "/*", 0, 1, 1)) do
		vim.loop.fs_unlink(symlink)
	end

    -- Create all the necessary cheovim directories if they don't already exist
	vim.fn.mkdir(root_plugin_dir .. "/cheovim/" .. selected_profile, "p")

    -- Relink the current config's plugin/ directory with a symlinked version
    -- If we don't do this then packer will write its packer_compiled.vim into a location we cannot track
	vim.loop.fs_unlink(loader.stdpath_config_orig .. "/plugin")
    if not loader.noSymlink then
        vim.loop.fs_symlink(vim.fn.stdpath("config") .. "/plugin", loader.stdpath_config_orig .. "/plugin", { dir = true })
    end

    -- Symlink the plugin install location
	vim.loop.fs_unlink(root_plugin_dir .. "/" .. profile_config.plugins)
    if not loader.noSymlink then
        vim.loop.fs_symlink(root_plugin_dir .. "/cheovim/" .. selected_profile, root_plugin_dir .. "/" .. profile_config.plugins, { dir = true })
    end

    -- If we want to preconfigure some software
	if profile_config.preconfigure then
		-- Print a unique and epic loading message
		local loading_messages = {
			"Brewing up your plugins...",
			"Linearly interpolating your config...",
			"Binary searching for a decent config...",
			"Configuring all the goodies...",
			"Finding who asked...",
			"Making sure nothing breaks...",
			"Loading up your favourite plugin manager...",
			"Finding reasons why Neovim is the best text editor...",
			"Laughing at all the emacs users...",
			"Initializing the plugin manager...",
			"Finding the next occurrence of a leap second...",
			"Listing all the reasons why Kyoko is best waifu...",
			"Telling the population to use Linux...",
			"Arbitrarily executing code...",
			"Censoring all the bad reviews...",
			"Locating Peach's castle...",
			"Dividing by 0...",
			"Breaking the 4th wall...",
			"Just Neovim Just Neovim Just Neovim Just Neovim...",
			"Locating the funny...",
			"Manipulating the stock market...",
			"Spamming all r/emacs comments with hAhA I sTiLl hAvE mY PiNKy...",
			"Consooming all the RAM...",
		}

		-- Set a pseudorandom seed
		math.randomseed(os.time())
		vim.cmd(("echom \"%s\""):format(loading_messages[math.random(#loading_messages)]))

		-- Cheovim can configure itself for several known configurations, they are defined here
		local config_matches = {
			["doom-nvim"] = "packer:opt",
			["lunarvim"] = "packer:start",
			["vapournvim"] = "packer:start",
			["nv-ide"] = "packer:start",
			["lvim"] = "packer:opt",
		}

		-- Check whether the user has picked one of the above configs
		local config_match = config_matches[profile_config.preconfigure:lower()]

		-- If they have then set profile_config.preconfigure to its respective option in the config_matches table
		profile_config.preconfigure = config_match or profile_config.preconfigure

		-- Split the preconfigure options at every ':'
		local preconfigure_options = vim.split(profile_config.preconfigure, ":", true)

        -- If we elected to autoconfigure packer
		if preconfigure_options[1] == "packer" then
			local branch = "master"

            -- Perform option checking
			if #preconfigure_options < 2 then
				table.insert(preconfigure_options, "start")
			elseif preconfigure_options[2] ~= "start" and preconfigure_options[2] ~= "opt" then
				log.warn("Config option for packer:{opt|start} did not match the allowed values {opt|start}. Assuming packer:start...")
				table.insert(preconfigure_options, "start")
			end

            -- If we have specified a branch then set it
			if preconfigure_options[3] and preconfigure_options[3]:len() > 0 then
				branch = preconfigure_options[3]
			end

			-- Grab packer from GitHub with all the options
			vim.cmd("silent !git clone https://github.com/wbthomason/packer.nvim -b " .. branch .. " " .. root_plugin_dir .. "/" .. profile_config.plugins .. "/" .. preconfigure_options[2] .. "/packer.nvim")
		elseif preconfigure_options[1] == "paq-nvim" then
			local branch = "master"

            -- Perform option checking
			if #preconfigure_options < 2 then
				log.trace("Did not provide second option for paq's preconfiguration. Assuming paq-nvim:start...")
				table.insert(preconfigure_options, "start")
			elseif preconfigure_options[2] ~= "start" and preconfigure_options[2] ~= "opt" then
				log.warn("Config option for paq-nvim:{opt|start} did not match the allowed values {opt|start}. Assuming paq-nvim:start...")
				table.insert(preconfigure_options, "start")
			end

            -- If we have specified a branch then set it
			if preconfigure_options[3] and preconfigure_options[3]:len() > 0 then
				branch = preconfigure_options[3]
			end

			-- Grab packer from GitHub with all the options
			vim.cmd("silent !git clone https://github.com/savq/paq-nvim -b " .. branch .. " " .. root_plugin_dir .. "/" .. profile_config.plugins .. "/" .. preconfigure_options[2] .. "/paq-nvim")
		else -- We do not know of such a configuration, so print an error
			log.error(("Unable to preconfigure %s, such a configuration is not available, sorry!"):format(preconfigure_options[1]))
		end
	end

    if type(profile_config.setup) == "string" then
        vim.cmd(profile_config.setup)
    elseif type(profile_config.setup) == "function" then
        profile_config.setup(profile_path)
    end

    -- Invoke the profile's init.lua
    if profiles[selected_profile][2].useVimFile then
        vim.cmd('source ' .. profile_path .. '/init.vim')
    else
        dofile(profile_path .. "/init.lua")
    end

	-- Issue the success message
	log.info("Successfully loaded new configuration")
end

-- Pulls a config from a URL and returns the path of the stored config
function loader.handle_url(selected_profile, profiles)

	-- Store the URL in a variable
	local url = profiles[selected_profile][1]
	-- Set the install location for remote configurations
	local cheovim_pulled_config_location = loader.stdpath_data_orig .. "/cheovim/"

	-- Create the directory if it doesn't already exist
	vim.fn.mkdir(cheovim_pulled_config_location, "p")

	-- Check whether we already have a pulled repo in that location
	local dir, err_message = vim.loop.fs_scandir(cheovim_pulled_config_location .. selected_profile)

	-- If we don't then pull it down!
	if not dir then
		log.info("Pulling your config via git...")
		vim.cmd("!git clone " .. url .. " " .. cheovim_pulled_config_location .. selected_profile)
	end

	-- Return the path of the installed configuration
	return cheovim_pulled_config_location .. selected_profile

end

-- helper function to join paths
function loader.join_paths(...)
	local path_sep = vim.loop.os_uname().version:match("Windows") and "\\" or "/"
	local result = table.concat({ ... }, path_sep)
	return result
end

function cheovim_profile_setup(selected_profile, profiles)
	local profile_path = vim.fn.expand(profiles[selected_profile][1])
	-- no need to delete packer_compiled.lua, since config path will be from current cheovim config.
	-- vim.fn.delete(loader.stdpath_config_orig .. "/plugin/packer_compiled.lua")
	-- make sure profile_path is in runtimepath for modules to work (ex doom-nvim)
	vim.opt.rtp:append(profile_path)
	-- remove original data/site and data/site/after
	vim.opt.rtp:remove(loader.join_paths(loader.stdpath_data_orig, "site"))
	vim.opt.rtp:remove(loader.join_paths(loader.stdpath_data_orig, "site", "after"))
	-- these will not work since cheovim will override default config path
	-- default config path needs to be in rtp for cheovim to work correctly.
	-- vim.opt.rtp:remove(loader.stdpath_config_orig)
	-- vim.opt.rtp:remove(loader.join_paths(loader.stdpath_config_orig, "after"))

	-- query original data path and append selected_profile in the path for new stdpath("data")
	local data_path = loader.join_paths(loader.stdpath_data_orig, selected_profile)
	-- add new data/site and data/site/after
	vim.opt.rtp:prepend(loader.join_paths(data_path, "site"))
	vim.opt.rtp:append(loader.join_paths(data_path, "site", "after"))
	vim.cmd([[let &packpath = &runtimepath]])
	-- vim.cmd(("echom \"%s\""):format(data_path))

	-- an implementation of stdpath
	local stdpath_impl = function(what)
		if what:lower() == "data" then
			return data_path
		elseif what:lower() == "cache" then
			return loader.join_paths(data_path, ".cache")
		elseif what:lower() == "config" then
			return profile_path
		end
		return vim.fn._stdpath(what)
	end

	-- Override vim.fn.stdpath and vim.call to manipulate the data returned by it. Yes, I know, changing core functions
	-- is really bad practice in any codebase, however this is our only way to make things like LunarVim, doom-nvim etc. work
	vim.fn.stdpath = function(what)
		return stdpath_impl(what)
	end
	vim.call = function(...)
		if select("#", ...) == 2 and select(1, ...):lower() == "stdpath" then
			return stdpath_impl(select(2, ...))
		end
		return vim._call(...)
	end
end

function loader.create_plugin_symlink(selected_profile, profiles)

	local selected = profiles[selected_profile]

	-- If we haven't selected a valid profile or that profile doesn't come with a path then error out
	if not selected then
		log.error("Unable to find profile with name", selected_profile)
		return
	elseif not selected[1] then
		log.error("Unable to load profile with name", selected_profile, "- the first element of the profile must be a path.")
		return
	end

	-- Set the public variables for use by other files
	loader.selected_profile = selected_profile
	loader.profiles = profiles
    -- Set the variable for no symlink 
    loader.noSymlink = profiles[selected_profile][2].noSymlink and true or false

	-- save original paths
	loader.stdpath_config_orig = vim.fn.stdpath("config")
	loader.stdpath_data_orig = vim.fn.stdpath("data")
	loader.stdpath_cache_orig = vim.fn.stdpath("cache")

	-- Clone the current stdpath function definition into an unused func
	vim.fn._stdpath = vim.fn.stdpath
	vim._call = vim.call

	-- setup profile, this will hook vim.fn.stdpath and vim.call
	cheovim_profile_setup(selected_profile, profiles)

    -- create new data directory - some profile will not work if this dir does not exist (ex doom-nvim)
    local profile_data_dir = vim.fn.stdpath('data') -- using hooked fnction
    local dir, err_message = vim.loop.fs_scandir(profile_data_dir)
    if not dir then
        vim.fn.mkdir(profile_data_dir, "p")
    end

    -- Set this variable to the site/pack location
	local root_plugin_dir = loader.stdpath_data_orig .. "/site/pack"

    -- Unlink the plugins/ directory so packer_compiled.vim doesn't autotrigger
	vim.loop.fs_unlink(loader.stdpath_config_orig .. "/plugin")

	if selected[2] and selected[2].url then
		selected[1] = loader.handle_url(selected_profile, profiles)
	end

	-- Expand the current path (i.e. convert ~ to the home directory etc.)
	selected[1] = vim.fn.expand(selected[1])

	local start_directory = root_plugin_dir .. "/cheovim/start"

    -- Create a start/ directory for the cheovim configuration
	vim.fn.mkdir(start_directory, "p")

    -- Read the cheovim symlink from the start/ directory
	local symlink = vim.loop.fs_readlink(start_directory .. "/cheovim")

    -- If that symlink does not exist or it differs from the selected config
    -- then update the current configuration and reload everything
	if not symlink then
        loader.profile_changed = true
        vim.loop.fs_symlink(selected[1], start_directory .. "/cheovim", { dir = true })
		loader.create_plugin_manager_symlinks(selected_profile, profiles)
	elseif symlink ~= selected[1] then
        loader.profile_changed = true
		vim.loop.fs_unlink(start_directory .. "/cheovim")
        vim.loop.fs_symlink(selected[1], start_directory .. "/cheovim", { dir = true })
		loader.create_plugin_manager_symlinks(selected_profile, profiles)
	else -- Else load the config and restore the plugin/ directory
        local profile_path = vim.fn.expand(profiles[selected_profile][1])
        if profiles[selected_profile][2].useVimFile then
            vim.cmd('source ' .. profile_path .. '/init.vim')
        else
            dofile(profile_path .. "/init.lua")
            vim.loop.fs_symlink(vim.fn.stdpath("config") .. "/plugin", loader.stdpath_config_orig .. "/plugin", { dir = true })
        end
	end

end

return loader
