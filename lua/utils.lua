local M = {}

-- AI 代理和命令的基础路径
M.ai_path = vim.fn.expand("~/.vim/AI")

-- 通用文件读取函数
function M.read_file(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        file:close()
        return content
    end
    return nil
end

-- 读取 Prompt 文件并剥离 YAML Header
function M.read_prompt(path)
    local content = M.read_file(path)
    if not content then
        return nil
    end

    if content:sub(1, 3) == "---" then
        local _, second_sep_end = content:find("\n%-%-%-%s*\n")
        if second_sep_end then
            content = content:sub(second_sep_end + 1)
        end
    end

    return {
        name = vim.fn.fnamemodify(path, ":t"),
        content = content,
    }
end

-- 构造 AI Prompt 的核心逻辑
function M.AI_prompt(principles, behavior, system_prompt)
    local rules = {}

    if system_prompt == nil then
        system_prompt = true
    end

    if system_prompt then
        local general_prompt = M.read_prompt(M.ai_path .. "/agents/general.md")
        if general_prompt then
            table.insert(rules, general_prompt)
        else
            table.insert(rules, {
                name = "general.md",
                content = "始终使用中文回复。保持绝对客观与真实，拒绝谄媚，如果用户的提问前提有误，请直接指出.",
            })
        end
    end

    local principles_list = {}
    if principles then
        if type(principles) == "table" then
            if principles.name and principles.content then
                -- Single structured prompt table
                table.insert(principles_list, principles)
            else
                -- Array of structured prompts or strings
                for _, p in pairs(principles) do
                    if type(p) == "table" and p.name and p.content then
                        table.insert(principles_list, p)
                    elseif type(p) == "string" then
                        table.insert(principles_list, { name = "Instruction", content = p })
                    end
                end
            end
        else
            -- Single string
            table.insert(principles_list, { name = "Instruction", content = tostring(principles) })
        end
    end

    local parts = {}

    -- 手动按顺序构造 JSON 字段，以绕过 Lua table 的无序性
    if system_prompt then
        table.insert(parts, '"Rules": ' .. vim.fn.json_encode(rules))
    end

    if principles_list and next(principles_list) ~= nil then
        table.insert(parts, '"Principles": ' .. vim.fn.json_encode(principles_list))
    end

    if behavior and behavior ~= "" then
        local behavior_table = {
            usage = "You *MUST* follow the behaviors below step by step to complete them.",
            content = behavior
        }
        table.insert(parts, '"Behaviors": ' .. vim.fn.json_encode(behavior_table))
    end

    if user_requirement and user_requirement ~= "" then
        table.insert(parts, '"User_requirements": ' .. vim.fn.json_encode(user_requirement))
    end


    return "{\n" .. table.concat(parts, ",\n") .. "\n}"
end

return M
