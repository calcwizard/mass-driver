
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