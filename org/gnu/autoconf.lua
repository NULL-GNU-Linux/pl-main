pkg = {
	name = "org.gnu.autoconf",
	version = "2.72",
	description = "Automatic configure script builder.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "GPL-3.0",
	homepage = "https://www.gnu.org/software/autoconf/",
	depends = { "m4" },
	conflicts = {},
	provides = { "autoconf" },
	files = {},
	options = {
		enable_docs = { type = "boolean", default = true },
		enable_tests = { type = "boolean", default = false },
		extra_configs = { type = "string", default = "" },
	},
}

function pkg.source()
	local tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	local srcdir = tmpdir .. "/autoconf-" .. pkg.version
	local major_version = pkg.version:match("^(%d+%.%d+)")
	return function(hook)
		hook("prepare")(function()
			print("Downloading autoconf " .. pkg.version .. "...")
			sh("mkdir -p " .. tmpdir)
			sh(
				"cd "
					.. tmpdir
					.. " && curl https://ftp.gnu.org/gnu/autoconf/autoconf-"
					.. pkg.version
					.. ".tar.xz | tar -xJ"
			)
		end)

		hook("build")(function()
			print("Configuring autoconf...")
			local configure_opts = "--prefix=/usr " .. OPTIONS.extra_configs
			if not OPTIONS.enable_docs then
				configure_opts = configure_opts .. " --disable-doc"
			end
			sh("cd " .. srcdir .. " && ./configure " .. configure_opts)
			print("Building autoconf...")
			sh("cd " .. srcdir .. " && make -j$(nproc)")

			if OPTIONS.enable_tests then
				print("Running test suite...")
				sh("cd " .. srcdir .. " && make check")
			end
		end)

		hook("pre_install")(function()
			print("Pre-installation checks for " .. pkg.name)
			local space_check = io.popen("df -h " .. ROOT .. "/usr | tail -1 | awk '{print $4}'")
			local available = space_check:read("*all")
			space_check:close()
			print("Available space: " .. available)
		end)

		hook("install")(function()
			print("Installing autoconf...")
			sh("cd " .. srcdir .. " && make DESTDIR=" .. (ROOT or "") .. " install")

			table.insert(pkg.files, ROOT .. "/usr/bin/autoconf")
			table.insert(pkg.files, ROOT .. "/usr/bin/autoheader")
			table.insert(pkg.files, ROOT .. "/usr/bin/autom4te")
			table.insert(pkg.files, ROOT .. "/usr/bin/autoreconf")
			table.insert(pkg.files, ROOT .. "/usr/bin/autoscan")
			table.insert(pkg.files, ROOT .. "/usr/bin/autoupdate")
			table.insert(pkg.files, ROOT .. "/usr/bin/ifnames")
			table.insert(pkg.files, ROOT .. "/usr/share/autoconf")
			if OPTIONS.enable_docs then
				table.insert(pkg.files, ROOT .. "/usr/share/info")
				table.insert(pkg.files, ROOT .. "/usr/share/man")
			end
		end)

		hook("post_install")(function()
			print(
				"╔════════════════════════════════╗"
			)
			print("║  autoconf installed!           ║")
			print("║  Version: " .. pkg.version .. "                 ║")
			print(
				"╚════════════════════════════════╝"
			)
		end)
	end
end

function pkg.binary()
	local tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name

	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for autoconf...")
			if OPTIONS.enable_tests then
				print("WARNING: Binary install does not support the enable_tests option.")
			end
			print("Detected architecture: " .. ARCH)
			print("Downloading autoconf prebuilt...")
			local url = "https://files.obsidianos.xyz/~neo/null/" .. ARCH .. "-autoconf-" .. pkg.version .. ".tar.gz"
			curl(url, tmpdir .. "/autoconf-" .. ARCH .. ".tar.gz")
			print("Extracting autoconf...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/autoconf && tar -xzf "
					.. tmpdir
					.. "/autoconf-"
					.. ARCH
					.. ".tar.gz -C "
					.. tmpdir
					.. "/autoconf"
			)
		end)

		hook("install")(function()
			print("Installing autoconf...")
			sh("cp -r " .. tmpdir .. "/autoconf/* " .. ROOT .. "/")

			table.insert(pkg.files, ROOT .. "/usr/bin/autoconf")
			table.insert(pkg.files, ROOT .. "/usr/bin/autoheader")
			table.insert(pkg.files, ROOT .. "/usr/bin/autom4te")
			table.insert(pkg.files, ROOT .. "/usr/bin/autoreconf")
			table.insert(pkg.files, ROOT .. "/usr/bin/autoscan")
			table.insert(pkg.files, ROOT .. "/usr/bin/autoupdate")
			table.insert(pkg.files, ROOT .. "/usr/bin/ifnames")
			table.insert(pkg.files, ROOT .. "/usr/share/autoconf")
			if OPTIONS.enable_docs then
				table.insert(pkg.files, ROOT .. "/usr/share/info")
				table.insert(pkg.files, ROOT .. "/usr/share/man")
			end
		end)

		hook("post_install")(function()
			print("Binary autoconf installation complete!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall autoconf")
		end)

		hook("uninstall")(function()
			print("Removing autoconf files...")
			for _, file in ipairs(pkg.files) do
				sh("rm -rf " .. file)
			end
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. autoconf has been removed")
		end)
	end
end
