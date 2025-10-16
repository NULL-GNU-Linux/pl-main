pkg = {
	name = "org.lua.lua",
	version = "5.4.8",
	description = "Powerful, efficient, lightweight, embeddable scripting language",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "MIT",
	homepage = "https://www.lua.org",
	depends = {},
	conflicts = {},
	provides = { "lua", "luac" },
	files = {},
}

function pkg.source()
	return function(hook)
		hook("prepare")(function()
			print("Preparing Lua source...")
			local url = "https://www.lua.org/ftp/lua-" .. pkg.version .. ".tar.gz"
			wget(url, ROOT .. "/lua-" .. pkg.version .. ".tar.gz")
			sh("tar -xzf " .. ROOT .. "/lua-" .. pkg.version .. ".tar.gz -C /tmp")
		end)

		hook("build")(function()
			print("Building Lua...")
			local make_opts = "MYCFLAGS='-fPIC' MYLDFLAGS='-static' -j$(nproc)"
			os.execute("cd /tmp/lua-" .. pkg.version .. " && make linux " .. make_opts)
		end)

		hook("pre_install")(function()
			print("Pre-installation checks for " .. pkg.name)
			local space_check = io.popen("df -h " .. ROOT .. "/usr | tail -1 | awk '{print $4}'")
			local available = space_check:read("*all")
			space_check:close()
			print("Available space: " .. available)
			if os.getenv("USER") ~= "root" then
				print("Warning: Not running as root, installation may fail")
			end
		end)

		hook("install")(function()
			print("Installing " .. pkg.name .. " " .. pkg.version)

			install("../../../../../../tmp/lua-" .. pkg.version .. "/src/lua", "/usr/bin/lua", "755")
			install("../../../../../../tmp/lua-" .. pkg.version .. "/src/luac", "/usr/bin/luac", "755")

			sh("mkdir -p " .. ROOT .. "/usr/include/lua" .. pkg.version:match("^%d+%.%d+"))
			sh("mkdir -p " .. ROOT .. "/usr/lib")
			sh("mkdir -p " .. ROOT .. "/usr/share/lua/" .. pkg.version:match("^%d+%.%d+"))

			sh(
				"cp /tmp/lua-"
					.. pkg.version
					.. "/src/*.h "
					.. ROOT
					.. "/usr/include/lua"
					.. pkg.version:match("^%d+%.%d+")
					.. "/"
			)
			sh("cp /tmp/lua-" .. pkg.version .. "/src/liblua.a " .. ROOT .. "/usr/lib/")

			table.insert(pkg.files, ROOT .. "/usr/bin/lua")
			table.insert(pkg.files, ROOT .. "/usr/bin/luac")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print("")
			print(
				"╔════════════════════════════════════════╗"
			)
			print("║  " .. pkg.provides[1] .. " installed!                ║")
			print("║  Version: " .. pkg.version .. "                      ║")
			print(
				"╚════════════════════════════════════════╝"
			)
			print("")
			sh(ROOT .. "/usr/bin/lua -v")
		end)
	end
end

function pkg.binary()
	return function(hook)
		hook("pre_install")(function()
			print("Binary installation for org.lua.lua is not yet supported. please use b/org.lua/lua instead.")
			error("Unsupported.")
		end)

		hook("install")(function()
			print("Installing binary files...")
			install("../../../../../../../../../tmp/lua-" .. pkg.version .. "/src/lua", "/usr/bin/lua", "755")
			install("../../../../../../../../../tmp/lua-" .. pkg.version .. "/src/luac", "/usr/bin/luac", "755")

			table.insert(pkg.files, ROOT .. "/usr/bin/lua")
			table.insert(pkg.files, ROOT .. "/usr/bin/luac")
		end)

		hook("post_install")(function()
			print("Binary installation complete!")
			print("Verifying installation...")
			sh(ROOT .. "/usr/bin/lua -v")
			print("")
			print("Installation successful!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall " .. pkg.name)
		end)

		hook("uninstall")(function()
			print("Removing " .. pkg.name .. "...")
			uninstall("/usr/bin/lua")
			uninstall("/usr/bin/luac")

			sh("rm -rf " .. ROOT .. "/usr/include/lua" .. pkg.version:match("^%d+%.%d+"))
			sh("rm -f " .. ROOT .. "/usr/lib/liblua.a")
			sh("rm -rf " .. ROOT .. "/usr/share/lua/" .. pkg.version:match("^%d+%.%d+"))
		end)

		hook("post_uninstall")(function()
			print("Cleanup...")
			sh("rm -rf /tmp/lua-" .. pkg.version .. " /tmp/lua-*.tar.gz")
			print("")
			print(pkg.name .. " has been uninstalled")
		end)
	end
end

function pkg.upgrade()
	return function(from_version)
		print("Upgrading Lua from " .. from_version .. " to " .. pkg.version)
		print("Backing up existing Lua libraries...")
		sh("mkdir -p /tmp/lua-backup")
		sh("cp -r " .. ROOT .. "/usr/share/lua/* /tmp/lua-backup/ 2>/dev/null || true")
		print("Upgrade preparation complete")
	end
end
