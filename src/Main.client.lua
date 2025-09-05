-- StarterPlayerScripts/Main.client.lua
-- Local ModuleScripts approach (Roblox Studio / your own experience)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hub = require(ReplicatedStorage:WaitForChild("WoodzHUB"):WaitForChild("Hub"))
Hub.start()
