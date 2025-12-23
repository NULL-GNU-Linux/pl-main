pkg = {
	name = "org.gnu.grub",
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
		bios = { type = "boolean", default = false },
		platform = { type = "string", default = "x86_64-efi" },
	},
}

major_version = pkg.version:match("^(%d+%.%d+)")
tarball_name = "grub-" .. pkg.version .. ".tar.xz"
function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	source_url = "https://ftp.gnu.org/gnu/grub/" .. tarball_name
	srcdir = tmpdir .. "/grub-" .. pkg.version
	builddir = tmpdir .. "/build"
	return function(hook)
		hook("prepare")(function()
			print("Detected architecture: " .. ARCH)
			print("Downloading GRUB source...")
			sh("mkdir -p " .. tmpdir)
			sh("cd " .. tmpdir .. " && curl -L " .. source_url .. " | tar -xJ")
			sh("mkdir -p " .. builddir)
		end)

		hook("build")(function()
			print("Configuring GRUB...")
			local config_flags = "--prefix=/usr --sbindir=/usr/bin --sysconfdir=/etc --disable-werror"
			if OPTIONS.efi then
				config_flags = config_flags .. " --with-platform=efi --target=x86_64"
			end
			sh("cd " .. builddir .. " && " .. srcdir .. "/configure " .. config_flags)
			print("Building GRUB...")
			sh("cd " .. builddir .. " && make -j$(nproc)")
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
			sh("cd " .. builddir .. " && make install DESTDIR=" .. (ROOT or "/"))
			table.insert(pkg.files, ROOT .. "/usr/bin/grub-install")
			table.insert(pkg.files, ROOT .. "/usr/bin/grub-mkconfig")
			table.insert(pkg.files, ROOT .. "/usr/lib/grub/")
			table.insert(pkg.files, ROOT .. "/usr/share/grub/")
			table.insert(pkg.files, ROOT .. "/etc/grub.d/")
			table.insert(pkg.files, ROOT .. "/etc/default/grub")
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
	binary_url = "https://files.obsidianos.xyz/~neo/null/" .. ARCH .. "-grub.tar.gz"
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for GRUB...")
			print("Detected architecture: " .. ARCH)
			print("Downloading GRUB prebuilt from our servers...")
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
			table.insert(pkg.files, ROOT .. "/etc/default/grub")
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
			sh("rm -f " .. ROOT .. "/usr/bin/grub-install")
			sh("rm -f " .. ROOT .. "/usr/bin/grub-mkconfig")
			sh("rm -f " .. ROOT .. "/usr/bin/grub-*")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. GRUB has been removed")
		end)
	end
end
