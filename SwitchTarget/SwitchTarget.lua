_addon_name = 'SwitchTarget'
_addon_author = 'wes'
_addon_version = '0.3'

packets = require('packets')

windower.register_event('outgoing chunk', function(id, data, modified, injected, blocked)
    if id == 0x01A then -- outgoing action packet
        if injected or blocked then return end

        local player = windower.ffxi.get_player()

        if player.status == 1
        or player.status == 0 and os.time() - last_disengage_time <= 1
        then -- player is engaged, or was recently

            local p = packets.parse('outgoing', data)

            if (p['Category'] == 0x02 or p['Category'] == 0x0F)
            and valid_target(p['Target Index'])
            then -- inject an early clientside target swap for "engage enemy" and "switch target" actions
                packets.inject(packets.new('incoming', 0x058, {
                    ['Player'] = player.id,
                    ['Target'] = p['Target'],
                    ['Player Index'] = player.index
                }))

                -- replace "engage enemy" with "switch target" in outgoing packet
                if p['Category'] == 0x02 then
                    p['Category'] = 0x0F
                    return packets.build(p)
                end
            end
        end
    end
end)

last_disengage_time = 0
windower.register_event('status change', function(new, old)
    if new == 0 and old == 1 then -- just disengaged
        last_disengage_time = os.time()
    end
end)

-- check that the new target is valid before changing any packets (this is probably unnecessary)
function valid_target(index)
    local mob = windower.ffxi.get_mob_by_index(index)
    local is_valid = mob and mob.valid_target and (mob.spawn_type == 16 or mob.charmed and mob.spawn_type % 2 == 1)
    if not is_valid then print('ST: refused to swap target') end
    return is_valid
end
