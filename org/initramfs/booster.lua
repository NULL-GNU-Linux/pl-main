pkg = {
	name = "org.initramfs.booster",
	version = "0.12",
	description = "Fast and secure initramfs generator.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "MIT",
	homepage = "https://github.com/anatol/booster",
	depends = {},
	conflicts = {},
	provides = { "booster", "initramfs" },
	files = {},
	options = {},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("prepare")(function()
			print("Detected architecture: " .. ARCH)
			print("Downloading booster source...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. " && cd "
					.. tmpdir
					.. " && curl -L https://github.com/anatol/booster/archive/refs/tags/"
					.. pkg.version
					.. ".tar.gz | tar -xz"
			)
		end)

		hook("build")(function()
			print("Building booster generator...")
			sh(
				"cd "
					.. tmpdir
					.. "/booster-"
					.. pkg.version
					.. '/generator && go build -trimpath -buildmode=pie -mod=readonly -modcacherw -ldflags "-linkmode external"'
			)
			print("Building booster init...")
			sh(
				"cd "
					.. tmpdir
					.. "/booster-"
					.. pkg.version
					.. "/init && CGO_ENABLED=0 go build -trimpath -mod=readonly -modcacherw"
			)
		end)

		hook("pre_install")(function()
			print("Pre-installation checks for " .. pkg.name)
			if os.getenv("USER") ~= "root" then
				print("Warning: Not running as root, installation may fail")
			end
		end)

		hook("install")(function()
			print("Installing booster...")
			local basedir = tmpdir .. "/booster-" .. pkg.version
			sh("mkdir -p " .. ROOT .. "/etc")
			sh("touch " .. ROOT .. "/etc/booster.yaml")
			sh("mkdir -p " .. ROOT .. "/usr/bin")
			sh("cp " .. basedir .. "/generator/generator " .. ROOT .. "/usr/bin/booster")
			sh("chmod 755 " .. ROOT .. "/usr/bin/booster")
			sh("mkdir -p " .. ROOT .. "/usr/share/man/man1")
			sh("cp " .. basedir .. "/docs/manpage.1 " .. ROOT .. "/usr/share/man/man1/booster.1")
			sh("chmod 644 " .. ROOT .. "/usr/share/man/man1/booster.1")
			sh("mkdir -p " .. ROOT .. "/usr/lib/booster")
			sh("cp " .. basedir .. "/init/init " .. ROOT .. "/usr/lib/booster/init")
			sh("chmod 755 " .. ROOT .. "/usr/lib/booster/init")
			sh("mkdir -p " .. ROOT .. "/usr/share/bash-completion/completions")
			sh(
				"cp "
					.. basedir
					.. "/contrib/completion/bash "
					.. ROOT
					.. "/usr/share/bash-completion/completions/booster"
			)
			sh("chmod 644 " .. ROOT .. "/usr/share/bash-completion/completions/booster")
			table.insert(pkg.files, ROOT .. "/etc/booster.yaml")
			table.insert(pkg.files, ROOT .. "/usr/bin/booster")
			table.insert(pkg.files, ROOT .. "/usr/share/man/man1/booster.1")
			table.insert(pkg.files, ROOT .. "/usr/lib/booster/init")
			table.insert(pkg.files, ROOT .. "/usr/share/bash-completion/completions/booster")
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
			print(
				"╔════════════════════════════════╗"
			)
			print("║  Booster installed!            ║")
			print("║  Version: " .. pkg.version .. "                ║")
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
			print("Preparing binary installation for booster...")
			print("Detected architecture: " .. ARCH)
			print("Downloading booster prebuilt from our servers...")
			local url = "https://files.obsidianos.xyz/~neo/null/" .. ARCH .. "-booster-" .. pkg.version .. ".tar.gz"
			sh("mkdir -p " .. tmpdir)
			curl(url, tmpdir .. "/booster-" .. ARCH .. ".tar.gz")
			print("Extracting booster...")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/booster && tar -xzf "
					.. tmpdir
					.. "/booster-"
					.. ARCH
					.. ".tar.gz -C "
					.. tmpdir
					.. "/booster"
			)
		end)

		hook("install")(function()
			print("Installing booster...")
			sh("cp -r " .. tmpdir .. "/booster/* " .. ROOT .. "/")
			table.insert(pkg.files, ROOT .. "/etc/booster.yaml")
			table.insert(pkg.files, ROOT .. "/usr/bin/booster")
			table.insert(pkg.files, ROOT .. "/usr/share/man/man1/booster.1")
			table.insert(pkg.files, ROOT .. "/usr/lib/booster/")
			table.insert(pkg.files, ROOT .. "/usr/share/bash-completion/completions/booster")
		end)

		hook("post_install")(function()
			print("Binary booster installation complete!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall booster")
		end)

		hook("uninstall")(function()
			print("Removing booster files...")
			sh("rm -f " .. ROOT .. "/etc/booster.yaml")
			sh("rm -f " .. ROOT .. "/usr/bin/booster")
			sh("rm -f " .. ROOT .. "/usr/share/man/man1/booster.1")
			sh("rm -rf " .. ROOT .. "/usr/lib/booster")
			sh("rm -f " .. ROOT .. "/usr/share/bash-completion/completions/booster")
		end)

		hook("post_uninstall")(function()
			print("Cleanup complete. Booster has been removed")
		end)
	end
end
