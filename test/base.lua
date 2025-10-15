pkg = {
	name = "test.base",
	version = "rolling",
	description = "Test Base",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "No idea",
	homepage = "https://github.com/NULL-GNU-Linux",
	depends = {},
	conflicts = {},
	provides = { "base" },
	files = {},
}
function pkg.source()
	return function(hook)
		hook("prepare")(function()
			print("Preparing source code...")
			sh(
				"git clone "
					.. pkg.homepage
					.. " --depth=1 -b v"
					.. pkg.version
					.. " "
					.. os.getenv("HOME")
					.. "/.cache/pkglet/build/"
					.. pkg.name
					.. "/nvimsrc"
			)
		end)

		hook("build")(function()
			print("Building...")
			sh("cd nvimsrc && make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=" .. ROOT .. "/usr/")
		end)
		hook("install")(function()
			print("Installing " .. pkg.name .. " " .. pkg.version)
			sh("cd nvimsrc && sudo make CMAKE_INSTALL_PREFIX=" .. ROOT .. "/usr/ install")
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
		hook("install")(function()
			sh("cp ~/base-test.tar.gz " .. ROOT) -- dont even try to run the script bud :)
			os.execute("tar -xvzf " .. ROOT .. "/base-test.tar.gz -C " .. ROOT)
		end)

		hook("post_install")(function()
			print("Binary installation complete!")
			print("Verifying installation...")
			os.execute("rm -f " .. ROOT .. "/base-test.tar.gz")
			sh(ROOT .. "/usr/bin/bash --version")

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

		hook("uninstall")(function() end)
	end
end

function pkg.upgrade()
	return function(from_version)
		print("Upgrading from " .. from_version .. " to " .. pkg.version)
		print("Upgrade hooks complete")
	end
end
