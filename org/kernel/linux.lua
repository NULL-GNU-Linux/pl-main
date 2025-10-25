pkg = {
	name = "org.kernel.linux",
	version = "6.17.5",
	description = "The Linux Kernel.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "GPL-2.0",
	homepage = "https://kernel.org",
	depends = {},
	conflicts = {},
	provides = { "linux" },
	files = {},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("prepare")(function()
			local arch = io.popen("uname -m"):read("*all"):gsub("%s+", "")
			print("Detected architecture: " .. arch)
			print("Downloading Linux source...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "&& cd "
					.. tmpdir
					.. " && curl https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-"
					.. pkg.version
					.. ".tar.xz|tar -xJ"
			)
			sh(
				"curl https://raw.githubusercontent.com/NULL-GNU-Linux/linux/refs/heads/main/"
					.. arch
					.. ".conf -o "
					.. tmpdir
					.. "/linux-"
					.. pkg.version
					.. "/.config"
			)
		end)

		hook("build")(function()
			print("Configuring Linux...")
			sh("cd " .. tmpdir .. "/linux-" .. pkg.version .. ' && (yes "" | make oldconfig)')
			print("Building Linux...")
			sh("cd " .. tmpdir .. "/linux-" .. pkg.version .. " && make -j$(nproc)")
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
			print("Installing Linux and its modules...")
			sh(
				"cd "
					.. tmpdir
					.. "/linux-"
					.. pkg.version
					.. " && cp arch/x86/boot/bzImage "
					.. ROOT
					.. "/boot/vmlinuz-linux"
			)
			sh(
				"cd "
					.. tmpdir
					.. "/linux-"
					.. pkg.version
					.. " && make modules_install INSTALL_MOD_PATH="
					.. (ROOT or "/")
			)
			table.insert(pkg.files, ROOT .. "/boot/vmlinuz-linux")
			table.insert(pkg.files, ROOT .. "/usr/lib/modules/")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print(
				"╔════════════════════════════════╗"
			)
			print("║  Linux installed!          ║")
			print("║  Version: " .. pkg.version .. "              ║")
			print(
				"╚════════════════════════════════╝"
			)
		end)
	end
end

function pkg.binary()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for Linux...")
			local arch = io.popen("uname -m"):read("*all"):gsub("%s+", "")
			print("Detected architecture: " .. arch)
			print("Downloading Linux prebuilt from our servers...")
			local url = "https://files.obsidianos.xyz/~neo/null/" .. arch .. "-linux.tar.gz"
			curl(url, tmpdir .. "/linux-" .. arch .. ".tar.gz")
			print("Extracting Linux...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/linux && tar -xzf "
					.. tmpdir
					.. "/linux-"
					.. arch
					.. ".tar.gz -C "
					.. tmpdir
					.. "/linux"
			)
		end)

		hook("install")(function()
			print("Installing Linux...")
			sh("cp -r " .. tmpdir .. "/linux/* " .. ROOT .. "/")
			table.insert(pkg.files, ROOT .. "/boot/vmlinuz-linux")
			table.insert(pkg.files, ROOT .. "/usr/lib/modules/")
		end)

		hook("post_install")(function()
			print("Binary Linux installation complete!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall Linux")
		end)

		hook("uninstall")(function()
			print("Removing Linux files...")
			sh("rm -rf " .. ROOT .. "/usr/lib/modules/")
			sh("rm -rf " .. ROOT .. "/boot/vmlinuz-linux")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. Linux has been removed")
		end)
	end
end
