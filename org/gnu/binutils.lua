pkg = {
    name = "org.gnu.binutils",
    version = "2.45",
    description = "GNU Binary Utilities - Essential tools for manipulating binaries",
    maintainer = "NEOAPPS <neo@obsidianos.xyz>",
    license = "GPL-3.0",
    homepage = "https://www.gnu.org/software/binutils/",
    depends = {},
    conflicts = {},
    provides = { "binutils", "ld", "as", "ar", "nm", "objdump", "strip", "readelf" },
    files = {},
}

function pkg.source()
tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
return function(hook)
hook("prepare")(function()
print("Preparing GNU binutils source...")
local version_tag = "binutils-" .. pkg.version:gsub("%.", "_")
local url = "https://github.com/bminor/binutils-gdb/archive/refs/tags/" .. version_tag .. ".tar.gz"
wget(url, tmpdir .. "/binutils-" .. pkg.version .. ".tar.gz")
sh("tar -xzf " .. tmpdir .. "/binutils-" .. pkg.version .. ".tar.gz -C " .. tmpdir)
end)

hook("build")(function()
print("Configuring GNU binutils...")
local build_dir = tmpdir .. "/binutils-gdb-binutils-" .. pkg.version:gsub("%.", "_")
sh("cd " .. build_dir .. " && ./configure --prefix=/usr --enable-gold --enable-ld=default --enable-plugins --disable-werror --with-system-zlib")

print("Building GNU binutils...")
sh("cd " .. build_dir .. " && make -j$(nproc)")
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
local build_dir = tmpdir .. "/binutils-gdb-binutils-" .. pkg.version:gsub("%.", "_")
sh("cd " .. build_dir .. " && make DESTDIR=" .. ROOT .. " install")

local binaries = { "ld", "as", "ar", "nm", "objdump", "strip", "readelf", "objcopy", "ranlib", "size", "strings", "addr2line", "c++filt", "elfedit", "gprof" }
for _, bin in ipairs(binaries) do
    table.insert(pkg.files, ROOT .. "/usr/bin/" .. bin)
    end
    end)

hook("post_install")(function()
print("Post-installation setup...")
print("")
print("╔════════════════════════════════════════╗")
print("║  " .. pkg.provides[1] .. " installed!           ║")
print("║  Version: " .. pkg.version .. "                  ║")
print("╚════════════════════════════════════════╝")
print("")
sh(ROOT .. "/usr/bin/ld --version | head -n 1")
end)
end
end

function pkg.binary()
tmpdir = os.getenv("HOME") .. "/.cache/pkglet/build/" .. pkg.name
return function(hook)
hook("pre_install")(function()
print("[!] Binary builds unavailable. Building from source...")
print("Preparing binary installation for " .. pkg.name)
local arch = io.popen("uname -m"):read("*all"):gsub("%s+", "")
print("Detected architecture: " .. arch)

local arch_map = {
    x86_64 = "x86_64",
    aarch64 = "aarch64",
    armv7l = "armv7l",
    i686 = "i686",
}

local binutils_arch = arch_map[arch]
if not binutils_arch then
    error("Binary package not available for architecture: " .. arch)
    end

    print("Downloading GNU binutils prebuilt binaries...")
    local url = "https://ftp.gnu.org/gnu/binutils/binutils-" .. pkg.version .. ".tar.xz"
    curl(url, tmpdir .. "/binutils-binary.tar.xz")
    sh("tar -xJf " .. tmpdir .. "/binutils-binary.tar.xz -C " .. tmpdir)

    local extract_dir = tmpdir .. "/binutils-" .. pkg.version
    sh("cd " .. extract_dir .. " && ./configure --prefix=" .. tmpdir .. "/binutils-install --disable-werror")
    sh("cd " .. extract_dir .. " && make -j$(nproc) && make install")
    end)

hook("install")(function()
print("Installing...")
local binaries = { "ld", "as", "ar", "nm", "objdump", "strip", "readelf", "objcopy", "ranlib", "size", "strings", "addr2line", "c++filt", "elfedit", "gprof" }

for _, bin in ipairs(binaries) do
    install(tmpdir .. "/binutils-install/bin/" .. bin, "/usr/bin/" .. bin, "755")
    table.insert(pkg.files, ROOT .. "/usr/bin/" .. bin)
    end
    end)

hook("post_install")(function()
print("Binary installation complete!")
print("Verifying installation...")
sh(ROOT .. "/usr/bin/ld --version | head -n 1")
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
local binaries = { "ld", "as", "ar", "nm", "objdump", "strip", "readelf", "objcopy", "ranlib", "size", "strings", "addr2line", "c++filt", "elfedit", "gprof" }

for _, bin in ipairs(binaries) do
    uninstall("/usr/bin/" .. bin)
    end
    end)

hook("post_uninstall")(function()
print("Cleanup...")
sh("rm -rf " .. tmpdir .. "/binutils-* " .. tmpdir .. "/*.tar.*")
print("")
print(pkg.name .. " has been uninstalled")
end)
end
end

function pkg.upgrade()
return function(from_version)
print("Upgrading GNU binutils from " .. from_version .. " to " .. pkg.version)
print("Upgrade preparation complete")
end
end
