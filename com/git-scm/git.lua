pkg = {
	name = "com.git-scm.git",
	version = "2.51.0",
	description = "Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "GPL-2.0-only",
	homepage = "https://git-scm.com/",
	depends = {},
	conflicts = {},
	provides = { "git" },
	files = {},
	options = {
		extra_configs = { type = "string", default = "" },
	},
}

function pkg.source()
	local version = pkg.version
	local url = "https://www.kernel.org/pub/software/scm/git/git-" .. version .. ".tar.gz"
	local source_dir = "git-" .. version

	return function(hook)
		hook("prepare")(function()
			wget(url, "git.tar.gz")
			sh("tar -zxf git.tar.gz")
		end)

		hook("build")(function()
			sh("cd " .. source_dir .. " && make configure")
			sh(
				"cd "
					.. source_dir
					.. ' && ./configure LDFLAGS="-static" NO_SHARED=1 --prefix=/usr --with-openssl --with-curl --with-expat ' .. OPTIONS..extra_configs
			)
			sh("cd " .. source_dir .. " && make")
		end)

		hook("install")(function()
			sh("cd " .. source_dir .. " && make install DESTDIR=" .. ROOT)
		end)
	end
end
