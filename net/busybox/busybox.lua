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
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("prepare")(function()
			print("Preparing config file...")
			wget(
				"https://raw.githubusercontent.com/NULL-GNU-Linux/busybox/refs/heads/main/" .. pkg.version,
				tmpdir .. "/busybox-config-" .. pkg.version
			)
			print("Preparing BusyBox source...")
			local url = "https://github.com/mirror/busybox/archive/refs/tags/"
				.. pkg.version:gsub("%.", "_")
				.. ".tar.gz"
			wget(url, tmpdir .. "/busybox-" .. pkg.version .. ".tar.gz")
			sh("tar -xzf " .. tmpdir .. "/busybox-" .. pkg.version .. ".tar.gz -C " .. tmpdir)
		end)

		hook("build")(function()
			print("Configuring BusyBox...")
			sh(
				"cp "
					.. tmpdir
					.. "/busybox-config-"
					.. pkg.version
					.. " "
					.. tmpdir
					.. "/busybox-"
					.. pkg.version:gsub("%.", "_")
					.. "/.config"
			)
			sh("cd " .. tmpdir .. "/busybox-" .. pkg.version:gsub("%.", "_") .. ' && (yes "" | make oldconfig)')
			print("Building BusyBox...")
			os.execute(
				"cd " .. tmpdir .. "/busybox-" .. pkg.version:gsub("%.", "_") .. " && make CC=musl-gcc -j$(nproc)"
			)
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
				tmpdir .. "/busybox-" .. pkg.version:gsub("%.", "_") .. "/busybox", -- a very weird way of getting to /
				"/usr/bin/busybox",
				"755"
			)
			if not OPTIONS.no_symlinks then
				print("Creating symlinks for applets...")
				sh(
					ROOT .. "/usr/bin/busybox --list | grep -xv 'busybox' | while read applet; do " ..
					"[ ! -e '" .. ROOT .. "/usr/bin/$applet' ] && ln -s /usr/bin/busybox '" .. ROOT .. "/usr/bin/$applet' || true; " ..
					"done"
				)
			end
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
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for " .. pkg.name)
			local arch = io.popen("uname -m"):read("*all"):gsub("%s+", "")
			print("Detected architecture: " .. arch)

			local arch_map = {
				x86_64 = "amd64",
				aarch64 = "armv8l",
				armv7l = "armv7l",
				i686 = "i686",
			}

			local busybox_arch = arch_map[arch]
			if not busybox_arch then
				error("Binary package not available for architecture: " .. arch)
			end

			print("Downloading BusyBox binary...")
			local url = "https://github.com/docker-library/busybox/raw/refs/heads/dist-"
				.. busybox_arch
				.. "/latest/musl/"
				.. busybox_arch
				.. "/rootfs.tar.gz"
			curl(url, tmpdir .. "/busybox-binary.tar.gz")
			sh("sudo tar -xzf " .. tmpdir .. "/busybox-binary.tar.gz -C " .. tmpdir)
			sh("sudo cp " .. tmpdir .. "/bin/busybox " .. tmpdir .. "/busybox-binary")
		end)

		hook("install")(function()
			print("Installing binary files...")
			install(tmpdir .. "/busybox-binary", "/usr/bin/busybox", "755")
			table.insert(pkg.files, ROOT .. "/usr/bin/busybox")
			print("Creating symlinks for applets...")
			sh(
				ROOT .. "/usr/bin/busybox --list | grep -xv 'busybox' | while read applet; do " ..
				"[ ! -e '" .. ROOT .. "/usr/bin/$applet' ] && ln -s /usr/bin/busybox '" .. ROOT .. "/usr/bin/$applet' || true; " ..
				"done"
			)
		end)

		hook("post_install")(function()
			print("Binary installation complete!")
			print("Verifying installation...")
			sh(ROOT .. "/usr/bin/busybox --help | head -n 1")
			print("")
			print("Installation successful!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall " .. pkg.name)
			print("Backing up applet list...")
			sh(
				ROOT
					.. '/usr/bin/busybox --list | grep -xv "busybox" > '
					.. tmpdir
					.. "/busybox-applets.txt 2>/dev/null || true"
			)
		end)

		hook("uninstall")(function()
			print("Removing " .. pkg.name .. "...")

			print("Removing applet symlinks...")
			sh(
				"if [ -f "
					.. tmpdir
					.. "/busybox-applets.txt ]; then while read applet; do rm -f "
					.. ROOT
					.. "/usr/bin/$applet 2>/dev/null || true; done < "
					.. tmpdir
					.. "/busybox-applets.txt; fi"
			)

			print("Removing busybox binary...")
			uninstall("/usr/bin/busybox")
		end)

		hook("post_uninstall")(function()
			print("Cleanup...")
			sh(
				"rm -f "
					.. tmpdir
					.. "/busybox-applets.txt "
					.. tmpdir
					.. "/busybox-binary "
					.. tmpdir
					.. "/busybox-*.tar.gz "
					.. tmpdir
					.. "/busybox-*.tar.xz"
			)
			print("")
			print(pkg.name .. " has been uninstalled")
		end)
	end
end

function pkg.upgrade()
	return function(from_version)
		print("Upgrading BusyBox from " .. from_version .. " to " .. pkg.version)

		print("Backing up current applet list...")
		sh(ROOT .. "/usr/bin/busybox --list > " .. tmpdir .. "/busybox-applets-old.txt 2>/dev/null || true")

		print("Upgrade preparation complete")
	end
end
