pkg = {
	name = "xyz.obsidianos.obsidianctl",
	version = "git",
	description = "Obsidianctl",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "MIT",
	homepage = "https://github.com/Obsidian-OS/obsidianctl",
	depends = {},
	conflicts = {},
	provides = { "obsidianctl" },
	files = {},
}
function pkg.source()
	return function(hook)
		hook("prepare")(function()
			print("Preparing source code...")
			gitclone(pkg.homepage, "obsidianctl")
		end)

		hook("build")(function()
			print("Building...")
			sh("cd obsidianctl && make")
		end)
		hook("pre_install")(function()
			print("Pre-installation checks for " .. pkg.name)
			local space_check = io.popen("df -h " .. ROOT .. "/usr | tail -1 | awk '{print $4}'")
			local available = space_check:read("*all")
			space_check:close()
			print("Available space: " .. available)
			sh("id")
			if os.getenv("USER") ~= "root" then
				print("Warning: Not running as root, installation may fail")
			end
		end)
		hook("install")(function()
			print("Installing " .. pkg.name .. " " .. pkg.version)
			install("obsidianctl/obsidianctl", "/usr/local/sbin/obsidianctl", "755")
			sh("chown root:root " .. ROOT .. "/usr/local/sbin/obsidianctl")
			print("Creating symlinks...")
			print("Setting up configuration...")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print("")
			print(
				"╔════════════════════════════════════════╗"
			)
			print("║  " .. pkg.provides[1] .. " installed!          ║")
			print("║  Version: " .. pkg.version .. "                        ║")
			print(
				"╚════════════════════════════════════════╝"
			)
			print("")
		end)
	end
end

function pkg.binary()
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for " .. pkg.name)
			local arch = io.popen("uname -m"):read("*all"):gsub("%s+", "")
			print("Detected architecture: " .. arch)
			if arch ~= "x86_64" then
				error("Binary package only available for x86_64")
			end

			print("Downloading binary package...")
			local url = "https://example.org/binaries/hello-" .. pkg.version .. "-linux-x86_64.tar.gz"
			curl(url, "/tmp/hello-binary.tar.gz")
		end)

		hook("install")(function()
			print("Installing binary files...")

			sh("tar -xzf " .. ROOT .. "/tmp/hello-binary.tar.gz -C " .. ROOT .. "/usr/local")
			table.insert(pkg.files, ROOT .. "/usr/local/hello") -- Track the extracted directory

			print("Creating wrapper script...")
			local wrapper = [[#!/bin/bash
export HELLO_HOME=/usr/local/hello
export LD_LIBRARY_PATH=/usr/local/hello/lib:$LD_LIBRARY_PATH
exec /usr/local/hello/bin/hello "$@"
]]
			sh("printf %s " .. shell_escape(wrapper) .. " > " .. ROOT .. "/usr/bin/hello")
			sh("chmod +x " .. ROOT .. "/usr/bin/hello")
			table.insert(pkg.files, ROOT .. "/usr/bin/hello")
		end)

		hook("post_install")(function()
			print("Binary installation complete!")
			print("Verifying installation...")
			sh(ROOT .. "/usr/bin/hello --version")

			print("")
			print("Installation successful!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall " .. pkg.name)

			print("Stopping related services...")
			sh("systemctl stop hello.service 2>/dev/null")

			print("Backing up configuration...")
			sh("cp " .. ROOT .. "/etc/hello/hello.conf " .. ROOT .. "/etc/hello/hello.conf.bak 2>/dev/null")
		end)

		hook("uninstall")(function()
			print("Removing " .. pkg.name .. "...")

			print("Removing binaries...")
			uninstall("/usr/bin/hello")
			uninstall("/usr/local/bin/hello")

			print("Removing libraries...")
			uninstall("/usr/local/hello")

			print("Removing man pages...")
			uninstall("/usr/share/man/man1/hello.1.gz")

			print("Removing configuration...")
			uninstall("/etc/hello")
		end)

		hook("post_uninstall")(function()
			print("Cleanup...")
			print("Removing cache files...")
			uninstall("/var/cache/hello")

			print("")
			print(pkg.name .. " has been uninstalled")
			print("Configuration backup: " .. ROOT .. "/etc/hello/hello.conf.bak")
		end)
	end
end

function pkg.upgrade()
	return function(from_version)
		print("Upgrading from " .. from_version .. " to " .. pkg.version)

		if from_version:match("^1%.") then
			print("Major version upgrade detected")
			print("Migrating configuration format...")
			sh(ROOT .. "/usr/local/sbin/hello-config-migrate " .. ROOT .. "/etc/hello/hello.conf")
		end

		if from_version < "2.0.0" then
			print("Database schema update required...")
			sh(ROOT .. "/usr/local/sbin/hello-db-upgrade")
		end

		print("Upgrade hooks complete")
	end
end
