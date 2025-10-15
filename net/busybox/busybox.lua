pkg = {
	name = "net.busybox.busybox",
	version = "1.36.1",
	description = "The Swiss Army Knife of Embedded Linux",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "GPL-2.0",
	homepage = "https://git.busybox.net/busybox",
	depends = {},
	conflicts = {},
	provides = { "busybox" },
	files = {},
}

function pkg.source()
	return function(hook)
		hook("prepare")(function()
			print("Preparing config file...")
			wget(
				"https://raw.githubusercontent.com/NULL-GNU-Linux/busybox/refs/heads/main/" .. pkg.version,
				"/tmp/busybox-config-" .. pkg.version
			)
			print("Preparing BusyBox source...")
			local url = "https://github.com/mirror/busybox/archive/refs/tags/"
				.. pkg.version:gsub("%.", "_")
				.. ".tar.gz"
			wget(url, "/tmp/busybox-" .. pkg.version .. ".tar.gz")
			sh("tar -xzf /tmp/busybox-" .. pkg.version .. ".tar.gz -C /tmp")
		end)

		hook("build")(function()
			print("Configuring BusyBox...")
			sh("cp /tmp/busybox-config-" .. pkg.version .. "/tmp/busybox-" .. pkg.version:gsub("%.", "_") .. "/.config")
			sh("cd /tmp/busybox-" .. pkg.version:gsub("%.", "_") .. ' && (yes "" | make oldconfig)')
			print("Building BusyBox...")
			os.execute("cd /tmp/busybox-" .. pkg.version:gsub("%.", "_") .. " && make -j$(nproc)")
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
			install(
				"../../../../../../tmp/busybox-" .. pkg.version:gsub("%.", "_") .. "/busybox", -- a very weird way of getting to /
				"/usr/bin/busybox",
				"755"
			)
			sh("chown root:root " .. ROOT .. "/usr/bin/busybox")

			print("Creating symlinks for applets...")
			sh(
				ROOT
					.. "/usr/bin/busybox --list | while read applet; do ln -sf /usr/bin/busybox "
					.. ROOT
					.. "/usr/bin/$applet 2>/dev/null || true; done"
			)
			table.insert(pkg.files, ROOT .. "/usr/bin/busybox")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print("")
			print(
				"╔════════════════════════════════════════╗"
			)
			print("║  " .. pkg.provides[1] .. " installed!             ║")
			print("║  Version: " .. pkg.version .. "                    ║")
			print(
				"╚════════════════════════════════════════╝"
			)
			print("")
			sh(ROOT .. "/usr/bin/busybox | head -n 1")
		end)
	end
end

function pkg.binary()
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for " .. pkg.name)
			local arch = io.popen("uname -m"):read("*all"):gsub("%s+", "")
			print("Detected architecture: " .. arch)

			local arch_map = {
				x86_64 = "x86_64",
				aarch64 = "armv8l",
				armv7l = "armv7l",
				i686 = "i686",
			}

			local busybox_arch = arch_map[arch]
			if not busybox_arch then
				error("Binary package not available for architecture: " .. arch)
			end

			print("Downloading BusyBox binary...")
			local url = "https://github.com/docker-library/busybox/raw/dist-"
				.. busybox_arch
				.. "/stable/glibc/busybox.tar.xz"
			curl(url, "/tmp/busybox-binary.tar.xz")
			sh("tar -xJf /tmp/busybox-binary.tar.xz -C /tmp")
			sh("cp /tmp/bin/busybox /tmp/busybox-binary")
		end)

		hook("install")(function()
			print("Installing binary files...")
			install("/tmp/busybox-binary", "/usr/bin/busybox", "755")
			sh("chown root:root " .. ROOT .. "/usr/bin/busybox")
			table.insert(pkg.files, ROOT .. "/usr/bin/busybox")

			print("Creating symlinks for applets...")
			sh(
				ROOT
					.. "/usr/bin/busybox --list | while read applet; do ln -sf /usr/bin/busybox "
					.. ROOT
					.. "/usr/bin/$applet 2>/dev/null || true; done"
			)
		end)

		hook("post_install")(function()
			print("Binary installation complete!")
			print("Verifying installation...")
			sh(ROOT .. "/usr/bin/busybox --help | head -n 1")
			print("")
			print("Installation successful!")
			print("BusyBox provides " .. sh(ROOT .. "/usr/bin/busybox --list | wc -l") .. " applets")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall " .. pkg.name)
			print("Backing up applet list...")
			sh(ROOT .. "/usr/bin/busybox --list > /tmp/busybox-applets.txt 2>/dev/null || true")
		end)

		hook("uninstall")(function()
			print("Removing " .. pkg.name .. "...")

			print("Removing applet symlinks...")
			sh(
				"if [ -f /tmp/busybox-applets.txt ]; then while read applet; do rm -f "
					.. ROOT
					.. "/usr/bin/$applet 2>/dev/null || true; done < /tmp/busybox-applets.txt; fi"
			)

			print("Removing busybox binary...")
			uninstall("/usr/bin/busybox")
		end)

		hook("post_uninstall")(function()
			print("Cleanup...")
			sh("rm -f /tmp/busybox-applets.txt /tmp/busybox-binary /tmp/busybox-*.tar.gz /tmp/busybox-*.tar.xz")
			print("")
			print(pkg.name .. " has been uninstalled")
		end)
	end
end

function pkg.upgrade()
	return function(from_version)
		print("Upgrading BusyBox from " .. from_version .. " to " .. pkg.version)

		print("Backing up current applet list...")
		sh(ROOT .. "/usr/bin/busybox --list > /tmp/busybox-applets-old.txt 2>/dev/null || true")

		print("Upgrade preparation complete")
	end
end
