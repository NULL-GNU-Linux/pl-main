pkg = {
	name = "org.libc.musl",
	version = "1.2.5",
	description = "musl is lightweight, fast, simple, free, and strives to be correct in the sense of standards-conformance and safety.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "MIT",
	homepage = "https://musl.libc.org",
	depends = {},
	conflicts = { "org.gnu.glibc" },
	provides = { "musl", "libc", "ld-linux" },
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
			sh("cd " .. tmpdir .. "/musl-" .. pkg.version .. " && sudo make install")
			table.insert(pkg.files, ROOT .. "/usr/lib/libc.so")
			table.insert(pkg.files, ROOT .. "/usr/include/")
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
		end)
	end
end

function pkg.binary()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("pre_install")(function()
			if ROOT == "" then
				error("Bootstrap mode required for musl libc.")
			end
			print("Preparing binary installation for musl libc...")
			print("Detected architecture: " .. ARCH)
			local arch_map = {
				x86_64 = "x86_64",
				aarch64 = "aarch64",
				armv7l = "armv7l",
				i686 = "i686",
			}

			local musl_arch = arch_map[ARCH]
			if not musl_arch then
				error("Binary package not available for architecture: " .. ARCH)
			end

			print("Downloading musl prebuilt binary...")
			local url = "https://musl.cc/" .. musl_arch .. "-linux-musl-native.tgz"
			curl(url, tmpdir .. "/musl-" .. musl_arch .. ".tar.gz")
			print("Extracting musl binary...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/musl && tar --strip-components=1 -xzf "
					.. tmpdir
					.. "/musl-"
					.. musl_arch
					.. ".tar.gz -C "
					.. tmpdir
					.. "/musl"
			)
		end)

		hook("install")(function()
			print("Installing musl binary to /usr...")
			sh("sudo cp -r " .. tmpdir .. "/musl/bin/* " .. ROOT .. "/usr/bin/")
			sh("sudo cp -r " .. tmpdir .. "/musl/lib/* " .. ROOT .. "/usr/lib/")
			sh("sudo cp -r " .. tmpdir .. "/musl/*-linux-musl/* " .. ROOT .. "/usr/") -- very weird way of all architectures and all those extra stuff
			table.insert(pkg.files, ROOT .. "/usr/bin/musl-gcc")
			table.insert(pkg.files, ROOT .. "/usr/lib/libc.so")
			table.insert(pkg.files, ROOT .. "/usr/include/")
		end)

		hook("post_install")(function()
			print("Binary musl libc installation complete!")
			sh(ROOT .. "/usr/bin/gcc --version | head -n 1")
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
			sh("rm -rf " .. ROOT .. "/usr/bin/musl-gcc")
			sh("rm -rf " .. ROOT .. "/usr/lib/libc.so*")
			sh("rm -rf " .. ROOT .. "/usr/include/*")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. musl libc has been removed")
		end)
	end
end
