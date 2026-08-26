-- ~/.config/hypr/modules/monitors.lua
-- Monitor & Workspace configuration

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Persistent named workspaces (stay visible in the Noctalia workspace indicator)
for i, name in ipairs({ "web", "code", "chat", "game", "design" }) do
	hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2", persistent = true, default_name = name })
end
