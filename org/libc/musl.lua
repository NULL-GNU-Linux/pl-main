pkg = {
	name = "org.libc.musl",
	version = "1.2.5",
	description = "musl is lightweight, fast, simple, free, and strives to be correct in the sense of standards-conformance and safety.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "MIT",
	homepage = "https://musl.libc.org",
	depends = {},
	conflicts = {},
	provides = { "musl" },
	files = {},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("prepare")(function()
			if ROOT == "" then
				error("Cannot install to current root. bootstrap mode must be used.")
			end
			print("Downloading musl source...")
			local url = "https://musl.libc.org/releases/musl-" .. pkg.version .. ".tar.gz"
			wget(url, tmpdir .. "/musl-" .. pkg.version .. ".tar.gz")
			sh("mkdir -p " .. tmpdir .. " && tar -xzf " .. tmpdir .. "/musl-" .. pkg.version .. ".tar.gz -C " .. tmpdir)
		end)

		hook("build")(function()
			print("Configuring musl...")
			sh("cd " .. tmpdir .. "/musl-" .. pkg.version .. " && ./configure --prefix=" .. ROOT)
			print("Building musl...")
			sh("cd " .. tmpdir .. "/musl-" .. pkg.version .. " && make -j$(nproc)")
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
			print("Installing musl libc...")
			sh("cd " .. tmpdir .. "/musl-" .. pkg.version .. " && make install")
			table.insert(pkg.files, ROOT .. "/usr/local/lib/libc.so")
			table.insert(pkg.files, ROOT .. "/usr/local/include/")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print(
				"╔════════════════════════════════╗"
			)
			print("║  musl libc installed!          ║")
			print("║  Version: " .. pkg.version .. "              ║")
			print(
				"╚════════════════════════════════╝"
			)
			sh(ROOT .. "/usr/local/bin/musl-gcc --version | head -n 1")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall musl libc")
		end)

		hook("uninstall")(function()
			print("Removing musl libc files...")
			sh("rm -rf " .. ROOT .. "/usr/local/lib/libc.so*")
			sh("rm -rf " .. ROOT .. "/usr/local/include/*")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. musl libc has been removed")
		end)
	end
end
