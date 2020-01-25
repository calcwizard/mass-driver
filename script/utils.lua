
-- compares two string version numbers, like those given by on_configuration_changed
-- returns <0 if oldVersion is older and >0 if newVersion is older, 0 if they're equal
function version_compare(oldVersion, newVersion)
    local old, new = {major,minor,patch}, {major,minor,patch}
    _,_,old.major,old.minor,old.patch = string.find(oldVersion,"(%d+)%.(%d+)%.(%d+)")
    _,_,new.major,new.minor,new.patch = string.find(newVersion,"(%d+)%.(%d+)%.(%d+)")
    if new.major ~= old.major then
        return old.major - new.major
    elseif new.minor ~= old.minor then
        return old.minor - new.minor
    elseif new.patch ~= old.patch then
        return old.patch - new.patch
    else
        return 0
    end
end

-- returns true if the given version is older than the version to compare it to.
-- if the version is nil, it returns false
function is_version_older_than(oldVersion, compareVersion)
    if oldVersion and compareVersion then
        return version_compare(oldVersion, compareVersion) < 0
    else
        return false
    end
end

-- Copies the given prototype and returns one with the new name, setting its mining/place result appropriately
-- @param type The type of the prototype to copy
-- @param name The name of the prototype to copy
-- @param newName The name the copy will have
-- @return The copied entity
function copy_prototype(type, name, newName)
    if not data.raw[type][name] then error("type " .. type .. " " .. name .. " does not exist") end
    local prototype = util.table.deepcopy(data.raw[type][name])
    prototype.name = newName
    if prototype.minable and prototype.minable.result then
        prototype.minable.result = newName
    end
    if prototype.place_result then
        prototype.place_result = newName
    end
    if prototype.result then
        prototype.result = newName
    end
    if prototype.results then
        prototype.results = {{name=newName, amount=1}}
    end
    return prototype
end

-- Returns a read-only table.  Gives an error when attempting to change the values of the table
-- @param t the table to be made read-only
-- @reaturn a read-only copy of the source table
function read_only (t)
    local proxy = {}
    local mt = {       
        __index = t,
        __newindex = function (t,k,v)
            error("attempt to update a read-only table", 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy
end


-- returns the distance between two positions.  Positions are either an array with {x,y} or an indexed table
function distance_between(pos1, pos2)
    local p1 = {
        x = pos1.x or pos1[1],
        y = pos1.y or pos1[2]
    }
    local p2 = {
        x = pos2.x or pos2[1],
        y = pos2.y or pos2[2]
    }
    return ((p1.x-p2.x)^2 + (p1.y-p2.y)^2)^0.5
end

-- Calculates the velocity needed to travel the distance given and the kinetic energy to reach that speed
-- @param distance the distance to launch a projectile
-- @param gravity the local gravity.  Defaults to 9.81 if not provided
-- @return [1] the energy needed, in joules
-- @return [2] the velocity the projectile needs to travel that far
function calculate_energy_cost(distance, gravity)
  local velocity = (distance*(gravity or 9.81))^0.5
  local energy = (global.settings.mass*velocity^2)/2
  return energy, velocity
end