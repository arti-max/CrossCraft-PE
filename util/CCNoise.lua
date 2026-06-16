-- util/CCNoise.lua

_G.CCNoise = {};
dbg.info("Register noise");


local function hash(ix, iy, seed)
    local h = seed + ix * 374761393 + iy * 668265263;
    h = (h * 1274126177) % 4294967296;
    h = (h * 668265263 + 1274126177) % 4294967296;
    return (h % 2147483647) / 2147483647;
end

local function smoothstep(t)
    return t * t * t * (t * (t * 6 - 15) + 10);
end

local function smoothstep2(t)
    return t * t * (3 - 2 * t);
end

_G.CCNoise.valueNoise = function(x, y, seed)
    local ix = math.floor(x);
    local iy = math.floor(y);
    local fx = x - ix;
    local fy = y - iy;

    local sx = smoothstep(fx);
    local sy = smoothstep(fy);

    local v00 = hash(ix, iy, seed);
    local v10 = hash(ix+1, iy, seed);
    local v01 = hash(ix, iy+1, seed);
    local v11 = hash(ix+1, iy+1, seed);

    local nx0 = v00 + (v10 - v00) * sx;
    local nx1 = v01 + (v11 - v01) * sx;
    return nx0 + (nx1 - nx0) * sy;
end

_G.CCNoise.fbm = function (x, y, seed, octaves, lacunarity, persistence)
    local value = 0;
    local amp = 1;
    local freq = 1;
    local mValue = 0;

    for i = 1, octaves do
        value = value + CCNoise.valueNoise(x * freq, y * freq, seed + i * 631) * amp;
        mValue = mValue + amp;
        amp = amp * persistence;
        freq = freq * lacunarity;
    end

    return value / mValue;
end