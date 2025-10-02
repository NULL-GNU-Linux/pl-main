pkg = {
	name = "xyz.obsidianos.obsidianctl",
	version = "NaN",
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
			os.execute("git clone " .. pkg.homepage)
		end)

		hook("build")(function()
			print("Building...")
			os.execute("cd obsidianctl && make")
		end)
		hook("pre_install")(function()
			print("Pre-installation checks for " .. pkg.name)
			local space_check = io.popen("df -h /usr | tail -1 | awk '{print $4}'")
			local available = space_check:read("*all")
			space_check:close()
			print("Available space: " .. available)
			os.execute("id")
			if os.getenv("USER") ~= "root" then
				print("Warning: Not running as root, installation may fail")
			end
		end)
		hook("install")(function()
			print("Installing " .. pkg.name .. " " .. pkg.version)
			local ret = os.execute("cd obsidianctl && make install")
			print("Creating symlinks...")
			print("Setting up configuration...")
			table.insert(pkg.files, "/usr/local/sbin/obsidianctl")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print("Updating man database...")
			os.execute("mandb -q")
			print("Setting permissions...")
			os.execute("chmod 755 /usr/local/sbin/obsidianctl")
			os.execute("chown root:root /usr/local/sbin/obsidianctl")

			print("")
			print(
				"╔════════════════════════════════════════╗"
			)
			print("║  " .. pkg.name .. " installed!          ║")
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
			os.execute("wget " .. url .. " -O /tmp/hello-binary.tar.gz")
		end)

		hook("install")(function()
			print("Installing binary files...")

			os.execute("tar -xzf /tmp/hello-binary.tar.gz -C /usr/local")

			print("Creating wrapper script...")
			local wrapper = [[#!/bin/bash
export HELLO_HOME=/usr/local/hello
export LD_LIBRARY_PATH=/usr/local/hello/lib:$LD_LIBRARY_PATH
exec /usr/local/hello/bin/hello "$@"
]]
			local f = io.open("/usr/bin/hello", "w")
			f:write(wrapper)
			f:close()
			os.execute("chmod +x /usr/bin/hello")

			table.insert(pkg.files, "/usr/bin/hello")
			table.insert(pkg.files, "/usr/local/hello")
		end)

		hook("post_install")(function()
			print("Binary installation complete!")
			print("Verifying installation...")
			os.execute("/usr/bin/hello --version")

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
			os.execute("systemctl stop hello.service 2>/dev/null")

			print("Backing up configuration...")
			os.execute("cp /etc/hello/hello.conf /etc/hello/hello.conf.bak 2>/dev/null")
		end)

		hook("uninstall")(function()
			print("Removing " .. pkg.name .. "...")

			print("Removing binaries...")
			os.execute("rm -f /usr/bin/hello")
			os.execute("rm -f /usr/local/bin/hello")

			print("Removing libraries...")
			os.execute("rm -rf /usr/local/hello")

			print("Removing man pages...")
			os.execute("rm -f /usr/share/man/man1/hello.1.gz")

			print("Removing configuration...")
			os.execute("rm -rf /etc/hello")
		end)

		hook("post_uninstall")(function()
			print("Cleanup...")

			print("Updating man database...")
			os.execute("mandb -q")

			print("Removing user group...")
			os.execute("groupdel hello-users 2>/dev/null")

			print("Removing cache files...")
			os.execute("rm -rf /var/cache/hello")

			print("")
			print(pkg.name .. " has been uninstalled")
			print("Configuration backup: /etc/hello/hello.conf.bak")
		end)
	end
end

function pkg.upgrade()
	return function(from_version)
		print("Upgrading from " .. from_version .. " to " .. pkg.version)

		if from_version:match("^1%.") then
			print("Major version upgrade detected")
			print("Migrating configuration format...")
			os.execute("hello-config-migrate /etc/hello/hello.conf")
		end

		if from_version < "2.0.0" then
			print("Database schema update required...")
			os.execute("hello-db-upgrade")
		end

		print("Upgrade hooks complete")
	end
end
