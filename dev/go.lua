pkg = {
	name = "dev.go",
	version = "1.25.4",
	description = "The Go programming language.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "BSD-3-Clause",
	homepage = "https://go.dev",
	depends = {},
	conflicts = {},
	provides = { "go", "golang" },
	files = {},
	options = {},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	local major_version = pkg.version:match("^(%d+%.%d+)")
	local archive_name = "go" .. pkg.version .. ".src.tar.gz"
	local extract_dir = "go"
	return function(hook)
		hook("prepare")(function()
			print("Detected architecture: " .. ARCH)
			print("Downloading Go source...")
			sh("mkdir -p " .. tmpdir)
			local url = "https://go.dev/dl/" .. archive_name
			curl(url, tmpdir .. "/" .. archive_name)
			print("Extracting Go source...")
			sh("cd " .. tmpdir .. " && tar -xzf " .. archive_name)
		end)

		hook("build")(function()
			print("Building Go from source...")
			sh("cd " .. tmpdir .. "/" .. extract_dir .. "/src && ./make.bash")
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
			print("Installing Go...")
			sh("mkdir -p " .. ROOT .. "/usr/lib/go")
			sh("cp -r " .. tmpdir .. "/" .. extract_dir .. "/* " .. ROOT .. "/usr/lib/go/")
			sh("mkdir -p " .. ROOT .. "/usr/bin")
			sh("ln -sf /usr/lib/go/bin/go " .. ROOT .. "/usr/bin/go")
			sh("ln -sf /usr/lib/go/bin/gofmt " .. ROOT .. "/usr/bin/gofmt")
			table.insert(pkg.files, ROOT .. "/usr/lib/go/")
			table.insert(pkg.files, ROOT .. "/usr/bin/go")
			table.insert(pkg.files, ROOT .. "/usr/bin/gofmt")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print(
				"╔════════════════════════════════╗"
			)
			print("║  Go installed!             ║")
			print("║  Version: " .. pkg.version .. "              ║")
			print(
				"╚════════════════════════════════╝"
			)
			print("Run 'go version' to verify installation")
		end)
	end
end

function pkg.binary()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	local arch_map = {
		x86_64 = "amd64",
		aarch64 = "arm64",
		armv7l = "armv6l",
		i686 = "386",
	}
	local go_arch = arch_map[ARCH] or ARCH
	local archive_name = "go" .. pkg.version .. ".linux-" .. go_arch .. ".tar.gz"
	return function(hook)
		hook("pre_install")(function()
			print("Preparing binary installation for Go...")
			print("Detected architecture: " .. ARCH)
			print("Downloading Go prebuilt binary...")
			sh("mkdir -p " .. tmpdir)
			local url = "https://go.dev/dl/" .. archive_name
			curl(url, tmpdir .. "/" .. archive_name)
			print("Extracting Go...")
			sh("cd " .. tmpdir .. " && tar -xzf " .. archive_name)
		end)

		hook("install")(function()
			print("Installing Go...")
			sh("mkdir -p " .. ROOT .. "/usr/lib")
			sh("cp -r " .. tmpdir .. "/go " .. ROOT .. "/usr/lib/")
			sh("mkdir -p " .. ROOT .. "/usr/bin")
			sh("ln -sf /usr/lib/go/bin/go " .. ROOT .. "/usr/bin/go")
			sh("ln -sf /usr/lib/go/bin/gofmt " .. ROOT .. "/usr/bin/gofmt")
			table.insert(pkg.files, ROOT .. "/usr/lib/go/")
			table.insert(pkg.files, ROOT .. "/usr/bin/go")
			table.insert(pkg.files, ROOT .. "/usr/bin/gofmt")
		end)

		hook("post_install")(function()
			print("Binary Go installation complete!")
			print("Run 'go version' to verify installation")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall Go")
		end)

		hook("uninstall")(function()
			print("Removing Go files...")
			sh("rm -rf " .. ROOT .. "/usr/lib/go")
			sh("rm -f " .. ROOT .. "/usr/bin/go")
			sh("rm -f " .. ROOT .. "/usr/bin/gofmt")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. Go has been removed")
		end)
	end
end
