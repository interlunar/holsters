-- Created by Jamelele, last updated April 2019

-- Do NOT edit this file unless you know what you're doing.
-- If you're looking to edit the configuration, go to config.lua

local default_weapon = GetHashKey(config.weapon) -- The weapon that the script looks for if one isn't specified for a holster, this is the glock.
local active = false
local ped = nil -- Cache the ped
local currentPedData = nil -- Config data for the current ped

-- Helper function to invert tables
function table_invert(t)
  local s={}
  for k,v in pairs(t) do
    s[v]=k
  end
  return s
end

-- Slow loop to determine the player ped and if it is of interest to the algorithm
-- This only needs to be run every 5 seconds or so, as ped changes are infrequent
Citizen.CreateThread(function()
  while true do
    ped = GetPlayerPed(-1)
    local ped_hash = GetEntityModel(ped)
    local enable = false -- We updated the 'enabled' variable in the upper scope with this at the end
    -- Loop over peds in the config
    for ped, data in pairs(config.peds) do
      if GetHashKey(ped) == ped_hash then 
        enable = true -- By default, the ped will have its holsters enabled
        if data.enabled ~= nil then -- Optional 'enabled' option
          enable = data.enabled
        end
        currentPedData = data
        break
      end
    end
    active = enable
    Citizen.Wait(5000)
  end
end)

-- Faster loop to change holster textures
local last_weapon = nil -- Variable used to save the weapon from the last tick
Citizen.CreateThread(function()
  while true do
    if active then -- A ped in the config is in use, so we start checking
      current_weapon = GetSelectedPedWeapon(ped)
      if current_weapon ~= last_weapon then -- The weapon in hand has changed, so we need to check for holsters
        
        for component, holsters in pairs(currentPedData.components) do
          local holsterDrawable = GetPedDrawableVariation(ped, component) -- Current drawable of this component
          local holsterTexture = GetPedTextureVariation(ped, component) -- Current texture, we need to preserve this

          local emptyHolster = holsters[holsterDrawable] -- The corresponding empty holster
          if emptyHolster and current_weapon == default_weapon then
            SetPedComponentVariation(ped, component, emptyHolster, holsterTexture, 0)
            break
          end

          local filledHolster = table_invert(holsters)[holsterDrawable] -- The corresponding filled holster
          if filledHolster and current_weapon ~= default_weapon and last_weapon == default_weapon then
            SetPedComponentVariation(ped, component, filledHolster, holsterTexture, 0)
            break
          end
        end
      end
      last_weapon = current_weapon
    end
    Citizen.Wait(200)
  end
end)
