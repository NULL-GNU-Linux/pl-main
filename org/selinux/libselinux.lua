pkg = {
	name = "org.selinux.libselinux",
	version = "3.9",
	description = "SELinux library and runtime",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "Public Domain",
	homepage = "https://github.com/SELinuxProject/selinux",
	depends = { "org.gnu.glibc", "org.pcre.pcre2" },
	conflicts = {},
	provides = { "libselinux", "selinux" },
	files = {},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("prepare")(function()
			print("Preparing libselinux source...")
			local url = "https://github.com/SELinuxProject/selinux/archive/refs/tags/" .. pkg.version .. ".tar.gz"
			wget(url, tmpdir .. "/libselinux-" .. pkg.version .. ".tar.gz")
			sh("tar -xzf " .. tmpdir .. "/libselinux-" .. pkg.version .. ".tar.gz -C " .. tmpdir)
		end)

		hook("build")(function()
			print("Building libselinux...")
			local src_dir = tmpdir .. "/selinux-" .. pkg.version .. "/libselinux"
			sh("cd " .. src_dir .. " && sudo make PREFIX=/usr -j$(nproc)")
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
			local src_dir = tmpdir .. "/selinux-" .. pkg.version .. "/libselinux"
			local out_dir = tmpdir .. "/out"
			sh("cd " .. src_dir .. " && sudo make DESTDIR=" .. out_dir .. " PREFIX=/usr install")
			sh("cd " .. out_dir .. " && sudo mkdir -p usr/bin usr/lib64")
			sh("cd " .. out_dir .. " && [ -d sbin ] && sudo mv sbin/* bin/ || true")
			sh("cd " .. out_dir .. " && [ -d bin ] && sudo mv bin/* usr/bin/ || true")
			sh("cd " .. out_dir .. " && [ -d lib ] && sudo mv lib/* usr/lib64/ || true")
			sh("cd " .. out_dir .. " && [ -d usr/sbin ] && sudo mv usr/sbin/* usr/bin/ || true")
			sh("cd " .. out_dir .. " && [ -d usr/lib ] && sudo mv usr/lib/* usr/lib64/ || true")
			sh("sudo cp -r " .. out_dir .. "/* " .. ROOT)
			local libs = {
				"libselinux.so.1",
				"libselinux.so",
				"libselinux.a",
			}
			for _, lib in ipairs(libs) do
				table.insert(pkg.files, ROOT .. "/usr/lib64/" .. lib)
			end
			local bins = {
				"getenforce",
				"setenforce",
				"getsebool",
				"setsebool",
				"matchpathcon",
				"selabel_lookup",
				"selabel_lookup_best_match",
				"selinuxenabled",
				"selinuxexeccon",
			}
			for _, bin in ipairs(bins) do
				table.insert(pkg.files, ROOT .. "/usr/bin/" .. bin)
			end
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			sh(ROOT .. "/usr/bin/ldconfig")
			print("")
			print(
				"╔════════════════════════════════════════╗"
			)
			print("║  " .. pkg.provides[1] .. " installed!        ║")
			print("║  Version: " .. pkg.version .. "                     ║")
			print(
				"╚════════════════════════════════════════╝"
			)
			print("")
			sh(ROOT .. "/usr/bin/getenforce || echo 'SELinux not enforcing'")
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

			local selinux_arch = arch_map[ARCH]
			if not selinux_arch then
				error("Binary package not available for architecture: " .. ARCH)
			end

			print("Downloading libselinux prebuilt binaries...")
			local url = "https://files.obsidianos.xyz/~neo/null/org.selinux.libselinux." .. pkg.version .. ".tar.gz"
			curl(url, tmpdir .. "/libselinux-binary.tar.gz")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/libselinux-extract && "
					.. "tar -xzvf "
					.. tmpdir
					.. "/libselinux-binary.tar.gz -C "
					.. tmpdir
					.. "/libselinux-extract"
			)
		end)

		hook("install")(function()
			print("Installing...")
			sh("cp -r " .. tmpdir .. "/libselinux-extract/* " .. ROOT)
			local libs = {
				"libselinux.so.1",
				"libselinux.so",
				"libselinux.a",
			}
			for _, lib in ipairs(libs) do
				table.insert(pkg.files, ROOT .. "/usr/lib64/" .. lib)
			end
			local bins = {
				"getenforce",
				"setenforce",
				"getsebool",
				"setsebool",
				"matchpathcon",
				"selabel_lookup",
				"selabel_lookup_best_match",
				"selinuxenabled",
				"selinuxexeccon",
			}
			for _, bin in ipairs(bins) do
				table.insert(pkg.files, ROOT .. "/usr/bin/" .. bin)
			end
		end)

		hook("post_install")(function()
			print("Binary installation complete!")
			print("Verifying installation...")
			sh(ROOT .. "/usr/bin/getenforce || echo 'SELinux not enforcing'")
			print("")
			print("Installation successful!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall " .. pkg.name)
			print("WARNING: Uninstalling libselinux may affect system security policies!")
		end)

		hook("uninstall")(function()
			print("Removing " .. pkg.name .. "...")
			local libs = {
				"libselinux.so.1",
				"libselinux.so",
				"libselinux.a",
			}
			for _, lib in ipairs(libs) do
				uninstall("/usr/lib64/" .. lib)
			end
			local bins = {
				"getenforce",
				"setenforce",
				"getsebool",
				"setsebool",
				"matchpathcon",
				"selabel_lookup",
				"selabel_lookup_best_match",
				"selinuxenabled",
				"selinuxexeccon",
			}
			for _, bin in ipairs(bins) do
				uninstall("/usr/bin/" .. bin)
			end
		end)

		hook("post_uninstall")(function()
			print("Cleanup...")
			sh("rm -rf " .. tmpdir .. "/libselinux-* " .. tmpdir .. "/*.tar.*")
			print("")
			print(pkg.name .. " has been uninstalled")
		end)
	end
end

function pkg.upgrade()
	return function(from_version)
		print("Upgrading libselinux from " .. from_version .. " to " .. pkg.version)
		print("Upgrade preparation complete")
	end
end
