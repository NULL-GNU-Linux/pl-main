pkg = {
	name = "org.gnu.m4",
	version = "1.4.20",
	description = "GNU M4 macro processor.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "GPL-3.0",
	homepage = "https://www.gnu.org/software/m4/",
	depends = {},
	conflicts = {},
	provides = { "m4" },
	files = {},
	options = {
		enable_changeword = { type = "boolean", default = false },
		disable_nls = { type = "boolean", default = false },
	},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	local major_minor = pkg.version:match("(%d+%.%d+)")
	local source_url = "https://ftp.gnu.org/gnu/m4/m4-" .. pkg.version .. ".tar.xz"
	local extract_dir = tmpdir .. "/m4-" .. pkg.version
	return function(hook)
		hook("prepare")(function()
			print("Detected architecture: " .. ARCH)
			print("Downloading GNU M4 " .. pkg.version .. "...")
			sh("mkdir -p " .. tmpdir)
			sh("cd " .. tmpdir .. " && curl -L " .. source_url .. " | tar -xJ")
		end)

		hook("build")(function()
			print("Configuring GNU M4...")
			local configure_flags = "--prefix=/usr"
			if OPTIONS.enable_changeword then
				configure_flags = configure_flags .. " --enable-changeword"
			end
			if OPTIONS.disable_nls then
				configure_flags = configure_flags .. " --disable-nls"
			end
			sh("cd " .. extract_dir .. " && ./configure " .. configure_flags)
			print("Building GNU M4...")
			sh("cd " .. extract_dir .. " && make -j$(nproc)")
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
			print("Installing GNU M4...")
			sh("cd " .. extract_dir .. " && make install DESTDIR=" .. (ROOT or "/"))
			table.insert(pkg.files, ROOT .. "/usr/bin/m4")
			table.insert(pkg.files, ROOT .. "/usr/share/man/man1/m4.1")
			table.insert(pkg.files, ROOT .. "/usr/share/info/m4.info")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print(
				"╔════════════════════════════════╗"
			)
			print("║  GNU M4 installed!         ║")
			print("║  Version: " .. pkg.version .. "             ║")
			print(
				"╚════════════════════════════════╝"
			)
		end)
	end
end

function pkg.binary()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	local binary_url = "https://files.obsidianos.xyz/~neo/null/" .. ARCH .. "-m4-" .. pkg.version .. ".tar.gz"
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for GNU M4...")
			if OPTIONS.enable_changeword then
				print("WARNING: Binary install does not support the enable_changeword option.")
			end
			if OPTIONS.disable_nls then
				print("WARNING: Binary install does not support the disable_nls option.")
			end
			print("Detected architecture: " .. ARCH)
			print("Downloading GNU M4 prebuilt from our servers...")
			curl(binary_url, tmpdir .. "/m4-" .. ARCH .. ".tar.gz")
			print("Extracting GNU M4...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/m4 && tar -xzf "
					.. tmpdir
					.. "/m4-"
					.. ARCH
					.. ".tar.gz -C "
					.. tmpdir
					.. "/m4"
			)
		end)

		hook("install")(function()
			print("Installing GNU M4...")
			sh("cp -r " .. tmpdir .. "/m4/* " .. ROOT .. "/")
			table.insert(pkg.files, ROOT .. "/usr/bin/m4")
			table.insert(pkg.files, ROOT .. "/usr/share/man/man1/m4.1")
			table.insert(pkg.files, ROOT .. "/usr/share/info/m4.info")
		end)

		hook("post_install")(function()
			print("Binary GNU M4 installation complete!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall GNU M4")
		end)

		hook("uninstall")(function()
			print("Removing GNU M4 files...")
			sh("rm -f " .. ROOT .. "/usr/bin/m4")
			sh("rm -rf " .. ROOT .. "/usr/share/man/man1/m4.1")
			sh("rm -rf " .. ROOT .. "/usr/share/info/m4.info")
			sh("rm -rf " .. ROOT .. "/usr/share/info/m4.info-*")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. GNU M4 has been removed")
		end)
	end
end
