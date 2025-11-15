AddCSLuaFile()

local pulse_sql = {}
pulse_sql.__index = pulse_sql

function pulse_sql:create(name, schema)
    local tbl = setmetatable({}, self)
    tbl.name = name

    if schema then
        local columns = {}
        for k, v in pairs(schema) do
            if k ~= "constraints" then
                table.insert(columns, k .. " " .. v)
            end
        end

        if schema.constraints then
            for _, v in pairs(schema.constraints) do
                table.insert(columns, v)
            end
        end

        local query = "CREATE TABLE IF NOT EXISTS " .. name .. " (" .. table.concat(columns, ", ") .. ")"
        local ok = sql.Query(query)
        if ok == false then error("psql | " .. sql.LastError()) end
    end

    return tbl
end

function pulse_sql:insert(data)
    local columns, values = {}, {}
    for k, v in pairs(data) do
        table.insert(columns, k)
        table.insert(values, sql.SQLStr(v))
    end
    local query = string.format("INSERT INTO %s (%s) VALUES (%s)", self.name, table.concat(columns, ","), table.concat(values, ","))
    return sql.Query(query)
end

function pulse_sql:select(where)
    local conditions = {}
    for k, v in pairs(where or {}) do
        table.insert(conditions, k .. " = " .. sql.SQLStr(v))
    end
    local query = "SELECT * FROM " .. self.name
    if #conditions > 0 then
        query = query .. " WHERE " .. table.concat(conditions, " AND ")
    end
    return sql.Query(query) or {}
end

function pulse_sql:update(data, where)
    if not where then error("psql | cannot update without conditions!") end

    local set, conditions = {}, {}
    for k, v in pairs(data) do
        table.insert(set, k .. " = " .. sql.SQLStr(v))
    end
    for k, v in pairs(where) do
        table.insert(conditions, k .. " = " .. sql.SQLStr(v))
    end
    local query = string.format("UPDATE %s SET %s WHERE %s", self.name, table.concat(set, ","), table.concat(conditions, " AND "))
    return sql.Query(query)
end

function pulse_sql:delete(where)
    if not where then error("psql | cannot delete without conditions!") end

    local conditions = {}
    for k, v in pairs(where) do
        table.insert(conditions, k .. " = " .. sql.SQLStr(v))
    end
    local query = string.format("DELETE FROM %s WHERE %s", self.name, table.concat(conditions, " AND "))
    return sql.Query(query)
end

_G.psql = function(name, schema)
    return pulse_sql:create(name, schema)
end