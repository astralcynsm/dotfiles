-- words_counter.lua
--[[
版本: v4.0 (多上下文隔离 debug 版)
修复: 移除了 _G 全局变量，使用 env 私有表存储连接，解决多窗口切换导致连接断开的问题。
新增: 详细的 Context 生命周期日志。
--]]

local home = os.getenv("HOME")
local counter_dir = home .. "/.local/share/fcitx5/rime/py_wordscounter"
local csv_path = counter_dir .. "/words_input.csv"
local csv_header = '"timestamp_ms","timestamp_hr","schema_id","preedit_text","commit_text","chinese_count"\n'

-- 简单的日志封装，输出到 Rime 的 INFO 日志
local function log_debug(fmt, ...)
	log.info(string.format("[WordsCounter] " .. fmt, ...))
end

local function ensure_dir_exists(path)
	os.execute(string.format("mkdir -p '%s'", path))
end

local function get_hires_timestamp()
	local handle = io.popen("date +%s.%N")
	if handle then
		local result = handle:read("*a")
		handle:close()
		return result:gsub("[\r\n]", "")
	end
	return os.time()
end

function is_valid_text(text)
	if not text or text == "" then
		return false
	end
	for _, c in utf8.codes(text) do
		if c >= 0x4E00 and c <= 0x9FFF then
			return true
		end
	end
	return false
end

function count_chinese_characters(text)
	local count = 0
	for _, c in utf8.codes(text) do
		if c >= 0x4E00 and c <= 0x9FFF then
			count = count + 1
		end
	end
	return count
end

function append_to_csv(line)
	local file, err = io.open(csv_path, "a")
	if file then
		file:write(line)
		file:close()
	else
		log.error("[WordsCounter] Write failed: " .. tostring(err))
	end
end

-- 闭包工厂：为每个 env 创建独立的 on_commit 回调
local function create_commit_handler(env)
	return function(context)
		local commit_text = context:get_commit_text()

		-- 只有包含有效字符才记录
		if is_valid_text(commit_text) then
			local chinese_count = count_chinese_characters(commit_text)
			local timestamp_ms = get_hires_timestamp()
			local timestamp_hr = os.date("%Y-%m-%d %H:%M:%S")
			local preedit_text = context:get_preedit().text or ""
			local schema_id = env.engine.schema.schema_id

			-- 调试日志：确认是哪个上下文在记录
			log_debug("Ctx[%s] Commiting: %s (+%d)", tostring(env), commit_text, chinese_count)

			local csv_line = string.format(
				'"%s","%s","%s","%s","%s","%d"\n',
				timestamp_ms,
				timestamp_hr,
				schema_id,
				preedit_text:gsub('"', '""'),
				commit_text:gsub('"', '""'),
				chinese_count
			)
			append_to_csv(csv_line)
		end
	end
end

-- Processor 入口 (必须有，否则报错)
function processor(key, env)
	return 2 -- kNoop
end

-- 初始化
function inite(env)
	-- 打印当前 env 的 ID，用于区分不同窗口
	log_debug("Initializing Context: %s (Schema: %s)", tostring(env), env.engine.schema.schema_id)

	ensure_dir_exists(counter_dir)

	-- 初始化文件头 (只需做一次，并发无所谓)
	local file = io.open(csv_path, "r")
	if not file then
		file = io.open(csv_path, "w")
		if file then
			file:write(csv_header)
			file:close()
		end
	else
		file:close()
	end

	-- ！！！关键修改！！！
	-- 将 connection 绑定在 env 自身，而不是全局变量 _G
	-- 这样 Firefox 有 Firefox 的 connection，QQ 有 QQ 的 connection，互不干扰
	env.words_counter_conn = env.engine.context.commit_notifier:connect(create_commit_handler(env))
end

-- 销毁 (当窗口关闭或切换方案时触发)
function fini(env)
	log_debug("Destroying Context: %s", tostring(env))
	if env.words_counter_conn then
		env.words_counter_conn:disconnect()
		env.words_counter_conn = nil
	end
end

return { init = inite, func = processor, fini = fini }
