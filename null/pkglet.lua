pkg = {
	name = "null.pkglet",
	version = "git",
	description = "The hybrid package manager for NULL GNU/Linux",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "MIT",
	homepage = "https://github.com/NULL-GNU-Linux/pkglet",
	depends = { "b/org.lua.lua" },
	conflicts = {},
	provides = { "pkglet" },
	files = {},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("prepare")(function()
			gitclone(pkg.homepage, "pkglet")
		end)
		hook("install")(function()
			print("Installing " .. pkg.name .. " " .. pkg.version)
			install("../../../../../../" .. tmpdir .. "/pkglet/pl", "/usr/bin/pl", "755")
			table.insert(pkg.files, ROOT .. "/usr/bin/pl")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print("")
			print(
				"╔════════════════════════════════════════╗"
			)
			print("║  " .. pkg.provides[1] .. " installed!                ║")
			print("║  Version: " .. pkg.version .. "                      ║")
			print(
				"╚════════════════════════════════════════╝"
			)
			print("")
		end)
	end
end

function pkg.binary()
	return function(hook)
		hook("prepare")(function()
			curl("https://raw.githubusercontent.com/NULL-GNU-Linux/pkglet/refs/heads/main/pl", "pl")
		end)
		hook("install")(function()
			print("Installing binary files...")
			install("../../../../../../pl", "/usr/bin/pl", "755")
			table.insert(pkg.files, ROOT .. "/usr/bin/pl")
		end)

		hook("post_install")(function()
			print("Binary installation complete!")
			print("Verifying installation...")
			sh(ROOT .. "/usr/bin/pl -v")
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
			uninstall("/usr/bin/pl")
		end)

		hook("post_uninstall")(function()
			print("Cleanup...")
			print("")
			print(pkg.name .. " has been uninstalled")
		end)
	end
end
