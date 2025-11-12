pkg = {
	name = "org.gnu.readline",
	version = "8.3",
	description = "GNU Readline library for command-line editing.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "GPL-3.0",
	homepage = "https://tiswww.case.edu/php/chet/readline/rltop.html",
	depends = {},
	conflicts = {},
	provides = { "readline" },
	files = {},
	options = {
		static = { type = "boolean", default = false },
		multibyte = { type = "boolean", default = true },
	},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	local major_version = pkg.version:match("^(%d+%.%d+)")
	return function(hook)
		hook("prepare")(function()
			print("Detected architecture: " .. ARCH)
			print("Downloading readline " .. pkg.version .. "...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. " && cd "
					.. tmpdir
					.. " && curl https://ftp.gnu.org/gnu/readline/readline-"
					.. pkg.version
					.. ".tar.gz | tar -xz"
			)
		end)

		hook("build")(function()
			print("Configuring readline...")
			local configure_flags = "--prefix=/usr"
			if OPTIONS.static then
				configure_flags = configure_flags .. " --enable-static"
			end
			if not OPTIONS.multibyte then
				configure_flags = configure_flags .. " --disable-multibyte"
			end
			sh("cd " .. tmpdir .. "/readline-" .. pkg.version .. " && ./configure " .. configure_flags)
			print("Building readline...")
			sh("cd " .. tmpdir .. "/readline-" .. pkg.version .. " && make -j$(nproc)")
		end)

		hook("pre_install")(function()
			print("Pre-installation checks for " .. pkg.name)
			if os.getenv("USER") ~= "root" then
				print("Warning: Not running as root, installation may fail")
			end
		end)

		hook("install")(function()
			print("Installing readline...")
			sh("cd " .. tmpdir .. "/readline-" .. pkg.version .. " && make install DESTDIR=" .. (ROOT or "/"))
			table.insert(pkg.files, ROOT .. "/usr/lib/libreadline.so")
			table.insert(pkg.files, ROOT .. "/usr/lib/libhistory.so")
			table.insert(pkg.files, ROOT .. "/usr/include/readline/")
			table.insert(pkg.files, ROOT .. "/usr/share/man/man3/readline.3")
			table.insert(pkg.files, ROOT .. "/usr/share/info/readline.info")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print(
				"╔════════════════════════════════╗"
			)
			print("║  Readline installed!           ║")
			print("║  Version: " .. pkg.version .. "                ║")
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
			print("Preparing binary installation for readline...")
			if OPTIONS.static then
				print("WARNING: Binary install does not support the static option.")
			end
			if not OPTIONS.multibyte then
				print("WARNING: Binary install does not support disabling multibyte.")
			end
			print("Detected architecture: " .. ARCH)
			print("Downloading readline prebuilt from our servers...")
			local url = "https://files.obsidianos.xyz/~neo/null/" .. ARCH .. "-readline-" .. pkg.version .. ".tar.gz"
			curl(url, tmpdir .. "/readline-" .. ARCH .. ".tar.gz")
			print("Extracting readline...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/readline && tar -xzf "
					.. tmpdir
					.. "/readline-"
					.. ARCH
					.. ".tar.gz -C "
					.. tmpdir
					.. "/readline"
			)
		end)

		hook("install")(function()
			print("Installing readline...")
			sh("cp -r " .. tmpdir .. "/readline/* " .. ROOT .. "/")
			table.insert(pkg.files, ROOT .. "/usr/lib/libreadline.so")
			table.insert(pkg.files, ROOT .. "/usr/lib/libhistory.so")
			table.insert(pkg.files, ROOT .. "/usr/include/readline/")
			table.insert(pkg.files, ROOT .. "/usr/share/man/man3/readline.3")
			table.insert(pkg.files, ROOT .. "/usr/share/info/readline.info")
		end)

		hook("post_install")(function()
			print("Binary readline installation complete!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall readline")
		end)

		hook("uninstall")(function()
			print("Removing readline files...")
			sh("rm -rf " .. ROOT .. "/usr/lib/libreadline*")
			sh("rm -rf " .. ROOT .. "/usr/lib/libhistory*")
			sh("rm -rf " .. ROOT .. "/usr/include/readline/")
			sh("rm -rf " .. ROOT .. "/usr/share/man/man3/readline.3")
			sh("rm -rf " .. ROOT .. "/usr/share/info/readline.info")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. Readline has been removed")
		end)
	end
end
