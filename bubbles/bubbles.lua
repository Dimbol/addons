-- GEO bubble tracker
-- three optional output modes:
-- * faux party chat
-- * list in chatlog upon command
-- * colorful textbox HUD

_addon.name = 'bubbles'
_addon.author = 'wes'
_addon.version = '0.4.4'
_addon.command = 'bubbles'

require('bit')
require('functions')
require('lists')
require('pack')
require('sets')
require('tables')
config = require('config')
math = require('math')
texts = require('texts')

require('bubble_info')

defaults = {}
defaults.faux_party_chat = false
defaults.party_hud = {}
defaults.party_hud.enabled = true
defaults.party_hud.show_dist = true -- show distances for out of range bubbles
defaults.party_hud.text_settings = {}
defaults.party_hud.text_settings.pos   = {x = -189, y = 45}
defaults.party_hud.text_settings.bg    = {alpha = 150}
defaults.party_hud.text_settings.flags = {right = true, bold = true}
defaults.party_hud.text_settings.text  = {size = 12, font = 'Courier New', stroke = {width = 1}}
defaults.update_interval = 0.5
defaults.logcolor = 121 -- basic system message color

settings = config.load(defaults)

-- table mapping a name to active geo/indi bubbles
active_bubbles = T{}

-- table mapping a name to their previous geo/indi/entrust, never cleared
previous_bubbles = T{}

-- textbox listing active bubbles, one per line
party_hud = texts.new('', table.copy(settings.party_hud.text_settings))

-- the width of a distance in the party_hud textbox may vary with font and font size
-- an offscreen textbox is created to find out what that width is at runtime (assuming the font is monospace)
-- party_hud is shifted right by this width when distances are shown, so that the words within the textbox appear stationary
if settings.party_hud.text_settings.flags.right then
    local offscreen_settings = table.copy(settings.party_hud.text_settings)
    table.update(offscreen_settings, {flags = {bottom = false}, pos = {y = -100}}, true)
    offscreen = texts.new(' (9.9)', offscreen_settings)
    offscreen:show()
end

death_message_ids = S{6,20,113,406,605,646}

windower.register_event('incoming chunk', function(id, data)
    if id == 0x028 then -- action packet
        update_bubbles_from_action_packet(windower.packets.parse_action(data))
    elseif id == 0x029 then -- action message packet
        local message_id = data:unpack('H',0x19)%32768
        if death_message_ids:contains(message_id) then
            local target_id = data:unpack('I',0x09)
            local mob = windower.ffxi.get_mob_by_id(target_id)
            if mob and mob.in_alliance then
                -- member died; clear their bubbles
                active_bubbles[mob.name] = nil
            end
        end
    elseif id == 0x037 then -- player update packet
        local player_id = data:unpack('I',0x25)
        local indi_effect = data:unpack('b7',0x59)
        update_bubbles_from_update_packet(player_id, indi_effect)
    elseif id == 0x00D then -- pc update packet
        local pc_id = data:unpack('I',0x05)
        local indi_effect = data:unpack('b7',0x43)
        update_bubbles_from_update_packet(pc_id, indi_effect)
    -- npcs do not have visible indi effects
    elseif id == 0x075 and data:unpack('I',0x1D) > 0 then -- timed battle start (eg, unity, geas fete, domain invasion)
        -- wipe all active bubbles but preserve JAs
        just_started_battle = os.time()  -- ignore update packets for a bit
        for bubs in active_bubbles:it() do
            bubs.Indi = nil
            bubs.Geo = nil
        end
    end
end)

windower.register_event('logout', 'zone change', function()
    -- stop updating until more geomancy happens
    stop_update_loops()
    active_bubbles:clear()
end)

windower.register_event('load', function()
    if windower.ffxi.get_info().logged_in then
        -- start updating right away if addon is loaded or reloaded while playing
        start_update_loops()
    end
end)

function update_bubbles_from_action_packet(act)
    if act.category == 4 then -- completed spells
        local spell_id = act.param
        if 768 <= spell_id and spell_id <= 827 then -- geomancy spell id
            local caster = windower.ffxi.get_mob_by_id(act.actor_id)
            if caster and caster.in_alliance then
                -- update bubbles
                local caster_id = act.actor_id
                local target_id = act.targets[1].id
                local member = caster
                local now = os.time()

                local bub = bubble_info[spell_id]
                local entrust = bub.type == 'Indi' and caster_id ~= target_id or false
                if entrust then member = windower.ffxi.get_mob_by_id(target_id) or {name = '?'} end

                active_bubbles[member.name] = active_bubbles[member.name]
                                              or {member_id = (bub.type == 'Indi') and target_id or caster_id, trust_member = member.is_npc}
                active_bubbles[member.name][bub.type] = {effect = bub.effect, debuff = bub.debuff,
                                                         entrusted_by = entrust and caster.name or nil, start_time = now}
                if bub.type == 'Geo' or entrust and active_bubbles[caster.name] then
                    local jas = bub.type == 'Geo' and {'BoG','Bolster','Wide'} or {'Bolster','Wide'}
                    for _, ja in ipairs(jas) do
                        if active_bubbles[caster.name][ja] and now < active_bubbles[caster.name][ja].end_time then
                            active_bubbles[member.name][bub.type][ja] = true
                            if ja == 'BoG' then active_bubbles[caster.name][ja] = nil end
                        end
                    end
                end
                previous_bubbles[caster.name] = previous_bubbles[caster.name] or {}
                previous_bubbles[caster.name][entrust and 'Entrust' or bub.type] = bub.effect
                start_update_loops()

                if settings.faux_party_chat then
                    local line = '%s-%s by %s':format(bub.type, bub.effect, caster.name)
                    if entrust then
                        line = line .. ' on ' .. member.name
                    elseif bub.type == 'Geo' and active_bubbles[member.name].Geo.BoG then
                        line = '[%s]%s':format('BoG', line)
                    end
                    if active_bubbles[member.name][bub.type].Bolster then
                        line = '[Bolster]' .. line
                    end
                    windower.add_to_chat(5,line)
                end
            end
        end
    elseif act.category == 6 then -- job abilities (nondamaging, blinkable)
        local ja_id = act.param
        local bub_ja = bubble_jas[ja_id]
        if bub_ja then
            local caster = windower.ffxi.get_mob_by_id(act.actor_id)
            if caster and caster.in_alliance then
                if bub_ja.name == 'EA' or bub_ja.name == 'LE' then
                    if active_bubbles[caster.name].Geo then active_bubbles[caster.name].Geo[bub_ja.name] = true end
                else
                    active_bubbles[caster.name] = active_bubbles[caster.name] or {member_id = act.actor_id}
                    active_bubbles[caster.name][bub_ja.name] = {end_time = os.time() + bub_ja.dur}
                end
            end
        end
    end
end

function update_bubbles_from_update_packet(pc_id, indi_effect)
    if just_started_battle then return end

    local wide  = bit.band(indi_effect, 0x20) ~= 0
    indi_effect = bit.band(indi_effect, 0x5F)

    local pc = windower.ffxi.get_mob_by_id(pc_id)
    if pc and pc.in_alliance and pc.valid_target then
        if indi_effect == 0 then
            if active_bubbles[pc.name] and active_bubbles[pc.name].Indi then
                if (os.time() - active_bubbles[pc.name].Indi.start_time) > 3 then
                    -- indi effect expired
                    active_bubbles[pc.name].Indi = nil
                end
            end
        elseif pc.hpp > 0 then
            active_bubbles[pc.name] = active_bubbles[pc.name] or {member_id = pc_id}
            if not active_bubbles[pc.name].Indi then
                -- new indicolure; guess its type
                local likely_bub = bubble_info[likely_bubble_id_from_indi_effect[indi_effect]]
                if not likely_bub then return end
                active_bubbles[pc.name].Indi = {effect = likely_bub.effect, debuff = likely_bub.debuff,
                                                start_time = os.time(), assumed = true}
                start_update_loops()
            end
            active_bubbles[pc.name].Indi.Wide = wide
        end
    end
end

function update_active_bubbles()
    local party = windower.ffxi.get_party()
    local player = windower.ffxi.get_mob_by_target('me')
    if not party or not player then return end -- sometimes these are nil, eg, when moving between omen floors
    local now = os.time()

    -- first, scan the party for new luopans and expired bolsters
    for _, member in pairs(party) do
        if type(member) == 'table' then
            if member.mob and member.mob.valid_target and member.mob.pet_index then
                -- nearby ally with a pet
                local pet = windower.ffxi.get_mob_by_index(member.mob.pet_index)
                if pet and pet.valid_target and pet.name == 'Luopan' then
                    active_bubbles[member.name] = active_bubbles[member.name] or {member_id = member.mob.id}
                    if not active_bubbles[member.name].Geo then
                        if not just_started_battle then
                            -- new luopan; guess its type
                            local likely_bub = bubble_info[likely_bubble_id_from_model[pet.models[1]]]
                            if likely_bub then
                                active_bubbles[member.name].Geo = {effect = likely_bub.effect, debuff = likely_bub.debuff,
                                                                   start_time = now, assumed = true}
                            end
                        end
                    elseif active_bubbles[member.name].Geo.Bolster then
                        -- expire luopan bolsters
                        if not active_bubbles[member.name].Bolster
                        or active_bubbles[member.name].Bolster.end_time <= now then
                            active_bubbles[member.name].Geo.Bolster = nil
                        end
                    end
                    if active_bubbles[member.name].Geo then
                        -- attach up-to-date mob table for luopan position and hpp
                        active_bubbles[member.name].Geo.luopan = pet
                    end
                elseif active_bubbles[member.name] then
                    -- the pet is far or not a luopan
                    active_bubbles[member.name].Geo = nil
                end
            elseif active_bubbles[member.name] then
                -- member is no longer nearby or does not have a pet
                if active_bubbles[member.name].Geo and (now - active_bubbles[member.name].Geo.start_time) <= 3 then
                    -- geocolure cast recently; luopan may not have loaded yet
                else
                    active_bubbles[member.name].Geo = nil
                end
            end
        end
    end

    -- next, clean up the table
    for name, bubs in pairs(active_bubbles) do
        local sylvie_indi_dur = 360
        if bubs.trust_member and bubs.Indi and bubs.Indi.start_time + sylvie_indi_dur < now then
            bubs.Indi = nil -- trusts do not have visibile indicolures
        end

        local ja_active = false
        for _, ja in ipairs({'BoG','Bolster','Wide'}) do
            if bubs[ja] then
                if bubs[ja].end_time <= now then
                    bubs[ja] = nil
                else
                    ja_active = true
                end
            end
        end

        if not bubs.Geo and not bubs.Indi and not ja_active then
            active_bubbles[name] = nil
        end
    end

    -- reallow update packets to infer bubbles if a moment has passed
    if just_started_battle and now - just_started_battle > 1 then
        just_started_battle = nil
    end

    if settings.party_hud.enabled then update_party_hud(party, player) end
end

function update_party_hud(party, player)
    -- first, create a list of bubbles from active_bubbles and sort it
    local bubble_list = L{}
    local max_name_length = 0
    local max_colure_length = 0
    for _, member in pairs(party) do
        if type(member) == 'table' and member.mob and member.mob.valid_target then
            if active_bubbles[member.name] then
                for _, colure in ipairs({'Indi','Geo'}) do
                    if active_bubbles[member.name][colure] then
                        local bub = {member = member.name == player.name and player or member.mob,
                                     bub = active_bubbles[member.name][colure], type = colure}
                        bubble_list:append(bub)
                        max_name_length = math.max(max_name_length, bub.member.name:length())
                        max_colure_length = math.max(max_colure_length, colure:length() + bub.bub.effect:length())
                    end
                end
            end
        end
    end
    bubble_list:sort(function(a,b)
        if a.member.name ~= b.member.name then
            -- put player bubbles first
            if     a.member.name == player.name then return true
            elseif b.member.name == player.name then return false
            else return a.member.name < b.member.name
            end
        else
            -- indi before geo
            return a.type > b.type
        end
    end)

    -- then add a line to the text box for each bubble with the following format
    -- <colorized_member_name> :[<ja_mark>]<colorized_colure>[?][<colorized_distance>]
    if not bubble_list:empty() then
        local redundancies = redundant_debuff_effects()
        local target
        if settings.party_hud.show_dist then
            target = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().target_index or 0)
        end

        local distance_shown = false
        local lines = bubble_list:map(function(bub)
            local member  = bub.member
            local luopan  = bub.bub.luopan
            local effect  = bub.bub.effect
            local debuff  = bub.bub.debuff
            local assumed = bub.bub.assumed
            local bolster = bub.bub.Bolster      or false
            local wide    = bub.bub.Wide         or false
            local entrust = bub.bub.entrusted_by or false

            local bubble_enhancement_mark = ' '
            if bub.type == 'Geo' then
                for _, bub_ja in ipairs({'Bolster','BoG','EA','LE'}) do
                    if bub.bub[bub_ja] then
                        bubble_enhancement_mark = bubble_ja_symbols[bub_ja]
                        break
                    end
                end
            elseif entrust then
                if bolster then bubble_enhancement_mark = bubble_ja_symbols.Bolster end
            elseif active_bubbles[member.name] and active_bubbles[member.name].Bolster then
                bubble_enhancement_mark = bubble_ja_symbols.Bolster
            end

            local member_color
            if not (debuff or member.in_party) then
                -- unapplicable buff
                member_color = '\\cs(140,140,140)'
            elseif entrust then
                member_color = '\\cs(255,255,0)'
            else
                member_color = '\\cs(240,240,240)'
            end

            -- the leading space here seems necessary when a textbox starts with a color code
            local member_bubble_string = (' %s%' .. max_name_length .. 's\\cr %s%s%s%s-%s\\cr%s'):format(
                member_color, member.name,
                redundancies[effect] and '\\cs(255,0,0)!\\cr' or ':',
                bubble_enhancement_mark,
                bubble_text_colors[effect],
                bub.type, effect,
                assumed and '?' or ' '
            )

            local dist_string = ''
            if settings.party_hud.show_dist then
                local distance
                local padding = max_colure_length - bub.type:length() - effect:length()

                if debuff then
                    if target and target.valid_target and target.spawn_type == 16 and target.hpp > 0 then
                        -- player is targetting a monster
                        if bub.type == 'Indi' then
                            distance = math.sqrt((target.x-member.x)^2 + (target.y-member.y)^2 + (target.z-member.z)^2)
                        elseif luopan then
                            distance = math.sqrt((target.x-luopan.x)^2 + (target.y-luopan.y)^2 + (target.z-luopan.z)^2)
                        end
                        if distance and distance > (6 * (wide and 2 or 1) + target.model_size/2) then
                            -- debuff bubble too far from target
                            if distance < 9.95 then padding = padding + 1 end
                            dist_string = ('\\cs(255,0,0)%' .. padding .. 's(%.1f)\\cr'):format('', distance)
                            distance_shown = true
                        end
                    end
                elseif member.in_party then
                    if bub.type == 'Indi' then
                        distance = member.distance:sqrt()
                    elseif luopan then
                        distance = luopan.distance:sqrt()
                    end
                    if distance and distance > (6 * (wide and 2 or 1) + 0.3) then
                        -- buff bubble too far from player
                        if distance < 9.95 then padding = padding + 1 end
                        dist_string = ('\\cs(255,255,0)%' .. padding .. 's(%.1f)\\cr'):format('', distance)
                        distance_shown = true
                    end
                end
            end

            return member_bubble_string .. dist_string
        end)

        if settings.party_hud.text_settings.flags.right then
            if distance_shown then
                distance_pixel_width = distance_pixel_width or find_distance_pixel_width()
                party_hud:pos_x(settings.party_hud.text_settings.pos.x + distance_pixel_width)
            else
                party_hud:pos_x(settings.party_hud.text_settings.pos.x)
            end
        end

        party_hud:text(lines:concat('\n'))
        party_hud:show()
    else
        party_hud:hide()
    end
end

function find_distance_pixel_width()
    local distance_pixel_width = 0
    if offscreen then
        distance_pixel_width = offscreen:extents()
        if distance_pixel_width > 0 then
            distance_pixel_width = distance_pixel_width - 3 -- exclude width of borders, ignoring padding
            offscreen:hide(); offscreen:destroy(); offscreen = nil
        end
    end
    if distance_pixel_width == 0 then distance_pixel_width = 59 end -- works for defaults

    return distance_pixel_width
end

function redundant_debuff_effects()
    local redundancies = S{}
    local debuff_counts = setmetatable({}, {__index = function(t,k) return 0 end})

    for bubs in active_bubbles:it() do
        for _, colure in ipairs({'Indi','Geo'}) do
            if bubs[colure] and bubs[colure].debuff then
                debuff_counts[bubs[colure].effect] = debuff_counts[bubs[colure].effect] + 1
            end
        end
    end

    for debuff, count in pairs(debuff_counts) do
        if count > 1 then redundancies:add(debuff) end
    end

    return redundancies
end

function start_update_loops()
    if not update_thread and settings.party_hud.enabled then
        update_thread = update_active_bubbles:loop(settings.update_interval)
    end
end

function stop_update_loops()
    if update_thread then
        coroutine.close(update_thread)
        update_thread = nil
        party_hud:hide()
    end
end

windower.register_event('addon command', function(...)
    local args = {...}
    if args[1] == 'list' then
        list_active_bubbles()
    elseif args[1] == 'prev' or args[1] == 'last' then
        list_previous_bubbles()
    elseif args[1] == 'chat' then
        settings.faux_party_chat = not settings.faux_party_chat
        windower.add_to_chat(defaults.logcolor,'bubbles: fake party chat is now %s.':format(settings.faux_party_chat and 'on' or 'off'))
    elseif args[1] == 'phud' then
        settings.party_hud.enabled = not settings.party_hud.enabled
        windower.add_to_chat(defaults.logcolor,'bubbles: party hud is now %s.':format(settings.party_hud.enabled and 'on' or 'off'))
        if settings.party_hud.enabled then start_update_loops() else stop_update_loops() end
    elseif args[1] == 'interval' then
        if tonumber(args[2]) then settings.update_interval = math.min(math.max(0.1, tonumber(args[2])), 5) end
        windower.add_to_chat(defaults.logcolor,'bubbles: update interval is now %.1f.':format(settings.update_interval))
    elseif args[1] == 'save' then
        config.save(settings, args[2])
        windower.add_to_chat(defaults.logcolor,'bubbles: settings saved.')
    else
        print('bubbles usage:')
        print('  \\cs(255,255,255)list\\cr             Lists active bubbles')
        print('  \\cs(255,255,255)prev|last\\cr        Lists previous indi/geo/entrust')
        print('  \\cs(255,255,255)chat\\cr             Toggle fake party chat for bubbles')
        print('  \\cs(255,255,255)phud\\cr             Toggle party HUD text boxes')
        print('  \\cs(255,255,255)interval [<sec>]\\cr Shows or sets current HUD update interval (0.1s to 5.0s)')
        print('  \\cs(255,255,255)save [all]\\cr       Saves current settings for current or all characters')
        print('  \\cs(255,255,255)help\\cr             Displays this message')
    end
end)

function list_active_bubbles()
    if not update_thread then update_active_bubbles() end

    if active_bubbles:empty() then
        windower.add_to_chat(defaults.logcolor,'bubbles: currently active: none to list')
    else
        windower.add_to_chat(defaults.logcolor,'bubbles: currently active:')
        local player = windower.ffxi.get_mob_by_target('me')
        local redundancies = redundant_debuff_effects()

        local sorted_names = active_bubbles:keyset():sort()
        for name in sorted_names:it() do
            local member = windower.ffxi.get_mob_by_id(active_bubbles[name].member_id)
            if member and member.valid_target and member.in_alliance then
                local bub_strings = L{}
                local str

                if active_bubbles[name].Indi then
                    local bub = active_bubbles[name].Indi
                    if bub.entrusted_by then
                        str = 'Indi-%s%s from %s':format(bub.effect, bub.assumed and '?' or '', bub.entrusted_by)
                        if bub.Bolster then str = '[Bolster]' .. str end
                    else
                        str = 'Indi-%s%s':format(bub.effect, bub.assumed and '?' or '')
                        if active_bubbles[name].Bolster and os.time() < active_bubbles[name].Bolster.end_time then
                            str = '[Bolster]' .. str
                        end
                    end
                    bub_strings:append(redundancies[bub.effect] and '(!)'..str or str)
                end

                if active_bubbles[name].Geo then
                    local bub = active_bubbles[name].Geo
                    if bub.luopan then
                        local distance = math.sqrt((player.x-bub.luopan.x)^2 + (player.y-bub.luopan.y)^2 + (player.z-bub.luopan.z)^2)
                        str = 'Geo-%s%s [%0.1f yalms]':format(bub.effect, bub.assumed and '?' or '', distance)
                    else
                        str = 'Geo-%s%s [? yalms]':format(bub.effect, bub.assumed and '?' or '')
                    end
                    for _, ja in ipairs({'LE','EA','BoG','Bolster'}) do
                        if bub[ja] then
                            if ja ~= 'Bolster'
                            or active_bubbles[name].Bolster and os.time() < active_bubbles[name].Bolster.end_time then
                                str = '[%s]%s':format(ja, str)
                            end
                        end
                    end
                    bub_strings:append(redundancies[bub.effect] and '(!)'..str or str)
                end

                if not bub_strings:empty() then
                    windower.add_to_chat(defaults.logcolor,'bubbles: %-16s (%s)':format(name, bub_strings:concat(', ')))
                end
            end
        end
    end
end

function list_previous_bubbles()
    if previous_bubbles:empty() then
        windower.add_to_chat(defaults.logcolor,'bubbles: previously seen: none')
    else
        windower.add_to_chat(defaults.logcolor,'bubbles: previously seen:')
        local sorted_names = previous_bubbles:keyset():sort()
        for name in sorted_names:it() do
            local bub_strings = L{}
            for _, colure in ipairs({'Indi','Geo','Entrust'}) do
                if previous_bubbles[name][colure] then
                    bub_strings:append('%s-%s':format(colure, previous_bubbles[name][colure]))
                end
            end
            windower.add_to_chat(defaults.logcolor,'bubbles: %-16s (%s)':format(name, bub_strings:concat(', ')))
        end
    end
end
