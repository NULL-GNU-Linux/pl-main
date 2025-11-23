pkg = {
	name = "org.gnu.coreutils",
	version = "9.9",
	description = "GNU Core Utilities - essential file, shell and text utilities",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "GPL-3.0",
	homepage = "https://www.gnu.org/software/coreutils/",
	depends = { "org.gnu.glibc" },
	conflicts = {},
	provides = { "coreutils", "ls", "cat", "cp", "mv", "rm", "mkdir" },
	files = {},
}

function pkg.source()
	tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
	return function(hook)
		hook("prepare")(function()
			print("Preparing coreutils source...")
			local url = "https://ftp.gnu.org/gnu/coreutils/coreutils-" .. pkg.version .. ".tar.gz"
			wget(url, tmpdir .. "/coreutils-" .. pkg.version .. ".tar.gz")
			sh("tar -xzf " .. tmpdir .. "/coreutils-" .. pkg.version .. ".tar.gz -C " .. tmpdir)
			sh("mkdir -p " .. tmpdir .. "/coreutils-build")
		end)

		hook("build")(function()
			print("Building coreutils...")
			local src_dir = tmpdir .. "/coreutils-" .. pkg.version
			local build_dir = tmpdir .. "/coreutils-build"
			sh("cd " .. build_dir .. " && " .. src_dir .. "/configure --prefix=/usr")
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
			local build_dir = tmpdir .. "/coreutils-build"
			local out_dir = tmpdir .. "/out"
			sh("cd " .. build_dir .. " && sudo make DESTDIR=" .. out_dir .. " install")
			sh("cd " .. out_dir .. " && mkdir -p usr/bin")
			sh("cd " .. out_dir .. " && [ -d bin ] && sudo mv bin/* usr/bin/ || true")
			sh("cp -r " .. out_dir .. "/* " .. ROOT)
			local binaries = {
				"ls",
				"cat",
				"cp",
				"mv",
				"rm",
				"mkdir",
				"rmdir",
				"ln",
				"touch",
				"chmod",
				"chown",
				"chgrp",
				"dd",
				"df",
				"du",
				"echo",
				"false",
				"true",
				"pwd",
				"sync",
				"uname",
				"hostname",
				"sleep",
				"basename",
				"dirname",
				"head",
				"tail",
				"cut",
				"sort",
				"uniq",
				"wc",
				"tr",
				"tee",
				"yes",
				"seq",
				"printenv",
				"env",
				"id",
				"whoami",
				"groups",
				"users",
				"who",
				"date",
				"test",
				"[",
				"expr",
				"factor",
				"md5sum",
				"sha1sum",
				"sha256sum",
				"sha512sum",
				"b2sum",
				"base64",
				"base32",
				"stat",
				"readlink",
				"realpath",
				"nohup",
				"nice",
				"stty",
				"tty",
				"mktemp",
				"install",
				"shred",
				"timeout",
				"truncate",
				"split",
				"csplit",
				"paste",
				"join",
				"fmt",
				"pr",
				"fold",
				"expand",
				"unexpand",
				"nl",
				"od",
				"ptx",
				"tsort",
				"shuf",
				"numfmt",
				"comm",
				"pathchk",
				"pinky",
				"logname",
				"chcon",
				"runcon",
				"mkfifo",
				"mknod",
				"link",
				"unlink",
				"dir",
				"vdir",
				"dircolors",
			}
			for _, bin in ipairs(binaries) do
				table.insert(pkg.files, ROOT .. "/usr/bin/" .. bin)
			end
		end)

		hook("post_install")(function()
			print("Post-installation setup...")
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
			sh(ROOT .. "/usr/bin/ls --version | head -n 1")
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

			local coreutils_arch = arch_map[ARCH]
			if not coreutils_arch then
				error("Binary package not available for architecture: " .. ARCH)
			end

			print("Downloading coreutils prebuilt binaries...")
			local url = "https://files.obsidianos.xyz/~neo/null/org.gnu.coreutils." .. pkg.version .. ".tar.gz"
			curl(url, tmpdir .. "/coreutils-binary.tar.gz")
			sh(
				"mkdir -p "
					.. tmpdir
					.. "/coreutils-extract && "
					.. "tar -xzvf "
					.. tmpdir
					.. "/coreutils-binary.tar.gz -C "
					.. tmpdir
					.. "/coreutils-extract"
			)
		end)

		hook("install")(function()
			print("Installing...")
			sh("cp -r " .. tmpdir .. "/coreutils-extract/* " .. ROOT)
			local binaries = {
				"ls",
				"cat",
				"cp",
				"mv",
				"rm",
				"mkdir",
				"rmdir",
				"ln",
				"touch",
				"chmod",
				"chown",
				"chgrp",
				"dd",
				"df",
				"du",
				"echo",
				"false",
				"true",
				"pwd",
				"sync",
				"uname",
				"hostname",
				"sleep",
				"basename",
				"dirname",
				"head",
				"tail",
				"cut",
				"sort",
				"uniq",
				"wc",
				"tr",
				"tee",
				"yes",
				"seq",
				"printenv",
				"env",
				"id",
				"whoami",
				"groups",
				"users",
				"who",
				"date",
				"test",
				"[",
				"expr",
				"factor",
				"md5sum",
				"sha1sum",
				"sha256sum",
				"sha512sum",
				"b2sum",
				"base64",
				"base32",
				"stat",
				"readlink",
				"realpath",
				"nohup",
				"nice",
				"stty",
				"tty",
				"mktemp",
				"install",
				"shred",
				"timeout",
				"truncate",
				"split",
				"csplit",
				"paste",
				"join",
				"fmt",
				"pr",
				"fold",
				"expand",
				"unexpand",
				"nl",
				"od",
				"ptx",
				"tsort",
				"shuf",
				"numfmt",
				"comm",
				"pathchk",
				"pinky",
				"logname",
				"chcon",
				"runcon",
				"mkfifo",
				"mknod",
				"link",
				"unlink",
				"dir",
				"vdir",
				"dircolors",
			}
			for _, bin in ipairs(binaries) do
				table.insert(pkg.files, ROOT .. "/usr/bin/" .. bin)
			end
		end)

		hook("post_install")(function()
			print("Binary installation complete!")
			print("Verifying installation...")
			sh(ROOT .. "/usr/bin/ls --version | head -n 1")
			print("")
			print("Installation successful!")
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function()
			print("Preparing to uninstall " .. pkg.name)
			print("WARNING: Uninstalling coreutils will remove essential system utilities!")
		end)

		hook("uninstall")(function()
			print("Removing " .. pkg.name .. "...")
			local binaries = {
				"ls",
				"cat",
				"cp",
				"mv",
				"rm",
				"mkdir",
				"rmdir",
				"ln",
				"touch",
				"chmod",
				"chown",
				"chgrp",
				"dd",
				"df",
				"du",
				"echo",
				"false",
				"true",
				"pwd",
				"sync",
				"uname",
				"hostname",
				"sleep",
				"basename",
				"dirname",
				"head",
				"tail",
				"cut",
				"sort",
				"uniq",
				"wc",
				"tr",
				"tee",
				"yes",
				"seq",
				"printenv",
				"env",
				"id",
				"whoami",
				"groups",
				"users",
				"who",
				"date",
				"test",
				"[",
				"expr",
				"factor",
				"md5sum",
				"sha1sum",
				"sha256sum",
				"sha512sum",
				"b2sum",
				"base64",
				"base32",
				"stat",
				"readlink",
				"realpath",
				"nohup",
				"nice",
				"stty",
				"tty",
				"mktemp",
				"install",
				"shred",
				"timeout",
				"truncate",
				"split",
				"csplit",
				"paste",
				"join",
				"fmt",
				"pr",
				"fold",
				"expand",
				"unexpand",
				"nl",
				"od",
				"ptx",
				"tsort",
				"shuf",
				"numfmt",
				"comm",
				"pathchk",
				"pinky",
				"logname",
				"chcon",
				"runcon",
				"mkfifo",
				"mknod",
				"link",
				"unlink",
				"dir",
				"vdir",
				"dircolors",
			}
			for _, bin in ipairs(binaries) do
				uninstall("/usr/bin/" .. bin)
			end
		end)

		hook("post_uninstall")(function()
			print("Cleanup...")
			sh("rm -rf " .. tmpdir .. "/coreutils-* " .. tmpdir .. "/*.tar.*")
			print("")
			print(pkg.name .. " has been uninstalled")
		end)
	end
end

function pkg.upgrade()
	return function(from_version)
		print("Upgrading coreutils from " .. from_version .. " to " .. pkg.version)
		print("Upgrade preparation complete")
	end
end
