-- modified from TParty.lua
-- TODO use an icon instead of a textbox

_addon.name = 'charmed'
_addon.author = 'wes'
_addon.version = '0.3'

require('sets')
require('functions')
require('lists')
require('strings')
texts = require('texts')

alliance = T{}
new_charms = L{}
new_uncharms = L{}

-- only update every <interval> seconds
interval = 0.5

local x_pos = windower.get_windower_settings().ui_x_res - 17

for i = 0, 17 do
    local party = (i / 6):floor() + 1
    local key = {'p%i', 'a1%i', 'a2%i'}[party]:format(i % 6)
    local pos_base = {-42, -397, -296}
    alliance[key] = T{
        x = x_pos,
        y = pos_base[party] + 16 * (i % 6),
        box = nil
    }
end

key_indices = {p0 = 1, p1 = 2, p2 = 3, p3 = 4, p4 = 5, p5 = 6}
pt_y_pos = {}
for i = 1, 6 do
    pt_y_pos[i] = -42 - 20 * (6 - i)
end

function update()
    local party = T(windower.ffxi.get_party())
    new_charms:clear()
    new_uncharms:clear()

    for slot, key in alliance:it() do
        local member = party[key]
        if member and member.mob and member.mob.valid_target then
            if member.mob.charmed and not member.mob.is_npc then
                -- Adjust position for party member count
                if key:startswith('p') then
                    slot.y = pt_y_pos[key_indices[key] + 6 - party.party1_count]
                end
                if slot.box == nil then
                    -- create text box
                    slot.box = texts.new('<3', {
                        pos = {
                            x = slot.x,
                            y = slot.y
                        },
                        bg = {
                            red = 255,
                            green = 80,
                            blue = 80,
                            visible = true,
                        },
                        flags = {
                            right = false,
                            bottom = true,
                            bold = true,
                            draggable = false,
                            italic = false,
                        },
                        text = {
                            size = 10,
                            alpha = 255,
                            red = 255,
                            green = 255,
                            blue = 255,
                        },
                    })
                    slot.box:show()

                    new_charms:append(member.name)
                else
                    -- possibly move box
                    slot.box:pos(slot.x, slot.y)
                end
            else
                if slot.box ~= nil then
                    -- destroy text box
                    slot.box:hide()
                    slot.box:destroy()
                    slot.box = nil

                    new_uncharms:append(member.name)
                end
            end
        else
            if slot.box ~= nil then
                -- destroy text box
                slot.box:hide()
                slot.box:destroy()
                slot.box = nil
            end
        end
    end
    if not new_charms:empty() then
        windower.add_to_chat(123, 'CHARM <3 CHARM <3 CHARM <3 CHARM <3 CHARM')
        windower.add_to_chat(123, new_charms:sort():concat(' '))
        windower.add_to_chat(123, 'CHARM <3 CHARM <3 CHARM <3 CHARM <3 CHARM')
    end
    if not new_uncharms:empty() then
        windower.add_to_chat(121, 'uncharmed: ' .. new_uncharms:sort():concat(' '))
    end
end

update_thread = update:loop(interval)
