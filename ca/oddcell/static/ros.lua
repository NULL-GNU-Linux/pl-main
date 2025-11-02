pkg = {
	name = "ca.oddcell.static.ros",
	version = "rolling",
	description = "The caching package manager",
	maintainer = "TheOddCell <odd@obsidianos.xyz>",
	license = "MIT",
	homepage = "https://static.oddcell.ca/",
	depends = { "coreutils", "sh" },
	conflicts = {},
	provides = { "ros" },
	files = {},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("prepare")(function()
			wget("https://files.obsidianos.xyz/~odd/static/ros", tmpdir .. "/ros")
		end)

		hook("build")(function()
			print("Imagine needing to build shell scripts")
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
			local build_dir = tmpdir .. "/ros"
			sh("cp " .. build_dir .. " " .. ROOT .. "/usr/bin/ros")
		end)
		hook("post_install")(function()
			print("Post-installation setup...")
			print("")
			print(
				"╔══════════════════════════════════════════════════════╗"
			)
			print("║ ros, the caching package manager has been installed! ║")
			print("║ this package is provided by the odd static service.  ║")
			print(
				"╚══════════════════════════════════════════════════════╝"
			)
			print("")
			sh(ROOT .. "/usr/bin/ld --version | head -n 1")
		end)
	end
end

function pkg.binary()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("pre_install")(function()
			print("Do a building installation iCant bother to copy and paste code, it's a script anyways")
		end)

		hook("install")(function()
			print("how")
		end)

		hook("post_install")(function()
			print("waht")
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
			uninstall("/usr/bin/ros")
		end)

		hook("post_uninstall")(function()
			print(pkg.name .. " has been uninstalled")
		end)
	end
end

function pkg.upgrade()
	return function(from_version)
		print("Upgrading ros")
		print("Upgrade preparation complete")
	end
end
