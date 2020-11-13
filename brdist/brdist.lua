-- modified from TParty.lua and distance.lua

_addon.name = 'brdist'
_addon.author = 'wes'
_addon.version = '0.9'
_addon.command = 'brdist'

require('functions')
require('tables')
texts = require('texts')
config = require('config')

defaults = {}
defaults.near_dist = 9.9
defaults.blue_dist = 0      -- used if greater than near_dist
defaults.max_cast_coloring = true
defaults.interval = 0.2
defaults.side = 'left'
defaults.ally = true
defaults.bg = {}
defaults.bg.visible = false
defaults.target_dist = true

settings = config.load(defaults)

dist = T{}
dist_x_pos = {left = -158, right = 0}
party_y_pos = {}
for i = 1, 6 do
    party_y_pos[i] = -43 - 20 * (6 - i)
end
party_indices = {p0 = 1, p1 = 2, p2 = 3, p3 = 4, p4 = 5, p5 = 6}

for i = 1, 17 do
    local party = (i / 6):floor() + 1
    local key = {'p%i', 'a1%i', 'a2%i'}[party]:format(i % 6)
    dist[key] = texts.new('', {
        pos = {
            x = dist_x_pos[settings.side],
            y = {-43, -317, -214}[party] - (party == 1 and 20 or 16) * (5 - i%6)
        },
        bg    = {visible = settings.bg.visible},
        flags = {right = true, bottom = true, bold = true, draggable = false},
        text  = {size = 10}
    })
end
dist.target = texts.new('', {
    pos   = {x = -140, y = -180},
    bg    = {visible = false},
    flags = {right = true, bottom = true, bold = true, draggable = false},
    text  = {size = 14, stroke = {width = 2}}
})

function update_texts()
    local party = windower.ffxi.get_party()

    for text, key in dist:it() do
        if key == 'target' then
            if settings.target_dist then

                local player = windower.ffxi.get_player()
                local target = windower.ffxi.get_mob_by_index(player and player.target_index or 0)

                if target and target.valid_target then

                    local target_dist = target.distance:sqrt()

                    if settings.max_cast_coloring and target_dist > 20.5 then
                        text:color(255, 50, 50)
                    else
                        text:color(255, 255, 255)
                    end

                    text:pos_y(-180 + 20 * (6 - party.party1_count))
                    text:text('%.1f':format(target_dist))
                    text:show()
                else
                    text:hide()
                end
            else
                text:hide()
            end
        else
            local member = party[key]
            if member and member.mob and member.mob.valid_target then

                local member_dist = member.mob.distance:sqrt()

                if member_dist < settings.near_dist then
                    text:color(255, 255, 255)
                    text:stroke_width(1)
                elseif member_dist < settings.blue_dist then
                    text:color(0, 200, 255)
                    text:stroke_width(0)
                elseif settings.max_cast_coloring and member_dist < 20.5 then
                    text:color(255, 0, 0)
                    text:stroke_width(0)
                else
                    text:color(0, 0, 0)
                    text:stroke_width(0)
                end

                if key:startswith('p') then
                    text:pos_y(party_y_pos[party_indices[key] + 6 - party.party1_count])
                    text:text('%.1f':format(member_dist))
                    text:show()
                elseif settings.ally then
                    text:text('%.1f':format(member_dist))
                    text:show()
                else
                    text:hide()
                end
            else
                text:hide()
            end
        end
    end
end

windower.register_event('addon command', function(...)
    local args = {...}

    if args[1] == 'dist' then
        if #args > 1 then
            args[2] = args[2]:lower()
            if tonumber(args[2]) then
                settings.near_dist = tonumber(args[2])
                if #args == 3 and tonumber(args[3]) then
                    settings.blue_dist = tonumber(args[3])
                else
                    settings.blue_dist = 0
                end
            elseif args[2]:startswith('geo') then
                settings.near_dist = 6.1    -- bubble for tarus
                settings.blue_dist = 9.9
            elseif args[2]:startswith('cor') then
                settings.near_dist = 7.9    -- luzaf roll
                settings.blue_dist = 15.9   -- base roll
            elseif args[2]:startswith('thf') then
                settings.near_dist = 9.9
                settings.blue_dist = 12.5   -- accomplice
            else
                settings.near_dist = 9.9    -- typical aoe spell radius
                settings.blue_dist = 0
            end
        end
        print('brdist: nearby is %.1f yalms':format(settings.near_dist))
        if settings.blue_dist > settings.near_dist then
            print('brdist: blue to %.1f yalms':format(settings.blue_dist))
        end
    elseif args[1] == 'ally' then
        settings.ally = not settings.ally
        if not settings.ally then
            for text, key in dist:it() do
                if key:startswith('a') and text:visible() then
                    text:hide()
                end
            end
        end
        print('brdist: %s allies':format(settings.ally and 'showing' or 'hiding'))
    elseif args[1] == 'bg' then
        settings.bg.visible = not settings.bg.visible
        for text in dist:it() do
            text:bg_visible(settings.bg.visible)
        end
    elseif args[1] == 'lr' then
        settings.side = (settings.side == 'left') and 'right' or 'left'
        for text in dist:it() do
            text:pos_x(dist_x_pos[settings.side])
        end
    elseif args[1] == 'target' then
        settings.target_dist = not settings.target_dist
        if not settings.target_dist then dist.target:hide() end
        print('brdist: %s target':format(settings.target_dist and 'showing' or 'hiding'))
    elseif args[1] == 'interval' then
        if tonumber(args[2]) then
            local current_interval = settings.interval
            settings.interval = math.min(math.max(0.1, tonumber(args[2])), 5)
            if current_interval ~= settings.interval and update_thread then
                coroutine.close(update_thread)
                update_thread = update_texts:loop(settings.interval)
            end
        end
        print('brdist: update interval is %.1f seconds':format(settings.interval))
    elseif args[1] == 'save' then
        config.save(settings, 'all')
        print('brdist: settings saved')
    else
        print('usage:')
        print(' brdist dist [<near_dist> [<blue_dist]|<job>]')
        print(' brdist ally')
        print(' brdist bg')
        print(' brdist lr')
        print(' brdist target')
        print(' brdist interval <update_interval>')
        print(' brdist save')
    end
end)

update_thread = update_texts:loop(settings.interval)
