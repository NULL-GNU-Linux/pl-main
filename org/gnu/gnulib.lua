pkg = {
	name = "org.gnu.gnulib",
	version = "1.0",
	description = "GNU Portability Library - A collection of portable C functions.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "GPL-3.0-or-later",
	homepage = "https://www.gnu.org/software/gnulib/",
	depends = {},
	conflicts = {},
	provides = { "gnulib" },
	files = {},
	options = {
		install_docs = { type = "boolean", default = true },
		install_tests = { type = "boolean", default = false },
	},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	local GNULIB_BASE_URL = "https://github.com/coreutils/gnulib/archive/refs/tags/v" .. pkg.version .. ".tar.gz"
	return function(hook)
		hook("prepare")(function()
			print("Detected architecture: " .. ARCH)
			print("Downloading gnulib version " .. pkg.version .. "...")
			sh("mkdir -p " .. tmpdir)
			sh("cd " .. tmpdir .. " && curl -L " .. GNULIB_BASE_URL .. " | tar -xz")
		end)

		hook("build")(function()
			print("Building gnulib...")
			sh("cd " .. tmpdir .. "/gnulib-" .. pkg.version .. " && ./gnulib-tool --version")
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
			print("Installing gnulib to " .. ROOT .. "/usr/share/gnulib...")
			sh("mkdir -p " .. ROOT .. "/usr/share/gnulib")
			sh("mkdir -p " .. ROOT .. "/usr/bin")
			sh("cp -r " .. tmpdir .. "/gnulib-" .. pkg.version .. "/* " .. ROOT .. "/usr/share/gnulib/")
			sh("ln -sf /usr/share/gnulib/gnulib-tool " .. ROOT .. "/usr/bin/gnulib-tool")
			if not OPTIONS.install_docs then
				print("Removing documentation...")
				sh("rm -rf " .. ROOT .. "/usr/share/gnulib/doc")
			end

			if not OPTIONS.install_tests then
				print("Removing tests...")
				sh("find " .. ROOT .. "/usr/share/gnulib -type d -name 'tests' -exec rm -rf {} + 2>/dev/null || true")
			end

			table.insert(pkg.files, ROOT .. "/usr/share/gnulib/")
			table.insert(pkg.files, ROOT .. "/usr/bin/gnulib-tool")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print(
				"╔════════════════════════════════╗"
			)
			print("║  gnulib installed!         ║")
			print("║  Version: " .. pkg.version .. "          ║")
			print(
				"╚════════════════════════════════╝"
			)
			print("Run 'gnulib-tool --help' to get started")
		end)
	end
end

function pkg.binary()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	local BINARY_BASE_URL = "https://files.obsidianos.xyz/~neo/null/" .. ARCH .. "-gnulib-" .. pkg.version .. ".tar.gz"
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for gnulib...")
			if not OPTIONS.install_docs then
				print("WARNING: Binary install includes all components, install_docs option ignored.")
			end
			if not OPTIONS.install_tests then
				print("WARNING: Binary install includes all components, install_tests option ignored.")
			end
			print("Detected architecture: " .. ARCH)
			print("Downloading gnulib prebuilt version " .. pkg.version .. "...")
			sh("mkdir -p " .. tmpdir)
			curl(BINARY_BASE_URL, tmpdir .. "/gnulib-" .. ARCH .. ".tar.gz")
			print("Extracting gnulib...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/gnulib && tar -xzf "
					.. tmpdir
					.. "/gnulib-"
					.. ARCH
					.. ".tar.gz -C "
					.. tmpdir
					.. "/gnulib"
			)
		end)

		hook("install")(function()
			print("Installing gnulib...")
			sh("cp -r " .. tmpdir .. "/gnulib/* " .. ROOT .. "/")
			table.insert(pkg.files, ROOT .. "/usr/share/gnulib/")
			table.insert(pkg.files, ROOT .. "/usr/bin/gnulib-tool")
		end)

		hook("post_install")(function()
			print("Binary gnulib installation complete!")
			print("Run 'gnulib-tool --help' to get started")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall gnulib")
		end)

		hook("uninstall")(function()
			print("Removing gnulib files...")
			sh("rm -rf " .. ROOT .. "/usr/share/gnulib/")
			sh("rm -f " .. ROOT .. "/usr/bin/gnulib-tool")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. gnulib has been removed")
		end)
	end
end
