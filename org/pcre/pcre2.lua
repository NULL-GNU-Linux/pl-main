pkg = {
	name = "org.pcre.pcre2",
	version = "10.47",
	description = "Perl Compatible Regular Expressions 2",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "BSD-3-Clause",
	homepage = "https://www.pcre.org/",
	depends = {},
	conflicts = {},
	provides = { "pcre2", "libpcre2" },
	files = {},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("prepare")(function()
			print("Preparing pcre2 source...")
			local url = "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-"
				.. pkg.version
				.. "/pcre2-"
				.. pkg.version
				.. ".tar.gz"
			wget(url, tmpdir .. "/pcre2-" .. pkg.version .. ".tar.gz")
			sh("tar -xzf " .. tmpdir .. "/pcre2-" .. pkg.version .. ".tar.gz -C " .. tmpdir)
			sh("mkdir -p " .. tmpdir .. "/pcre2-build")
		end)

		hook("build")(function()
			print("Building pcre2...")
			local src_dir = tmpdir .. "/pcre2-" .. pkg.version
			local build_dir = tmpdir .. "/pcre2-build"
			sh(
				"cd "
					.. build_dir
					.. " && "
					.. src_dir
					.. "/configure --prefix=/usr --enable-jit --enable-pcre2-16 --enable-pcre2-32 --enable-pcre2grep-libz --enable-pcre2grep-libbz2 --enable-pcre2test-libreadline"
			)
			sh("cd " .. build_dir .. " && sudo make -j$(nproc)")
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
			print("Installing " .. pkg.name .. " " .. pkg.version)
			local build_dir = tmpdir .. "/pcre2-build"
			local out_dir = tmpdir .. "/out"
			sh("cd " .. build_dir .. " && sudo make DESTDIR=" .. out_dir .. " install")
			sh("cd " .. out_dir .. " && mkdir -p usr/bin usr/lib")
			sh("cd " .. out_dir .. " && [ -d sbin ] && sudo mv sbin/* bin/ || true")
			sh("cd " .. out_dir .. " && [ -d bin ] && sudo mv bin/* usr/bin/ || true")
			sh("cd " .. out_dir .. " && [ -d lib ] && sudo mv lib/* usr/lib/ || true")
			sh("cd " .. out_dir .. " && [ -d usr/sbin ] && sudo mv usr/sbin/* usr/bin/ || true")
			sh("cp -r " .. out_dir .. "/* " .. ROOT)
			local libs = {
				"libpcre2-8.so.0",
				"libpcre2-16.so.0",
				"libpcre2-32.so.0",
				"libpcre2-posix.so.3",
			}
			for _, lib in ipairs(libs) do
				table.insert(pkg.files, ROOT .. "/usr/lib/" .. lib)
			end
			table.insert(pkg.files, ROOT .. "/usr/bin/pcre2grep")
			table.insert(pkg.files, ROOT .. "/usr/bin/pcre2test")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			sh(ROOT .. "/usr/bin/ldconfig")
			print("")
			print(
				"╔════════════════════════════════════════╗"
			)
			print("║  " .. pkg.provides[1] .. " installed!            ║")
			print("║  Version: " .. pkg.version .. "                   ║")
			print(
				"╚════════════════════════════════════════╝"
			)
			print("")
			sh(ROOT .. "/usr/bin/pcre2grep --version | head -n 1")
		end)
	end
end

function pkg.binary()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for " .. pkg.name)
			print("Detected architecture: " .. ARCH)
			local arch_map = {
				x86_64 = "x86_64",
			}

			local pcre2_arch = arch_map[ARCH]
			if not pcre2_arch then
				error("Binary package not available for architecture: " .. ARCH)
			end

			print("Downloading pcre2 prebuilt binaries...")
			local url = "https://files.obsidianos.xyz/~neo/null/org.pcre.pcre2." .. pkg.version .. ".tar.gz"
			curl(url, tmpdir .. "/pcre2-binary.tar.gz")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/pcre2-extract && "
					.. "tar -xzvf "
					.. tmpdir
					.. "/pcre2-binary.tar.gz -C "
					.. tmpdir
					.. "/pcre2-extract"
			)
		end)

		hook("install")(function()
			print("Installing...")
			sh("cp -r " .. tmpdir .. "/pcre2-extract/* " .. ROOT)
			local libs = {
				"libpcre2-8.so.0",
				"libpcre2-16.so.0",
				"libpcre2-32.so.0",
				"libpcre2-posix.so.3",
			}
			for _, lib in ipairs(libs) do
				table.insert(pkg.files, ROOT .. "/usr/lib/" .. lib)
			end
			table.insert(pkg.files, ROOT .. "/usr/bin/pcre2grep")
			table.insert(pkg.files, ROOT .. "/usr/bin/pcre2test")
		end)

		hook("post_install")(function()
			print("Binary installation complete!")
			print("Verifying installation...")
			sh(ROOT .. "/usr/bin/pcre2grep --version | head -n 1")
			print("")
			print("Installation successful!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall " .. pkg.name)
			print("WARNING: Uninstalling pcre2 may break dependent packages!")
		end)

		hook("uninstall")(function()
			print("Removing " .. pkg.name .. "...")
			local libs = {
				"libpcre2-8.so.0",
				"libpcre2-16.so.0",
				"libpcre2-32.so.0",
				"libpcre2-posix.so.3",
			}
			for _, lib in ipairs(libs) do
				uninstall("/usr/lib/" .. lib)
			end
			uninstall("/usr/bin/pcre2grep")
			uninstall("/usr/bin/pcre2test")
		end)

		hook("post_uninstall")(function()
			print("Cleanup...")
			sh("rm -rf " .. tmpdir .. "/pcre2-* " .. tmpdir .. "/*.tar.*")
			print("")
			print(pkg.name .. " has been uninstalled")
		end)
	end
end

function pkg.upgrade()
	return function(from_version)
		print("Upgrading pcre2 from " .. from_version .. " to " .. pkg.version)
		print("Upgrade preparation complete")
	end
end
