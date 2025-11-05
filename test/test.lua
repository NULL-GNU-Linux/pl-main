pkg = {
	name = "test.test",
	version = "NULL",
	description = "Test Pkglet OPTIONS",
	maintainer = "NEOAPPS <neo@obsidianos.xyz>",
	license = "No idea",
	homepage = "https://github.com/NULL-GNU-Linux",
	depends = {},
	conflicts = {},
	provides = {},
	files = {},
}

function pkg.binary()
	return function(hook)
		hook("install")(function() end)
		hook("post_install")(function()
			dump(OPTIONS)
		end)
	end
end

function pkg.uninstall()
	return function(hook)
		hook("pre_uninstall")(function() end)

		hook("uninstall")(function() end)
	end
end

function pkg.upgrade()
	return function(from_version) end
end
