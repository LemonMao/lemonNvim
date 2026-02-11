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

-- 构造 AI Prompt 的核心逻辑
function M.AI_prompt(role, behavior, user_prompt)
    local system_prompt = M.read_file(M.ai_path .. "/agents/general.md")
    if not system_prompt or system_prompt == "" then
        system_prompt = "始终使用中文回复。保持绝对客观与真实，拒绝谄媚，如果用户的提问前提有误，请直接指出."
    end
    local final_user_prompt = user_prompt or "User requirements may be empty or as specified below."

    return "Follow system rules:\n{{{\n" .. (system_prompt or "") .. "\n}}}\n" ..
        "Work as role:\n{{{\n" .. (role or "") .. "\n}}}\n" ..
        "Perform the behavior:\n{{{\n" .. (behavior or "") .. "\n}}}\n" ..
        final_user_prompt
end

return M
