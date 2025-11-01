pkg = {
    name = "org.gnu.glibc",
    version = "2.42",
    description = "GNU C Library - core system C library",
    maintainer = "NEOAPPS <neo@obsidianos.xyz>",
    license = "LGPL-2.1",
    homepage = "https://www.gnu.org/software/libc/",
    depends = {},
    conflicts = { "org.libc.musl" },
    provides = { "glibc", "libc", "ld-linux" },
    files = {},
}

function pkg.source()
tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
return function(hook)
hook("prepare")(function()
print("Preparing glibc source...")
local url = "https://github.com/bminor/glibc/archive/refs/tags/glibc-" .. pkg.version .. ".tar.gz"
wget(url, tmpdir .. "/glibc-" .. pkg.version .. ".tar.gz")
sh("tar -xzf " .. tmpdir .. "/glibc-" .. pkg.version .. ".tar.gz -C " .. tmpdir)
sh("mkdir -p " .. tmpdir .. "/glibc-build")
end)

hook("build")(function()
print("Building glibc...")
local src_dir = tmpdir .. "/glibc-" .. pkg.version
local build_dir = tmpdir .. "/glibc-build"
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
local build_dir = tmpdir .. "/glibc-build"
local out_dir = tmpdir .. "/out"
sh("cd " .. build_dir .. " && sudo make DESTDIR=" .. out_dir .. " install")
sh("cd " .. out_dir .. " && mkdir -p usr/bin usr/lib64")
sh("cd " .. out_dir .. " && [ -d sbin ] && sudo mv sbin/* bin/ || true")
sh("cd " .. out_dir .. " && [ -d bin ] && sudo mv bin/* usr/bin/ || true")
sh("cd " .. out_dir .. " && [ -d lib64 ] && sudo mv lib64/* usr/lib64/ || true")
sh("cd " .. out_dir .. " && [ -d usr/sbin ] && sudo mv usr/sbin/* usr/bin/ || true")
sh("cp -r " .. out_dir .. "/* " .. ROOT)
local libs = { "libc.so.6", "libm.so.6", "libpthread.so.0", "libdl.so.2", "librt.so.1", "libresolv.so.2", "libnss_files.so.2", "libnss_dns.so.2" }
for _, lib in ipairs(libs) do
    table.insert(pkg.files, ROOT .. "/usr/lib64/" .. lib)
    end
    table.insert(pkg.files, ROOT .. "/usr/bin/ldd")
    table.insert(pkg.files, ROOT .. "/usr/bin/ldconfig")
    end)

hook("post_install")(function()
print("Post-installation setup...")
sh(ROOT .. "/usr/bin/ldconfig")
print("")
print("╔════════════════════════════════════════╗")
print("║  " .. pkg.provides[1] .. " installed!             ║")
print("║  Version: " .. pkg.version .. "                    ║")
print("╚════════════════════════════════════════╝")
print("")
sh(ROOT .. "/usr/bin/ldd --version | head -n 1")
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
}

local glibc_arch = arch_map[arch]
if not glibc_arch then
    error("Binary package not available for architecture: " .. arch)
    end

    print("Downloading glibc prebuilt binaries...")
    local url = "https://files.obsidianos.xyz/~neo/null/org.gnu.glibc." .. pkg.version .. ".tar.gz"
    curl(url, tmpdir .. "/glibc-binary.tar.gz")
    sh("mkdir -p " .. tmpdir .. "/glibc-extract && " .. "tar -xzvf " .. tmpdir .. "/glibc-binary.tar.gz -C " .. tmpdir .. "/glibc-extract")
    end)

hook("install")(function()
print("Installing...")
sh("cp -r " .. tmpdir .. "/glibc-extract/* " .. ROOT)
local libs = { "libc.so.6", "libm.so.6", "libpthread.so.0", "libdl.so.2", "librt.so.1", "libresolv.so.2", "libnss_files.so.2", "libnss_dns.so.2" }
for _, lib in ipairs(libs) do
    table.insert(pkg.files, ROOT .. "/usr/lib64/" .. lib)
    end
    table.insert(pkg.files, ROOT .. "/usr/bin/ldd")
    table.insert(pkg.files, ROOT .. "/usr/bin/ldconfig")
    end)

hook("post_install")(function()
print("Binary installation complete!")
print("Verifying installation...")
sh(ROOT .. "/usr/bin/ldd --version | head -n 1")
print("")
print("Installation successful!")
end)
end
end

function pkg.uninstall()
return function(hook)
hook("pre_uninstall")(function()
print("Preparing to uninstall " .. pkg.name)
print("WARNING: Uninstalling glibc may break your system!")
end)

hook("uninstall")(function()
print("Removing " .. pkg.name .. "...")
local libs = { "libc.so.6", "libm.so.6", "libpthread.so.0", "libdl.so.2", "librt.so.1", "libresolv.so.2", "libnss_files.so.2", "libnss_dns.so.2" }
for _, lib in ipairs(libs) do
    uninstall("/usr/lib64/" .. lib)
    end
    uninstall("/usr/bin/ldd")
    uninstall("/usr/bin/ldconfig")
    end)

hook("post_uninstall")(function()
print("Cleanup...")
sh("rm -rf " .. tmpdir .. "/glibc-* " .. tmpdir .. "/*.tar.*")
print("")
print(pkg.name .. " has been uninstalled")
end)
end
end

function pkg.upgrade()
return function(from_version)
print("Upgrading glibc from " .. from_version .. " to " .. pkg.version)
print("Upgrade preparation complete")
end
end
