pkg = {
	name = "io.neovim.neovim",
	version = "0.11.4",
	description = "hyperextensible Vim-based text editor",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "Apache-2.0",
	homepage = "https://github.com/neovim/neovim",
	depends = {},
	conflicts = {},
	provides = { "nvim" },
	files = {},
}
function pkg.source()
	return function(hook)
		hook("prepare")(function()
			print("Preparing source code...")
			curl(pkg.homepage .. "/archive/refs/tags/v" .. pkg.version .. ".tar.gz", "/tmp/neovim.tar.gz")
			sh("mkdir -p " .. os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name .. "/nvimsrc")
			sh(
				"tar -xvzf "
					.. ROOT
					.. "/tmp/neovim.tar.gz -C "
					.. os.getenv("HOME")
					.. "/.cache/pkglet/build/"
					.. pkg.name
					.. "/nvimsrc"
			)
		end)

		hook("build")(function()
			print("Building...")
			sh("make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=" .. ROOT .. "/usr/")
		end)
		hook("install")(function()
			print("Installing " .. pkg.name .. " " .. pkg.version)
			sh("sudo make install")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print("")
			print(
				"╔════════════════════════════════════════╗"
			)
			print("║  " .. pkg.provides[1] .. " installed!          ║")
			print("║  Version: " .. pkg.version .. "                        ║")
			print(
				"╚════════════════════════════════════════╝"
			)
			print("")
		end)
	end
end

function pkg.binary()
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for " .. pkg.name)
			local arch = io.popen("uname -m"):read("*all"):gsub("%s+", "")
			print("Detected architecture: " .. arch)
			print("Downloading binary package...")
			local url = "https://github.com/neovim/neovim/releases/download/v"
				.. pkg.version
				.. "/nvim-linux-"
				.. arch
				.. ".tar.gz"
			curl(url, "/tmp/nvim-binary.tar.gz")
		end)

		hook("install")(function()
			print("Installing binary files...")

			sh("tar -xzf /tmp/nvim-binary.tar.gz -C " .. ROOT .. "/usr/")
			table.insert(pkg.files, ROOT .. "/usr/")
		end)

		hook("post_install")(function()
			print("Binary installation complete!")
			print("Verifying installation...")
			sh(ROOT .. "/usr/bin/nvim --version")

			print("")
			print("Installation successful!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall " .. pkg.name)
		end)

		hook("uninstall")(function()
			print("Removing " .. pkg.name .. "...")
			print("Removing binaries...")
			uninstall("/usr/bin/nvim")
			uninstall("/usr/share/applications/nvim.desktop")
			uninstall("/usr/share/icons/hicolor/128x128/apps/nvim.png")
			print("Removing libraries...")
			uninstall("/usr/lib/nvim")
			print("Removing man pages...")
			uninstall("/usr/share/man/man1/nvim.1")
			print("Removing configuration...")
			uninstall("/usr/share/nvim")
		end)
	end
end

function pkg.upgrade()
	return function(from_version)
		print("Upgrading from " .. from_version .. " to " .. pkg.version)
		print("Upgrade hooks complete")
	end
end
