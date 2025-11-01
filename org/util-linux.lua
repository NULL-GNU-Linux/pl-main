pkg = {
    name = "org.util-linux",
    version = "2.41.2",
    description = "Essential system utilities for Linux",
    maintainer = "NEOAPPS <neo@obsidianos.xyz>",
    license = "GPL-2.0",
    homepage = "https://github.com/util-linux/util-linux",
    depends = {},
    conflicts = {},
    provides = { "util-linux", "mount", "umount", "fdisk", "mkfs", "blkid", "lsblk" },
    files = {},
}

function pkg.source()
tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
return function(hook)
hook("prepare")(function()
print("Preparing util-linux source...")
local url = "https://github.com/util-linux/util-linux/archive/refs/tags/v" .. pkg.version .. ".tar.gz"
wget(url, tmpdir .. "/util-linux-" .. pkg.version .. ".tar.gz")
sh("tar -xzf " .. tmpdir .. "/util-linux-" .. pkg.version .. ".tar.gz -C " .. tmpdir)
end)

hook("build")(function()
print("Building util-linux...")
local build_dir = tmpdir .. "/util-linux-" .. pkg.version
sh("cd " .. build_dir .. " && ./autogen.sh")
sh("cd " .. build_dir .. " && ./configure")
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
local build_dir = tmpdir .. "/util-linux-" .. pkg.version
local out_dir = tmpdir .. "/out"
sh("cd " .. build_dir .. " && sudo make DESTDIR=" .. out_dir .. " install")
sh("cd " .. out_dir .. " && mkdir -p usr/bin usr/lib")
sh("cd " .. out_dir .. " && [ -d sbin ] && sudo mv sbin/* bin/ || true")
sh("cd " .. out_dir .. " && [ -d lib ] && sudo mv lib/* usr/lib/ || true")
sh("cd " .. out_dir .. " && [ -d bin ] && sudo mv bin/* usr/bin/ || true")
sh("cd " .. out_dir .. " && [ -d usr/sbin ] && sudo mv usr/sbin/* usr/bin/ || true")
sh("cp -r " .. out_dir .. "/* " .. ROOT)
local binaries = { "mount", "umount", "fdisk", "mkfs", "blkid", "lsblk", "findmnt", "losetup", "sfdisk", "cfdisk", "partx", "dmesg", "lscpu", "lsmem" }
for _, bin in ipairs(binaries) do
    table.insert(pkg.files, ROOT .. "/usr/bin/" .. bin)
    end
    end)

hook("post_install")(function()
print("Post-installation setup...")
print("")
print("╔════════════════════════════════════════╗")
print("║  " .. pkg.provides[1] .. " installed!        ║")
print("║  Version: " .. pkg.version .. "                ║")
print("╚════════════════════════════════════════╝")
print("")
sh(ROOT .. "/usr/bin/mount --version | head -n 1")
end)
end
end

function pkg.binary()
tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
return function(hook)
hook("pre_install")(function()
print("Preparing binary installation for " .. pkg.name)
local arch = io.popen("uname -m"):read("*all"):gsub("%s+", "")
print("Detected architecture: " .. arch)
local arch_map = {
    x86_64 = "x86_64",
    i686 = "i686",
}

local util_arch = arch_map[arch]
if not util_arch then
    error("Binary package not available for architecture: " .. arch)
    end

    print("Downloading util-linux prebuilt binaries...")
    local url = "https://files.obsidianos.xyz/~neo/null/org.util-linux." .. pkg.version .. ".tar.gz"
    curl(url, tmpdir .. "/util-linux-binary.tar.gz")
    sh("mkdir -p " .. tmpdir .. "/util-linux-extract && " .. "tar -xzvf " .. tmpdir .. "/util-linux-binary.tar.gz -C " .. tmpdir .. "/util-linux-extract")
    end)

hook("install")(function()
print("Installing...")
local binaries = { "mount", "umount", "fdisk", "mkfs", "blkid", "lsblk", "findmnt", "losetup", "sfdisk", "cfdisk", "partx", "dmesg", "lscpu", "lsmem" }
sh("cp -r " .. tmpdir .. "/util-linux-extract/* " .. ROOT)
for _, bin in ipairs(binaries) do
    table.insert(pkg.files, ROOT .. "/usr/bin/" .. bin)
    end
    end)

hook("post_install")(function()
print("Binary installation complete!")
print("Verifying installation...")
sh(ROOT .. "/usr/bin/mount --version | head -n 1")
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
local binaries = { "mount", "umount", "fdisk", "mkfs", "blkid", "lsblk", "findmnt", "losetup", "sfdisk", "cfdisk", "partx", "dmesg", "lscpu", "lsmem" }
for _, bin in ipairs(binaries) do
    uninstall("/usr/bin/" .. bin)
    end
    end)

hook("post_uninstall")(function()
print("Cleanup...")
sh("rm -rf " .. tmpdir .. "/util-linux-* " .. tmpdir .. "/*.tar.*")
print("")
print(pkg.name .. " has been uninstalled")
end)
end
end

function pkg.upgrade()
return function(from_version)
print("Upgrading util-linux from " .. from_version .. " to " .. pkg.version)
print("Upgrade preparation complete")
end
end
