local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BASE_URL = "https://raw.githubusercontent.com/HiddenSquidHiding/GingeHUB/main/"

local modules = {
    "AutoLevel",
    "Hub",
    "Farm",
    "Merchants",
    "UI",
    "Remotes",
    "Crates",
    "Utils"
}

local WoodzHUB = ReplicatedStorage:FindFirstChild("WoodzHUB") or Instance.new("Folder")
WoodzHUB.Name = "WoodzHUB"
WoodzHUB.Parent = ReplicatedStorage

-- Function to load a module from URL
local function loadModule(name)
    local url = BASE_URL .. name .. ".lua"
    local success, code = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if not success then
        warn("Failed to fetch " .. name .. ".lua: " .. code)
        return nil
    end
    
    local module = Instance.new("ModuleScript")
    module.Name = name
    module.Source = code
    module.Parent = WoodzHUB
    return module
end

for _, modName in ipairs(modules) do
    loadModule(modName)
end

local mainCode = HttpService:GetAsync(BASE_URL .. "Main.client.lua")
loadstring(mainCode)()