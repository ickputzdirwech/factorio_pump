function add_area_information(event, mod_context)
    mod_context.area = {}
    mod_context.area_bounds = event.area

    -- fill the map with default data 
    for x = event.area.left_top.x, event.area.right_bottom.x, 1 do
        mod_context.area[x] = {}
        for y = event.area.left_top.y, event.area.right_bottom.y, 1 do
            mod_context.area[x][y] = "undefined"
        end
    end

    -- mark where the pumps will be
    for i, entity in pairs(event.entities) do
        local direction = defines.direction.east
        if can_place_extractor(event.surface, entity.position, direction,
                               mod_context.toolbox) then

            local relative_bounds = mod_context.toolbox.extractor
                                        .relative_bounds

            for x = relative_bounds.left_top.x, relative_bounds.right_bottom.x do
                for y = relative_bounds.left_top.y, relative_bounds.right_bottom
                    .y do

                    mod_context.area[entity.position.x + x][entity.position.y +
                        y] = "reserved-for-pump"
                end
            end
            mod_context.area[entity.position.x][entity.position.y] = "oil-well"
        else
            return {"failure.obstructed-resource"}
        end
    end

    for x, reservations in pairs(mod_context.area) do
        for y, reservation in pairs(reservations) do
            if reservation == "undefined" then
                if can_place_pipe(event.surface, {x = x, y = y}) then
                    mod_context.area[x][y] = "can-build"
                else
                    mod_context.area[x][y] = "can-not-build"
                end
            end
        end
    end
end

function pipes_present_in_area(surface, area)
    -- make search area one larger. This will make sure pipes right outside the selection are also found
    -- those might otherwise end up touching with the pipes we will add ourselves.
    local search_area = {
        left_top = {x = area.left_top.x - 1, y = area.left_top.y - 1},
        right_bottom = {
            x = area.right_bottom.x + 1,
            y = area.right_bottom.y + 1
        }
    }

    found_pipes = surface.find_entities_filtered {
        area = search_area,
        name = {"pipe", "pipe-to-ground"}
    }

    found_ghosts_of_pipes = surface.find_entities_filtered {
        area = search_area,
        ghost_name = {"pipe", "pipe-to-ground"}
    }

    if #found_pipes > 0 or #found_ghosts_of_pipes > 0 then
        return {"failure.other-pipes-nearby"}
    end
end

function can_place_extractor(surface, position, direction, toolbox)
    return surface.can_place_entity({
        name = toolbox.extractor.entity_name,
        position = position,
        direction = direction,
        force = "player",
        build_check_type = defines.build_check_type.ghost_place
    })
end

function can_place_pipe(surface, position)
    return surface.can_place_entity({
        name = "pipe",
        position = position,
        direction = defines.direction.north,
        force = "player",
        build_check_type = defines.build_check_type.ghost_place
    })
end
