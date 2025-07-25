-- TODO:
-- Plugins to checkout: Nvim-Tree(if Coc would be needed for java), Spring Boot Nvim (java framework), Git Signs (Git), Fugitive (Git), coc.nvim (might be useful but it's written in Typescript and Vimscript that are very slow compared to Lua), Vimspector (check if nvim-dap doesn't satisfy)
-- https://github.com/unknownkoder/Java-FullStack-NeoVim-Configuration
-- https://www.chiarulli.me/Neovim/24-neovim-and-java/
-- get to know Lombook
-- setup testing (everything is already installed), importing
-- NOTE:
-- nvim-jdtls is dependent on root_dir aka current directory where neovim is opened, if issue raises, just check cwd

local home = os.getenv("HOME")
local eclipse_jdtls_path = vim.fn.expand("$MASON/packages/jdtls")
local equinox_launcher_path = vim.fn.glob(eclipse_jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar", 1)
local lombok = eclipse_jdtls_path .. "/lombok.jar"
local config_linux = eclipse_jdtls_path .. "/config_linux"
local java_debug_path = vim.fn.expand("$MASON/packages/java-debug-adapter")
local java_test_path = vim.fn.expand("$MASON/packages/java-test")
local root_dir = vim.fs.dirname(
	vim.fs.find({ "gradlew", ".git", "mvnw", "build.gradle", "pom.xml", ".classpath" }, { upward = true })[1]
)

-- Inspired from github.com/IlyasYOY/dotfiles
local function matchInDir(file, pattern, plain)
	if plain == nil then
		plain = false
	end
	if pattern == nil then
		return false
	end

	local index = string.find(file, pattern, 1, plain)

	return index == 1
end

-- Inspired from github.com/IlyasYOY/dotfiles
local function findInDir(dir, pattern, plain)
	local targets = vim.fn.readdir(dir, function(file)
		if matchInDir(file, pattern, plain) then
			return 1
		end
	end)
	local target = targets[1]
	if not target then
		error(string.format("No %s target file was found", pattern))
	end
	return dir .. target
end

-- File types that signify a Java project's root directory. This will be
-- used by eclipse to determine what constitutes a workspace
local workspace_folder = home
	.. "/.local/java/nvim-jdtls-workspace-folder/"
	.. vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

-- eclipse.jdt.ls stores project specific data within a dir. If you are working
-- with multiple different projects, each project must use a dedicated data directory.
-- This variable is used to configure eclipse to use the directory name of the
-- current project found using the root_marker as the dir for project specific data.

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

-- Get the default extended client capablities of the JDTLS language server
local extendedClientCapabilities = require("jdtls").extendedClientCapabilities
-- Modify one property called resolveAdditionalTextEditsSupport and set it to true
extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

-- The on_attach function is used to set key maps after the language server
-- attaches to the current buffer
local on_attach = function(client, bufnr)
	-- With `hotcodereplace = 'auto' the debug adapter will try to apply code changes
	-- you make during a debug session immediately.
	-- Remove the option if you do not want that.
	require("jdtls").setup_dap({ hotcodereplace = "auto" })
	require("jdtls.setup").add_commands()
	require("dap.ext.vscode").load_launchjs()
	require("jdtls.dap").setup_dap_main_class_configs()
	local wk = require("which-key")
	wk.add({
		{ "<leader>j", group = "[j]dtls" }, -- group
	})
	vim.keymap.set("n", "<leader>jd", "<cmd>JdtUpdateDebugConfig<CR>", { desc = "[j]dtls update [d]ebug config" })
	vim.keymap.set("n", "<leader>jc", "<cmd>JdtCompile full<CR>", { desc = "[j]dtls [c]ompile full" })
	vim.keymap.set("n", "<leader>jl", "<cmd>JdtShowLogs<CR>", { desc = "[j]dtls show [l]ogs" })
	vim.keymap.set("n", "<leader>jr", "<cmd>JdtRestart<CR>", { desc = "[j]dtls [r]estart" })
	vim.keymap.set("n", "<leader>js", "<cmd>JdtSetRuntime<CR>", { desc = "[j]dtls [s]et runtime" })
	vim.keymap.set("n", "<leader>ju", "<cmd>JdtUpdateConfig<CR>", { desc = "[j]dtls [u]pdate config" })
	vim.keymap.set(
		"n",
		"<leader>ji",
		"<cmd>lua require'jdtls'.organize_imports()<CR>",
		{ desc = "[j]dtls organize [i]mports" }
	)
	wk.add({
		{ "<leader>jx", group = "[j]dtls e[x]tract" }, -- group
	})
	vim.keymap.set("n", "<leader>jxv", "<Cmd>lua require('jdtls').extract_variable()<CR>", { desc = "[j]dtls e[x]tract [v]ariable" })
	vim.keymap.set("v", "<leader>jxv", "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", { desc = "[j]dtls e[x]tract [v]ariable" })
	vim.keymap.set("n", "<leader>jxc", "<Cmd>lua require('jdtls').extract_constant()<CR>", { desc = "[j]dtls e[x]tract [c]onstant" })
	vim.keymap.set("v", "<leader>jxc", "<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>", { desc = "[j]dtls e[x]tract [c]onstant" })
	vim.keymap.set("v", "<leader>jxm", "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", { desc = "[j]dtls e[x]tract [m]ethod" })
	wk.add({
		{ "<leader>jt", group = "[j]dtls [t]est" }, -- group
	})
  -- nvim-dap integration
	vim.keymap.set("n", "<leader>jtc", "<Cmd>lua require'jdtls'.test_class()<CR>", { desc = "[j]dtls [t]est [c]lass" })
	vim.keymap.set("n", "<leader>jtm", "<Cmd>lua require'jdtls'.test_nearest_method()<CR>", { desc = "[j]dtls [t]est nearest [m]ethod" })
end

local bundles = {
	vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar", 1),
}
vim.list_extend(bundles, vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar", 1), "\n"))

local config = {
	cmd = {
		"java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xmx1g",
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		"-javaagent:" .. lombok,
		"-jar",
		equinox_launcher_path,
		"-configuration",
		config_linux,
		"-data",
		workspace_folder,
	},
	flags = {
		debounce_text_changes = 80,
	},
	capabilities = capabilities,
	on_attach = on_attach, -- We pass our on_attach keybindings to the configuration map
	root_dir = root_dir,
	-- Here you can configure eclipse.jdt.ls specific settings
	-- These are defined by the eclipse.jdt.ls project and will be passed to eclipse when starting.
	-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
	-- for a list of options
	init_options = {
		bundles = bundles,
		extendedClientCapabilities = extendedClientCapabilities,
	},
	settings = {
		java = {
			format = {
				enabled = false,
				-- settings = {
				--   url = home .. "/.local/java/eclipse-java-google-style.xml",
				-- },
			},
			signatureHelp = { enabled = true },
			contentProvider = { preferred = "fernflower" }, -- Use fernflower to decompile library code
			-- Specify any completion options
			completion = {
				favoriteStaticMembers = {
					"org.hamcrest.MatcherAssert.assertThat",
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
					"org.junit.jupiter.api.Assertions.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
					"org.mockito.Mockito.*",
				},
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"jdk.*",
					"sun.*",
				},
			},
			-- Specify any options for organizing imports
			sources = {
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},
			-- How code generation should act
			codeGeneration = {
				toString = {
					template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
				},
				hashCodeEquals = {
					useJava7Objects = true,
				},
				useBlocks = true,
			},
			-- If you are developing in projects with different Java versions, you need
			-- to tell eclipse.jdt.ls to use the location of the JDK for your Java version
			-- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
			-- And search for `interface RuntimeOption`
			-- The `name` is NOT arbitrary, but must match one of the elements from `enum ExecutionEnvironment` in the link above
			configuration = {
				runtimes = {
					{
						name = "JavaSE-1.8",
						path = "/usr/lib/jvm/java-8-openjdk-amd64/",
					},
					{
						name = "JavaSE-17",
						path = "/usr/lib/jvm/java-17-openjdk-amd64/",
					},
					{
						name = "JavaSE-21",
						path = vim.fn.glob(home .. "/.sdkman/candidates/java/21.0.7*", 1),
					},
				},
			},
		},
	},
	-- cmd is the command that starts the language server. Whatever is placed
	-- here is what is passed to the command line to execute jdtls.
	-- Note that eclipse.jdt.ls must be started with a Java version of 17 or higher
	-- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
	-- for the full list of options
}
-- Finally, start jdtls. This will run the language server using the configuration we specified,
-- setup the keymappings, and attach the LSP client to the current buffer
require("jdtls").start_or_attach(config)
