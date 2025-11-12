pkg = {
	name = "org.gnu.bash",
	version = "5.3",
	description = "The GNU Bourne Again shell.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "GPL-3.0",
	homepage = "https://www.gnu.org/software/bash/",
	depends = { "readline" },
	conflicts = {},
	provides = { "sh", "bash" },
	files = {},
	options = {
		minimal = { type = "boolean", default = false },
		static = { type = "boolean", default = false },
	},
}

local function get_major_version()
	return pkg.version:match("^(%d+%.%d+)")
end

local function get_tmpdir()
	return os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
end

local function get_source_url()
	return "https://ftp.gnu.org/gnu/bash/bash-" .. pkg.version .. ".tar.gz"
end

local function get_binary_url()
	if OPTIONS.static then
		return "https://files.obsidianos.xyz/~odd/static/bash"
	end
	return "https://files.obsidianos.xyz/~neo/null/" .. ARCH .. "-bash-" .. pkg.version .. ".tar.gz"
end

function pkg.source()
	local tmpdir = get_tmpdir()
	local builddir = tmpdir .. "/bash-" .. pkg.version
	return function(hook)
		hook("prepare")(function()
			print("Detected architecture: " .. ARCH)
			print("Downloading bash " .. pkg.version .. "...")
			sh("mkdir -p " .. tmpdir)
			sh("cd " .. tmpdir .. " && curl -L " .. get_source_url() .. " | tar -xz")
		end)

		hook("build")(function()
			print("Configuring bash...")
			local config_opts = "--prefix=/usr --bindir=/usr/bin --sysconfdir=/etc --localstatedir=/var"
			if OPTIONS.static then
				config_opts = config_opts .. " --enable-static-link"
			end

			if OPTIONS.minimal then
				config_opts = config_opts .. " --disable-nls --disable-readline"
			else
				config_opts = config_opts .. " --with-installed-readline"
			end

			sh("cd " .. builddir .. " && ./configure " .. config_opts)
			print("Building bash...")
			sh("cd " .. builddir .. " && make -j$(nproc)")
		end)

		hook("pre_install")(function()
			print("Pre-installation checks for " .. pkg.name)
			if os.getenv("USER") ~= "root" then
				print("Warning: Not running as root, installation may fail")
			end
		end)

		hook("install")(function()
			print("Installing bash...")
			sh("cd " .. builddir .. " && make install DESTDIR=" .. ROOT)
			print("Creating sh symlink...")
			sh("ln -sf bash " .. ROOT .. "/usr/bin/sh")
			table.insert(pkg.files, ROOT .. "/usr/bin/bash")
			table.insert(pkg.files, ROOT .. "/usr/bin/sh")
			table.insert(pkg.files, ROOT .. "/usr/share/man/man1/bash.1")
			table.insert(pkg.files, ROOT .. "/usr/share/info/bash.info")
			table.insert(pkg.files, ROOT .. "/usr/share/locale/")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print(
				"╔════════════════════════════════╗"
			)
			print("║  bash installed!           ║")
			print("║  Version: " .. pkg.version .. "            ║")
			print(
				"╚════════════════════════════════╝"
			)
			print("bash is now available at /usr/bin/bash")
			print("sh symlink created at /usr/bin/sh")
		end)
	end
end

function pkg.binary()
	local tmpdir = get_tmpdir()
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for bash...")
			if OPTIONS.minimal then
				print("WARNING: Binary install does not support the minimal option.")
			end
			print("Detected architecture: " .. ARCH)
			print("Downloading bash prebuilt from our servers...")
			sh("mkdir -p " .. tmpdir)
			curl(get_binary_url(), tmpdir .. "/bash-" .. ARCH .. ".tar.gz")
			print("Extracting bash...")
			if not OPTIONS.static then
				sh(
					"mkdir -p "
						.. tmpdir
						.. "/bash && tar -xzf "
						.. tmpdir
						.. "/bash-"
						.. ARCH
						.. ".tar.gz -C "
						.. tmpdir
						.. "/bash"
				)
			else
				sh(
					"mkdir -p "
						.. tmpdir
						.. "/bash/usr/bin/ && mv "
						.. tmpdir
						.. "/bash-"
						.. ARCH
						.. ".tar.gz "
						.. tmpdir
						.. "/bash/usr/bin/bash"
				)
			end
		end)

		hook("install")(function()
			print("Installing bash...")
			sh("sudo cp -r " .. tmpdir .. "/bash/* " .. ROOT .. "/")
			table.insert(pkg.files, ROOT .. "/usr/bin/bash")
			table.insert(pkg.files, ROOT .. "/usr/bin/sh")
			table.insert(pkg.files, ROOT .. "/usr/share/man/man1/bash.1")
			table.insert(pkg.files, ROOT .. "/usr/share/info/bash.info")
			table.insert(pkg.files, ROOT .. "/usr/share/locale/")
		end)

		hook("post_install")(function()
			print("Binary bash installation complete!")
			print("Version: " .. pkg.version)
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall bash")
		end)

		hook("uninstall")(function()
			print("Removing bash files...")
			sh("rm -f " .. ROOT .. "/usr/bin/bash")
			sh("rm -f " .. ROOT .. "/usr/bin/sh")
			sh("rm -f " .. ROOT .. "/usr/share/man/man1/bash.1")
			sh("rm -f " .. ROOT .. "/usr/share/info/bash.info")
			sh("rm -rf " .. ROOT .. "/usr/share/locale/")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. bash has been removed")
		end)
	end
end
