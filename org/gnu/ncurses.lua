pkg = {
	name = "org.gnu.ncurses",
	version = "6.5",
	description = "System V Release 4.0 curses emulation library.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "MIT",
	homepage = "https://invisible-island.net/ncurses/",
	depends = {},
	conflicts = {},
	provides = { "ncurses" },
	files = {},
	options = {
		enable_widec = { type = "boolean", default = true },
		enable_ext_colors = { type = "boolean", default = true },
		with_cxx_binding = { type = "boolean", default = true },
		extra_configs = { type = "string", default = "" },
	},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	local major_version = pkg.version:match("^(%d+)%.%d+")
	local srcdir = tmpdir .. "/ncurses-" .. pkg.version
	return function(hook)
		hook("prepare")(function()
			print("Detected architecture: " .. ARCH)
			print("Downloading ncurses source...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. " && cd "
					.. tmpdir
					.. " && curl https://ftp.gnu.org/gnu/ncurses/ncurses-"
					.. pkg.version
					.. ".tar.gz | tar -xz"
			)
		end)

		hook("build")(function()
			print("Configuring ncurses...")
			local configure_opts =
				"./configure --prefix=/usr --with-shared --without-debug --enable-pc-files --with-pkg-config-libdir=/usr/lib/pkgconfig " .. OPTIONS.extra_configs

			if OPTIONS.enable_widec then
				configure_opts = configure_opts .. " --enable-widec"
			end

			if OPTIONS.enable_ext_colors then
				configure_opts = configure_opts .. " --enable-ext-colors"
			end

			if OPTIONS.with_cxx_binding then
				configure_opts = configure_opts .. " --with-cxx-binding"
			end
			sh("cd " .. srcdir .. " && " .. configure_opts)
			print("Building ncurses...")
			sh("cd " .. srcdir .. " && make -j$(nproc)")
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
			print("Installing ncurses...")
			sh("cd " .. srcdir .. " && make install DESTDIR=" .. (ROOT or "/"))
			table.insert(pkg.files, ROOT .. "/usr/lib/libncurses*")
			table.insert(pkg.files, ROOT .. "/usr/include/ncurses*")
			table.insert(pkg.files, ROOT .. "/usr/include/*.h")
			table.insert(pkg.files, ROOT .. "/usr/share/terminfo/")
			table.insert(pkg.files, ROOT .. "/usr/bin/")
			table.insert(pkg.files, ROOT .. "/usr/lib/pkgconfig/")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print(
				"╔════════════════════════════════╗"
			)
			print("║  ncurses installed!        ║")
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
			print("Preparing binary installation for ncurses...")
			if OPTIONS.enable_widec then
				print("INFO: Binary built with wide character support")
			end
			if OPTIONS.enable_ext_colors then
				print("INFO: Binary built with extended colors support")
			end
			if OPTIONS.with_cxx_binding then
				print("INFO: Binary built with C++ bindings")
			end
			print("Detected architecture: " .. ARCH)
			print("Downloading ncurses prebuilt from our servers...")
			local url = "https://files.obsidianos.xyz/~neo/null/" .. ARCH .. "-ncurses-" .. pkg.version .. ".tar.gz"
			curl(url, tmpdir .. "/ncurses-" .. ARCH .. ".tar.gz")
			print("Extracting ncurses...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/ncurses && tar -xzf "
					.. tmpdir
					.. "/ncurses-"
					.. ARCH
					.. ".tar.gz -C "
					.. tmpdir
					.. "/ncurses"
			)
		end)

		hook("install")(function()
			print("Installing ncurses...")
			sh("cp -r " .. tmpdir .. "/ncurses/* " .. ROOT .. "/")
			table.insert(pkg.files, ROOT .. "/usr/lib/libncurses*")
			table.insert(pkg.files, ROOT .. "/usr/include/ncurses*")
			table.insert(pkg.files, ROOT .. "/usr/include/*.h")
			table.insert(pkg.files, ROOT .. "/usr/share/terminfo/")
			table.insert(pkg.files, ROOT .. "/usr/bin/")
			table.insert(pkg.files, ROOT .. "/usr/lib/pkgconfig/")
		end)

		hook("post_install")(function()
			print("Binary ncurses installation complete!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall ncurses")
		end)

		hook("uninstall")(function()
			print("Removing ncurses files...")
			sh("rm -rf " .. ROOT .. "/usr/lib/libncurses*")
			sh("rm -rf " .. ROOT .. "/usr/include/ncurses*")
			sh("rm -rf " .. ROOT .. "/usr/include/curses.h")
			sh("rm -rf " .. ROOT .. "/usr/include/unctrl.h")
			sh("rm -rf " .. ROOT .. "/usr/include/term.h")
			sh("rm -rf " .. ROOT .. "/usr/share/terminfo/")
			sh("rm -rf " .. ROOT .. "/usr/bin/tic")
			sh("rm -rf " .. ROOT .. "/usr/bin/toe")
			sh("rm -rf " .. ROOT .. "/usr/bin/tput")
			sh("rm -rf " .. ROOT .. "/usr/bin/tset")
			sh("rm -rf " .. ROOT .. "/usr/bin/clear")
			sh("rm -rf " .. ROOT .. "/usr/bin/infocmp")
			sh("rm -rf " .. ROOT .. "/usr/bin/tabs")
			sh("rm -rf " .. ROOT .. "/usr/lib/pkgconfig/ncurses*.pc")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. ncurses has been removed")
		end)
	end
end
