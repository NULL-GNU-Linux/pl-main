pkg = {
	name = "org.gnu.make",
	version = "4.4.1",
	description = "GNU Make - A tool which controls the generation of executables and other non-source files.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "GPL-3.0",
	homepage = "https://www.gnu.org/software/make/",
	depends = {},
	conflicts = {},
	provides = { "make", "gmake", "gnumake" },
	files = {},
	options = {
		disable_nls = { type = "boolean", default = false },
		enable_guile = { type = "boolean", default = false },
		static = { type = "boolean", default = false },
	},
}

function pkg.source()
	local major_version = pkg.version:match("^(%d+%.%d+)")
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	local source_dir = tmpdir .. "/make-" .. pkg.version
	return function(hook)
		hook("prepare")(function()
			print("Detected architecture: " .. ARCH)
			print("Downloading GNU Make " .. pkg.version .. "...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. " && cd "
					.. tmpdir
					.. " && curl https://ftp.gnu.org/gnu/make/make-"
					.. pkg.version
					.. ".tar.gz | tar -xz"
			)
		end)

		hook("build")(function()
			print("Configuring GNU Make...")
			local configure_flags = "--prefix=/usr"
			if OPTIONS.disable_nls then
				configure_flags = configure_flags .. " --disable-nls"
			end
			if OPTIONS.enable_guile then
				configure_flags = configure_flags .. " --with-guile"
			else
				configure_flags = configure_flags .. " --without-guile"
			end
			if OPTIONS.static then
				configure_flags = configure_flags .. " LDFLAGS=-static"
			end
			sh("cd " .. source_dir .. " && ./configure " .. configure_flags)
			print("Building GNU Make...")
			sh("cd " .. source_dir .. " && make -j$(nproc)")
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
			print("Installing GNU Make...")
			sh("cd " .. source_dir .. " && make install DESTDIR=" .. ROOT)
			table.insert(pkg.files, ROOT .. "/usr/bin/make")
			table.insert(pkg.files, ROOT .. "/usr/share/man/man1/make.1")
			table.insert(pkg.files, ROOT .. "/usr/share/info/make.info")
			table.insert(pkg.files, ROOT .. "/usr/include/gnumake.h")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print(
				"╔════════════════════════════════╗"
			)
			print("║  GNU Make installed!           ║")
			print("║  Version: " .. pkg.version .. "                ║")
			print(
				"╚════════════════════════════════╝"
			)
			sh("cd " .. ROOT .. "/usr/bin && test -L gmake || ln -s make gmake")
		end)
	end
end

function pkg.binary()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for GNU Make...")
			if OPTIONS.disable_nls or OPTIONS.enable_guile or OPTIONS.static_build then
				print("WARNING: Binary install does not support build options.")
			end
			print("Detected architecture: " .. ARCH)
			print("Downloading GNU Make prebuilt from our servers...")
			local url = "https://files.obsidianos.xyz/~neo/null/" .. ARCH .. "-make-" .. pkg.version .. ".tar.gz"
			curl(url, tmpdir .. "/make-" .. ARCH .. ".tar.gz")
			print("Extracting GNU Make...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/make && tar -xzf "
					.. tmpdir
					.. "/make-"
					.. ARCH
					.. ".tar.gz -C "
					.. tmpdir
					.. "/make"
			)
		end)

		hook("install")(function()
			print("Installing GNU Make...")
			sh("cp -r " .. tmpdir .. "/make/* " .. ROOT .. "/")
			table.insert(pkg.files, ROOT .. "/usr/bin/make")
			table.insert(pkg.files, ROOT .. "/usr/share/man/man1/make.1")
			table.insert(pkg.files, ROOT .. "/usr/share/info/make.info")
			table.insert(pkg.files, ROOT .. "/usr/include/gnumake.h")
		end)
		hook("post_install")(function()
			print("Binary GNU Make installation complete!")
			sh("cd " .. ROOT .. "/usr/bin && test -L gmake || ln -s make gmake")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall GNU Make")
		end)

		hook("uninstall")(function()
			print("Removing GNU Make files...")
			sh("rm -f " .. ROOT .. "/usr/bin/make")
			sh("rm -f " .. ROOT .. "/usr/bin/gmake")
			sh("rm -f " .. ROOT .. "/usr/share/man/man1/make.1")
			sh("rm -f " .. ROOT .. "/usr/share/info/make.info")
			sh("rm -f " .. ROOT .. "/usr/include/gnumake.h")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. GNU Make has been removed")
		end)
	end
end
