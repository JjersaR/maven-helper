local M = {}

-- Crear un namespace para los diagnósticos
local namespace_id = vim.api.nvim_create_namespace("maven-helper")

-- Definir signos para éxito, error y en ejecución
vim.fn.sign_define("MavenTestSuccess", { text = "", texthl = "SuccessMsg", numhl = "" })
vim.fn.sign_define("MavenTestError", { text = "", texthl = "ErrorMsg", numhl = "" })
vim.fn.sign_define("MavenTestRunning", { text = "", texthl = "WarningMsg", numhl = "" })

-- Función para mostrar notificaciones
local function notify_result(msg, level)
	vim.notify(msg, level, { title = "Maven Helper" })
end

-- Función para ejecutar comandos Maven de forma asíncrona usando vim.system
local function run_maven_command(cmd, callback)
	vim.system(cmd, { text = true }, function(obj)
		if obj.code == 0 then
			callback(true, obj.stdout)
		else
			callback(false, obj.stderr)
		end
	end)
end

-- Función para recargar dependencias usando mvn dependency:resolve
function M.reload_dependencies()
	run_maven_command({ "mvn", "dependency:resolve" }, function(success, output)
		if success then
			notify_result("Dependencies reloaded successfully.", vim.log.levels.INFO)
		else
			notify_result("Failed to reload dependencies:\n" .. output, vim.log.levels.ERROR)
		end
	end)
end

-- Función para validar el pom.xml con mvn validate
function M.validate_pom()
	run_maven_command({ "mvn", "validate" }, function(success, output)
		if success then
			notify_result("pom.xml validated successfully.", vim.log.levels.INFO)
		else
			notify_result("Validation failed:\n" .. output, vim.log.levels.ERROR)
		end
	end)
end

-- Función para verificar el proyecto con mvn verify
function M.verify_pom()
	run_maven_command({ "mvn", "verify" }, function(success, output)
		if success then
			notify_result("pom.xml verification successful.", vim.log.levels.INFO)
		else
			notify_result("Verification failed:\n" .. output, vim.log.levels.ERROR)
		end
	end)
end

-- Función para ejecutar Maven con un perfil proporcionado por el usuario
function M.run_with_profile()
	vim.ui.input({ prompt = "Enter Maven profile: " }, function(profile)
		if not profile or profile == "" then
			notify_result("Profile input cancelled.", vim.log.levels.WARN)
			return
		end

		run_maven_command({ "mvn", "clean", "install", "-P" .. profile }, function(success, output)
			if success then
				notify_result("Maven build with profile '" .. profile .. "' succeeded.", vim.log.levels.INFO)
			else
				notify_result("Build with profile '" .. profile .. "' failed:\n" .. output, vim.log.levels.ERROR)
			end
		end)
	end)
end

-- Autocomando para ejecutar recarga de dependencias, validación y verificación al guardar el archivo pom.xml
function M.set_autocmds()
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "pom.xml",
		callback = function()
			-- Ejecuta las tres funciones de manera asíncrona en secuencia
			M.reload_dependencies()
			M.validate_pom()
			M.verify_pom()
		end,
		desc = "Recarga dependencias, valida y verifica el archivo pom.xml tras guardarlo.",
	})
end

-- Función para asociar key mappings
function M.set_keymaps()
	-- Recargar dependencias con `<Leader>md`
	vim.api.nvim_set_keymap(
		"n",
		"<Leader>md",
		':lua require("maven-helper").reload_dependencies()<CR>',
		{ noremap = true, silent = true, desc = "Reload Maven Dependencies" }
	)
	-- Validar el archivo pom.xml con `<Leader>mv`
	vim.api.nvim_set_keymap(
		"n",
		"<Leader>mv",
		':lua require("maven-helper").validate_pom()<CR>',
		{ noremap = true, silent = true, desc = "Validate pom.xml" }
	)
	-- Verificar el proyecto con `<Leader>mvf`
	vim.api.nvim_set_keymap(
		"n",
		"<Leader>mvf",
		':lua require("maven-helper").verify_pom()<CR>',
		{ noremap = true, silent = true, desc = "Verify pom.xml" }
	)
	-- Ejecutar Maven con perfil con `<Leader>mp`
	vim.api.nvim_set_keymap(
		"n",
		"<Leader>mp",
		':lua require("maven-helper").run_with_profile()<CR>',
		{ noremap = true, silent = true, desc = "Run Maven with Profile" }
	)
end

-- Setup inicial del plugin
function M.setup()
	M.set_keymaps()
	M.set_autocmds()
end

return M
