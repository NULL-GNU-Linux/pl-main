pkg = {
	name = "org.boot.grub",
	version = "2.12",
	description = "GNU GRUB bootloader.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "GPL-3.0",
	homepage = "https://www.gnu.org/software/grub/",
	depends = {},
	conflicts = {},
	provides = { "grub", "bootloader" },
	files = {},
	options = {
		efi = { type = "boolean", default = true },
		bios = { type = "boolean", default = true },
		emu = { type = "boolean", default = false },
	},
}

local major_version = pkg.version:match("^(%d+%.%d+)")
local tarball_name = "grub-" .. pkg.version .. ".tar.xz"
local source_url = "https://ftp.gnu.org/gnu/grub/" .. tarball_name
local binary_url = "https://files.obsidianos.xyz/~neo/null/" .. ARCH .. "-grub.tar.gz"

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	srcdir = tmpdir .. "/grub-" .. pkg.version
	local target_arch = ARCH == "x86_64" and "x86_64" or "i386"
	local build_platforms = {}

	if OPTIONS.bios then
		table.insert(build_platforms, "i386-pc")
	end
	if OPTIONS.efi then
		table.insert(build_platforms, target_arch .. "-efi")
		if ARCH == "x86_64" then
			table.insert(build_platforms, "i386-efi")
		end
	end
	if OPTIONS.emu then
		table.insert(build_platforms, target_arch .. "-emu")
	end

	return function(hook)
		hook("prepare")(function()
			print("Detected architecture: " .. ARCH)
			print("Downloading GRUB source...")
			sh("rm -rf " .. tmpdir)
			sh("mkdir -p " .. tmpdir)
			sh("cd " .. tmpdir .. " && curl -L " .. source_url .. " | tar -xJ")

			print("Cloning grub-extras...")
			sh("cd " .. tmpdir .. " && git clone --depth=1 https://git.savannah.gnu.org/git/grub-extras.git")

			print("Cloning gnulib...")
			sh("cd " .. tmpdir .. " && git clone --depth=1 https://git.savannah.gnu.org/git/gnulib.git")

			print("Removing incompatible lua module...")
			sh("rm -rf " .. tmpdir .. "/grub-extras/lua")

			print("Running autogen...")
			sh(
				"cd "
					.. srcdir
					.. " && export GRUB_CONTRIB="
					.. tmpdir
					.. "/grub-extras && export GNULIB_SRCDIR="
					.. tmpdir
					.. "/gnulib && ./autogen.sh"
			)
		end)

		hook("build")(function()
			for _, platform in ipairs(build_platforms) do
				local builddir = srcdir .. "/build_" .. platform
				print("Building for platform: " .. platform)
				sh("mkdir -p " .. builddir)

				local arch_target = platform:match("^([^-]+)")
				local arch_platform = platform:match("-(.+)$")

				sh(
					"cd "
						.. builddir
						.. " && export GRUB_CONTRIB="
						.. tmpdir
						.. "/grub-extras && export GNULIB_SRCDIR="
						.. tmpdir
						.. "/gnulib && unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS MAKEFLAGS && "
						.. srcdir
						.. "/configure "
						.. "PACKAGE_VERSION="
						.. pkg.version
						.. " "
						.. "--with-platform="
						.. arch_platform
						.. " "
						.. "--target="
						.. arch_target
						.. " "
						.. "--prefix=/usr "
						.. "--sbindir=/usr/bin "
						.. "--sysconfdir=/etc "
						.. "--enable-boot-time "
						.. "--enable-cache-stats "
						.. "--enable-device-mapper "
						.. "--enable-grub-mkfont "
						.. "--enable-grub-mount "
						.. "--enable-nls "
						.. "--disable-silent-rules "
						.. "--disable-werror"
				)

				print("Compiling " .. platform .. "...")
				sh("cd " .. builddir .. " && make -j$(nproc)")
			end
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
			print("Installing GRUB...")
			for _, platform in ipairs(build_platforms) do
				local builddir = srcdir .. "/build_" .. platform
				sh(
					"cd "
						.. builddir
						.. " && make install DESTDIR="
						.. (ROOT or "/")
						.. " bashcompletiondir=/usr/share/bash-completion/completions"
				)
			end

			print("Cleaning up unnecessary files...")
			sh("find " .. ROOT .. "/usr/lib/grub -name '*.module' -delete")
			sh("find " .. ROOT .. "/usr/lib/grub -name '*.image' -delete")
			sh("find " .. ROOT .. "/usr/lib/grub -name 'kernel.exec' -delete")
			sh("find " .. ROOT .. "/usr/lib/grub -name 'gdb_grub' -delete")
			sh("find " .. ROOT .. "/usr/lib/grub -name 'gmodule.pl' -delete")

			table.insert(pkg.files, ROOT .. "/usr/bin/grub-install")
			table.insert(pkg.files, ROOT .. "/usr/bin/grub-mkconfig")
			table.insert(pkg.files, ROOT .. "/usr/lib/grub/")
			table.insert(pkg.files, ROOT .. "/usr/share/grub/")
			table.insert(pkg.files, ROOT .. "/etc/grub.d/")
			table.insert(pkg.files, ROOT .. "/etc/default/")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print(
				"╔════════════════════════════════╗"
			)
			print("║  GRUB installed!           ║")
			print("║  Version: " .. pkg.version .. "                ║")
			print(
				"╚════════════════════════════════╝"
			)
			print("Run 'grub-install' to install to your boot device")
		end)
	end
end

function pkg.binary()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for GRUB...")
			print("Detected architecture: " .. ARCH)
			print("Downloading GRUB prebuilt from our servers...")
			sh("mkdir -p " .. tmpdir)
			curl(binary_url, tmpdir .. "/grub-" .. ARCH .. ".tar.gz")
			print("Extracting GRUB...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/grub && tar -xzf "
					.. tmpdir
					.. "/grub-"
					.. ARCH
					.. ".tar.gz -C "
					.. tmpdir
					.. "/grub"
			)
		end)

		hook("install")(function()
			print("Installing GRUB...")
			sh("cp -r " .. tmpdir .. "/grub/* " .. ROOT .. "/")
			table.insert(pkg.files, ROOT .. "/usr/bin/grub-install")
			table.insert(pkg.files, ROOT .. "/usr/bin/grub-mkconfig")
			table.insert(pkg.files, ROOT .. "/usr/lib/grub/")
			table.insert(pkg.files, ROOT .. "/usr/share/grub/")
			table.insert(pkg.files, ROOT .. "/etc/grub.d/")
			table.insert(pkg.files, ROOT .. "/etc/default/")
		end)

		hook("post_install")(function()
			print("Binary GRUB installation complete!")
			print("Run 'grub-install' to install to your boot device")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall GRUB")
		end)

		hook("uninstall")(function()
			print("Removing GRUB files...")
			sh("rm -rf " .. ROOT .. "/usr/lib/grub/")
			sh("rm -rf " .. ROOT .. "/usr/share/grub/")
			sh("rm -rf " .. ROOT .. "/etc/grub.d/")
			sh("rm -f " .. ROOT .. "/etc/default/grub")
			sh("rm -f " .. ROOT .. "/usr/bin/grub-*")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. GRUB has been removed")
		end)
	end
end
