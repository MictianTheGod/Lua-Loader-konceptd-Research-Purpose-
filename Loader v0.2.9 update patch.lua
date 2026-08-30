--[[
    Forward Loader v0.2.9 test Loader-Only / NextGen
    Aimware v5.1.13 compliant — NO cheat functions, loader-only

    Patches v0.2.9 test (build bump v0.2.8 -> v0.2.9 test):
    - [FIX] Duplicate "Loader Injected" already fixed, kept single stage
    - [FIX] Subtitle "loader • secure • verified" already removed
    - [CHG] SYSTEM STATUS custom design: 3 natural pills ONLINE/OFFLINE,
            SECURE tri-state (INSECURE red / SECURE orange / SECURE green) and
            TO DATE/OUTDATE, no duplicate labels, centered with status colors
    - [CHG] LOADER STATUS custom card: left accent bar + centered READY/LOADING/
            LOADED with pulse dot + message, distinct from SYSTEM STATUS
    - [REM] Status Loaded remake: premium LOADED card with panel_active bg,
            green border, glow checkmark, centered VERIFIED badge, no duplicity
    - [CHG] Loader Options locked after LOAD: Secure Boot/Cloud Sync/Debug
            disabled (LOCK) when state != READY, settings page also locked
    - [BUMP] v0.2.8 -> v0.2.9 test version bump, window 375x590

    Layout 375x590, state READY -> LOADING -> LOADED, loader-only.
]]

------------------------------------------------------------
-- MENU VISIBILITY
------------------------------------------------------------
local menu_open = gui.Reference("MENU")

------------------------------------------------------------
-- LOCALS
------------------------------------------------------------
local l_floor = math.floor
local l_min   = math.min
local l_max   = math.max
local l_exp   = math.exp
local l_sin   = math.sin
local l_cos   = math.cos

local g_RealTime          = globals.RealTime
local g_AbsoluteFrameTime = globals.AbsoluteFrameTime

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local CONFIG = {
    width  = 375,
    height = 590,
    header_height = 32,
    radius = 6,

    version       = "0.2.9 test",
    build_date    = "Aug 29 2026",
    build_type    = "x64",
    registered_to = "Mictian",

    min_boot_time    = 4.50,
    random_variation = 0.18,
    smooth_progress = 8.0,
    smooth_hover    = 14.0,

    -- SYSTEM STATUS: 3 natural pills, no duplicity
    features = {
        { label = "ONLINE",   active = true  }, -- 1 ONLINE green / OFFLINE red
        { label = "SECURE",   active = true  }, -- 2 SECURE tri-state: INSECURE red / SECURE orange / SECURE green
        { label = "TO DATE",  active = true  }, -- 3 TO DATE green / OUTDATE orange
    },

    controls = {
        { id = "secure", label = "Secure Boot",  state = true  },
        { id = "cloud",  label = "Cloud Sync",   state = true  },
        { id = "debug",  label = "Debug",        state = false },
        { id = "autoinj",label = "Auto Inject",  state = false },
        { id = "notify", label = "Notifications",state = true  },
    },

    colors = {
        background    = {14, 14, 14, 255},
        header        = {18, 18, 18, 255},
        panel         = {22, 22, 22, 255},
        panel_light   = {28, 28, 28, 255},
        border        = {38, 38, 38, 255},
        border_light  = {52, 52, 52, 255},
        hairline      = { 1,  1,  1,  10},
        text          = {242, 242, 242, 255},
        text_dim      = {190, 190, 190, 255},
        muted         = {145, 145, 145, 255},
        muted_dark    = {110, 110, 110, 255},
        accent        = {118, 210,   0, 255},
        accent_dim    = { 80, 145,   0, 255},
        accent_glow   = {118, 210,   0,  28},
        accent_soft   = {118, 210,   0,  14},
        button        = {30, 30, 30, 255},
        button_hover  = {46, 46, 46, 255},
        button_pressed= {36, 36, 36, 255},
        progress_bg   = {39, 39, 39, 255},
        logger_bg     = {12, 12, 12, 255},
        shadow        = { 0,  0,  0,  80},
        shine         = {255,255,255,  38},
        troll         = {155, 155, 155, 255},
        troll_dim     = {120, 120, 120, 255},
    }
}

------------------------------------------------------------
-- BANTER POOL
------------------------------------------------------------
local BANTER_POOL = {
    "[DATA] Measuring reaction... 420ms (slow)",
    "[DATA] Checking aim... no hits found",
    "[DATA] Analyzing moves... hit walls [OK]",
    "[DATA] Game sense... not detected",
    "[DATA] Scanning excuses... 12 found",
    "[DATA] Reflex test... timeout 3s",
    "[DATA] Fetching carry... none online",
    "[DATA] Clutch chance... 0.0% measured",
    "[DATA] Trust factor... low (reported)",
    "[DATA] Optimizing whiffs... maxed",
    "[DATA] Estimating IQ... 2 digits",
    "[DATA] Loading confidence... ego heavy",
    "[DATA] Syncing skill issue... confirmed",
    "[DATA] Next death... queued [OK]",
}

------------------------------------------------------------
-- WINDOW STATE
------------------------------------------------------------
local ui = {
    x = 320, y = 200,
    w = CONFIG.width, h = CONFIG.height,
    dragging = false, drag_x = 0, drag_y = 0,
    load_hover = false, load_pressed = false,
    hover_anim = 0, progress_visual = 0,
    shimmer = 0, pulse = 0,
    ctrl_hover = -1,
    banter_idx = 1,
    banter_text = BANTER_POOL[1],
    banter_t = 0,
    last_save_t = 0,
    view = "main", -- main or settings
    gear_hover = false,
    settings_hover = -1,
}

------------------------------------------------------------
-- LAYOUT - each item owns its space, larger gaps, enlarged text
------------------------------------------------------------
local Layout = {}
local function updateLayout()
    local y0 = ui.y
    Layout.pad_x = 25
    Layout.content_w = CONFIG.width - Layout.pad_x*2
    Layout.header_end = y0 + CONFIG.header_height
    Layout.title_y = Layout.header_end + 20
    -- subtitle removed per v0.2.7 request
    Layout.info_y = Layout.title_y + 32
    Layout.info_h = 4*18
    Layout.info_end = Layout.info_y + Layout.info_h
    Layout.divider_y = Layout.info_end + 14
    Layout.status_tag_y = Layout.divider_y + 14
    Layout.status_bar_y = Layout.status_tag_y + 16
    Layout.status_bar_h = 30
    Layout.status_bar_end = Layout.status_bar_y + Layout.status_bar_h
    Layout.options_tag_y = Layout.status_bar_end + 14
    Layout.options_y = Layout.options_tag_y + 16
    Layout.options_h = 18
    Layout.options_end = Layout.options_y + Layout.options_h + 16
    Layout.button_y = Layout.options_end + 16
    Layout.button_h = 36
    Layout.button_end = Layout.button_y + Layout.button_h
    Layout.progress_y = Layout.button_end + 24 -- extra gap to avoid Loader Injected overlap
    Layout.progress_h = 7
    Layout.stage_y = Layout.progress_y - 14
    Layout.percent_y = Layout.progress_y + Layout.progress_h + 12
    Layout.dataloading_y = Layout.percent_y + 22
    Layout.dataloading_h = 105
    Layout.dataloading_end = Layout.dataloading_y + Layout.dataloading_h
    Layout.banter_y = Layout.dataloading_end + 10
    Layout.banter_h = 18
    Layout.banter_end = Layout.banter_y + Layout.banter_h
    Layout.status2_y = Layout.banter_end + 16
    Layout.status_h = 26
    Layout.window_end = Layout.status2_y + Layout.status_h
    -- settings view layout
    Layout.settings_title_y = Layout.header_end + 22
    Layout.settings_row_h = 28
    Layout.settings_start_y = Layout.settings_title_y + 36
    local needed = Layout.window_end - y0 + 10
    if needed > CONFIG.height then CONFIG.height = needed ui.h = needed end
    if needed < CONFIG.height then ui.h = CONFIG.height end
end

------------------------------------------------------------
-- LOADER STATE
------------------------------------------------------------
local Loader = {
    state = "READY",
    start_time = 0, state_time = 0,
    progress = 0, phase_progress = 0,
    phase_index = 0,
    phase_start_progress = 0, phase_target_progress = 0,
    phase_duration = 0,
    handoff_started = false,
    logger = {},
}

------------------------------------------------------------
-- FRAME TIMING
------------------------------------------------------------
local Timing = { last = g_RealTime(), dt = 0, time = 0 }

local function update_dt()
    local now = g_RealTime()
    local dt  = g_AbsoluteFrameTime()
    if dt == nil or dt <= 0 or dt > 0.1 then
        dt = now - Timing.last
        if dt < 0 then dt = 0 end
        if dt > 0.05 then dt = 0.05 end
    end
    if dt < 0 then dt = 0 end
    if dt > 0.05 then dt = 0.05 end
    Timing.dt = dt; Timing.last = now; Timing.time = now
end

local function exp_smooth(current, target, speed)
    local dt = Timing.dt
    if dt <= 0 then return current end
    local f = 1 - l_exp(-speed * dt)
    if f > 1 then f = 1 end
    if f < 0 then f = 0 end
    return current + (target - current) * f
end

------------------------------------------------------------
-- FONTS - enlarged +1-2px
------------------------------------------------------------
local Fonts = { title=nil, body=nil, info=nil, mono=nil, small=nil, icon=nil, gear=nil }

local function safe_create_font(name, size, weight)
    local ok, f = pcall(draw.CreateFont, name, size, weight)
    if ok and f ~= nil then return f end
    ok, f = pcall(draw.CreateFont, "Verdana", size, weight)
    if ok and f ~= nil then return f end
    return nil
end

local function init_fonts()
    -- enlarged +1px v0.2.7: title 22, body 16, info 14, mono 11, small 11, icon 11
    Fonts.title = safe_create_font("Bahnschrift", 22, 700) or safe_create_font("Verdana", 17, 700)
    Fonts.body  = safe_create_font("Bahnschrift", 16, 700) or safe_create_font("Verdana", 14, 700)
    Fonts.info  = safe_create_font("Bahnschrift", 14, 600) or safe_create_font("Verdana", 13, 600)
    Fonts.mono  = safe_create_font("Consolas", 11, 550) or safe_create_font("Lucida Console", 11, 550)
    Fonts.small = safe_create_font("Verdana", 11, 600)
    Fonts.icon  = safe_create_font("Verdana", 11, 700)
    Fonts.gear  = safe_create_font("Verdana", 14, 700)
end

------------------------------------------------------------
-- UTILS
------------------------------------------------------------
local function clamp(v,mn,mx) if v<mn then return mn end if v>mx then return mx end return v end
local function lerp(a,b,t) return a + (b-a)*t end
local function ease_in_out(t) t=clamp(t,0,1) if t<0.5 then return 2*t*t end return 1-(((-2*t+2)^2)/2) end
local function in_bounds(mx,my,x,y,w,h) return mx>=x and mx<=x+w and my>=y and my<=y+h end

------------------------------------------------------------
-- DRAW HELPERS
------------------------------------------------------------
local function set_color(c,a)
    if c == nil then
        c = CONFIG.colors.text or {255,255,255,255}
    end
    draw.Color(c[1] or 255, c[2] or 255, c[3] or 255, a or c[4] or 255)
end
local function fill_rect(x1,y1,x2,y2,color,alpha) set_color(color,alpha) draw.FilledRect(x1,y1,x2,y2) end
local function rounded_fill(x1,y1,x2,y2,r,color,alpha) set_color(color,alpha) draw.RoundedRectFill(x1,y1,x2,y2,r,1,1,1,1) end
local function rounded_outline(x1,y1,x2,y2,r,color,alpha) set_color(color,alpha) draw.RoundedRect(x1,y1,x2,y2,r,1,1,1,1) end

local function draw_text_centered(font,cx,y,text,color)
    draw.SetFont(font) local tw,th=draw.GetTextSize(text) set_color(color) draw.Text(l_floor(cx - tw*0.5), l_floor(y), text) return tw,th
end
local function draw_text_centered_box(font,x,y,w,h,text,color)
    draw.SetFont(font) local tw,th=draw.GetTextSize(text) set_color(color) draw.Text(l_floor(x + (w-tw)*0.5), l_floor(y + (h-th)*0.5), text)
end
local function draw_text_vcentered(font,x,y,h,text,color)
    draw.SetFont(font) local tw,th=draw.GetTextSize(text) set_color(color) draw.Text(l_floor(x), l_floor(y + (h-th)*0.5), text)
end
local function draw_centered_kv(font,cx,y,key,keyColor,val,valColor,gap)
    gap = gap or 6
    draw.SetFont(font) local kw,kh = draw.GetTextSize(key)
    draw.SetFont(font) local vw,vh = draw.GetTextSize(val)
    local total = kw + gap + vw
    local x0 = l_floor(cx - total*0.5)
    draw.SetFont(font) set_color(keyColor) draw.Text(x0, y, key)
    draw.SetFont(font) set_color(valColor) draw.Text(x0 + kw + gap, y, val)
end
local function truncate_text(font, text, max_w)
    draw.SetFont(font) local tw,th=draw.GetTextSize(text)
    if tw <= max_w then return text end
    local ellipsis="..." draw.SetFont(font) local ew,_=draw.GetTextSize(ellipsis)
    max_w = max_w - ew
    local len=#text
    while len>0 do
        local sub=text:sub(1,len) draw.SetFont(font) local sw,_=draw.GetTextSize(sub)
        if sw <= max_w then return sub..ellipsis end
        len=len-1
    end
    return ellipsis
end

------------------------------------------------------------
-- FILE API - valid lowercase .txt, closure pcall
------------------------------------------------------------
local SETTINGS_FILE = "forwardtrack_loader.txt"
local function save_loader_settings()
    if Timing.time - (ui.last_save_t or 0) < 0.30 then return end
    ui.last_save_t = Timing.time
    local d = string.format("secure=%d\ncloud=%d\ndebug=%d\nautoinj=%d\nnotify=%d\n",
        CONFIG.controls[1].state and 1 or 0,
        CONFIG.controls[2].state and 1 or 0,
        CONFIG.controls[3].state and 1 or 0,
        CONFIG.controls[4].state and 1 or 0,
        CONFIG.controls[5].state and 1 or 0)
    local ok, err = pcall(function() file.Write(SETTINGS_FILE, d) end)
    if not ok then
        if not ui.save_error_printed then
            print("[Loader] save failed: "..tostring(err).." (using "..SETTINGS_FILE..")")
            ui.save_error_printed = true
        end
    else
        ui.save_error_printed = false
    end
end
local function load_loader_settings()
    local exists=false
    local okEnum = pcall(function() file.Enumerate(function(n) if n==SETTINGS_FILE then exists=true end end) end)
    if not okEnum or not exists then return end
    local ok, content = pcall(function() return file.Read(SETTINGS_FILE) end)
    if not ok or not content then
        if not ok then print("[Loader] load failed: "..tostring(content)) end
        return
    end
    for line in content:gmatch("[^\r\n]+") do
        local k,v=line:match("(%w+)=(%d+)")
        if k=="secure" then CONFIG.controls[1].state = (v=="1")
        elseif k=="cloud" then CONFIG.controls[2].state = (v=="1")
        elseif k=="debug" then CONFIG.controls[3].state = (v=="1")
        elseif k=="autoinj" then CONFIG.controls[4].state = (v=="1")
        elseif k=="notify" then CONFIG.controls[5].state = (v=="1") end
    end
    CONFIG.features[2].active = CONFIG.controls[2].state
    CONFIG.features[1].active = CONFIG.controls[1].state
end

------------------------------------------------------------
-- LOGGER
------------------------------------------------------------
local function logger_add(msg, level)
    level = level or "INFO"
    Loader.logger[#Loader.logger+1] = { message=msg, level=level, time=Timing.time }
    if #Loader.logger>7 then table.remove(Loader.logger,1) end
end
local function get_logger_color(level)
    if level=="OK" then return CONFIG.colors.accent end
    if level=="WARN" then return {220,175,70,255} end
    if level=="ERROR" then return {220,80,80,255} end
    if level=="TROLL" then return CONFIG.colors.troll end
    return CONFIG.colors.muted
end

------------------------------------------------------------
-- LOADING PHASES
------------------------------------------------------------
local phases = {
    { name = "Authenticating license...",   target=0.12, duration=0.58 },
    { name = "Fetching cloud manifest...",  target=0.27, duration=0.64 },
    { name = "Decrypting payload...",       target=0.45, duration=0.52 },
    { name = "Verifying signature...",      target=0.67, duration=0.77 },
    { name = "Syncing user data...",        target=0.83, duration=0.68 },
    { name = "Preparing injection...",      target=0.95, duration=0.71 },
    { name = "Finalizing...",               target=1.00, duration=0.65 },
}
local function randomized_duration(base)
    local variation = base * CONFIG.random_variation
    return base + (math.random()*2 -1)*variation
end

------------------------------------------------------------
-- START LOADING
------------------------------------------------------------
local function start_loading()
    if Loader.state~="READY" then return end
    Loader.state="LOADING"
    Loader.start_time=Timing.time; Loader.state_time=Timing.time
    Loader.progress=0; Loader.phase_index=1; Loader.phase_progress=0
    Loader.phase_start_progress=0; Loader.phase_target_progress=phases[1].target
    Loader.phase_duration=randomized_duration(phases[1].duration)
    Loader.handoff_started=false; Loader.logger={}; ui.progress_visual=0
    ui.banter_idx = math.random(1, #BANTER_POOL)
    ui.banter_text = BANTER_POOL[ui.banter_idx]
    ui.banter_t = Timing.time
    logger_add("Starting ForwardTrack Loader...", "INFO")
    logger_add(phases[1].name, "INFO")
    if not CONFIG.controls[1].state then
        logger_add("Secure Boot OFF — skip verify [WARN]", "WARN")
    end
    if CONFIG.controls[2].state then
        local ok = pcall(function()
            http.Get("https://example.com/", function(body)
                if body == nil then
                    logger_add("Cloud: offline (no net) [WARN]", "WARN")
                else
                    logger_add("Cloud manifest OK [OK]", "OK")
                    CONFIG.features[2].active = true
                end
            end)
        end)
        if not ok then logger_add("Cloud: http error [WARN]", "WARN") end
    else
        logger_add("Cloud sync disabled [INFO]", "INFO")
        CONFIG.features[2].active = false
    end
end

------------------------------------------------------------
-- UPDATE LOADING
------------------------------------------------------------
local function update_loading()
    if Loader.state~="LOADING" then return end
    local now=Timing.time
    local elapsed=now - Loader.state_time
    local phase=phases[Loader.phase_index]
    if not phase then
        Loader.progress=1; Loader.state="LOADED"; Loader.state_time=now
        logger_add("Injection ready.", "OK")
        logger_add(BANTER_POOL[math.random(1,#BANTER_POOL)], "TROLL")
        save_loader_settings()
        return
    end
    local phase_t=clamp(elapsed/Loader.phase_duration,0,1)
    local eased=ease_in_out(phase_t)
    Loader.progress=lerp(Loader.phase_start_progress, Loader.phase_target_progress, eased)
    if phase_t>=1 then
        Loader.progress=Loader.phase_target_progress
        logger_add(phase.name.." done.", "OK")
        local chance = CONFIG.controls[3].state and 0.55 or 0.34
        if math.random() < chance then
            logger_add(BANTER_POOL[math.random(1,#BANTER_POOL)], "TROLL")
        end
        Loader.phase_index=Loader.phase_index+1
        if phases[Loader.phase_index] then
            local nxt=phases[Loader.phase_index]
            if nxt.name:find("Verifying") and not CONFIG.controls[1].state then
                nxt = { name="Verify skipped (insecure)", target=nxt.target, duration=0.20 }
                phases[Loader.phase_index]=nxt
            end
            Loader.phase_start_progress=Loader.progress
            Loader.phase_target_progress=nxt.target
            Loader.phase_duration=randomized_duration(nxt.duration)
            Loader.state_time=now
            logger_add(nxt.name, "INFO")
        else
            Loader.progress=1; Loader.state="LOADED"; Loader.state_time=now
            logger_add("All loader tasks complete.", "OK")
            save_loader_settings()
        end
    end
    local total_elapsed=now - Loader.start_time
    if Loader.state=="LOADED" and total_elapsed < CONFIG.min_boot_time then
        Loader.state="LOADING"; Loader.phase_index=#phases
        Loader.progress=clamp(Loader.progress,0.96,0.985)
        Loader.phase_start_progress=Loader.progress; Loader.phase_target_progress=1.0
        local remain=CONFIG.min_boot_time - total_elapsed
        Loader.phase_duration=l_max(remain,0.12)
        Loader.state_time=now - (Loader.phase_duration*0.15)
    end
end

------------------------------------------------------------
-- HOVER / BUTTON + GEAR
------------------------------------------------------------
local function update_button(mx, my)
    -- gear wheel next to X
    local hdr_x = ui.x
    local hdr_y = ui.y
    local hdr_w = ui.w
    local close_w = 28
    local gear_w = 28
    local close_x = hdr_x + hdr_w - close_w
    local gear_x = close_x - gear_w - 2
    ui.gear_hover = in_bounds(mx,my, gear_x, hdr_y, gear_w, CONFIG.header_height)
    if ui.gear_hover and input.IsButtonPressed(1) then
        ui.view = (ui.view == "main") and "settings" or "main"
    end
    -- close X still just hover (could hide loader if needed)

    if ui.view == "settings" then
        -- settings page toggles - disabled after load (inject)
        if Loader.state ~= "READY" then
            ui.settings_hover = -1
            ui.load_hover = false
            ui.ctrl_hover = -1
            return
        end
        local total_rows = #CONFIG.controls
        local row_w = 260
        local row_h = Layout.settings_row_h
        local start_y = Layout.settings_start_y
        local cx = l_floor(ui.x + (ui.w - row_w)*0.5)
        ui.settings_hover = -1
        for i, ctrl in ipairs(CONFIG.controls) do
            local ry = start_y + (i-1)*(row_h+8)
            local tx = cx
            -- hitbox is right toggle area
            local toggle_x = cx + row_w - 52
            if in_bounds(mx,my, toggle_x, ry+4, 52, 20) then
                ui.settings_hover = i
                if input.IsButtonPressed(1) then
                    ctrl.state = not ctrl.state
                    save_loader_settings()
                    logger_add(ctrl.label.." "..(ctrl.state and "ON" or "OFF"), "INFO")
                    if ctrl.id=="cloud" then CONFIG.features[3].active = ctrl.state
                    elseif ctrl.id=="secure" then CONFIG.features[2].active = ctrl.state end
                end
            elseif in_bounds(mx,my, cx, ry, row_w, row_h) and input.IsButtonPressed(1) then
                -- clicking row also toggles
                ctrl.state = not ctrl.state
                save_loader_settings()
                logger_add(ctrl.label.." "..(ctrl.state and "ON" or "OFF"), "INFO")
            end
        end
        -- back via gear already handled
        ui.load_hover = false
        ui.ctrl_hover = -1
        return
    end

    local bx = ui.x + Layout.pad_x
    local by = Layout.button_y
    local bw = Layout.content_w
    local bh = Layout.button_h

    ui.load_hover = in_bounds(mx,my,bx,by,bw,bh)
    local was_pressed=false
    if Loader.state=="READY" and ui.load_hover and input.IsButtonPressed(1) then
        was_pressed=true; start_loading()
    end
    ui.load_pressed = was_pressed and ui.load_hover

    -- loader controls toggles (main page 3) - disabled after load
    ui.ctrl_hover = -1
    if Loader.state == "READY" then
        local ctrl_w = 90
        local ctrl_h = Layout.options_h
        local ctrl_gap = 10
        local show_n = 3
        local total_w = show_n * ctrl_w + (show_n-1)*ctrl_gap
        local ctrl_x0 = l_floor(ui.x + (ui.w - total_w)*0.5)
        local ctrl_y = Layout.options_y
        for i=1, show_n do
            local ctrl = CONFIG.controls[i]
            local cx = ctrl_x0 + (i-1)*(ctrl_w+ctrl_gap)
            if in_bounds(mx,my,cx,ctrl_y,ctrl_w,ctrl_h) then
                ui.ctrl_hover = i
                if input.IsButtonPressed(1) then
                    ctrl.state = not ctrl.state
                    save_loader_settings()
                    logger_add(ctrl.label.." "..(ctrl.state and "ON" or "OFF"), "INFO")
                    if ctrl.id=="cloud" then CONFIG.features[3].active = ctrl.state end
                    if ctrl.id=="secure" then CONFIG.features[2].active = ctrl.state end
                end
            end
        end
    end
    -- System Status pills are display-only (controlled via Secure Boot / Cloud Sync)
    -- removed direct pill click toggling to avoid state desync

    local hover_target=(ui.load_hover and Loader.state=="READY") and 1 or 0
    if ui.load_pressed then hover_target=0.6 end
    ui.hover_anim = exp_smooth(ui.hover_anim, hover_target, CONFIG.smooth_hover)
    ui.progress_visual = exp_smooth(ui.progress_visual, Loader.progress, CONFIG.smooth_progress)
    ui.shimmer = (Timing.time*0.55)%1
    ui.pulse = 0.5 + 0.5*l_sin(Timing.time*3.2)

    if Loader.state=="LOADING" or Loader.state=="LOADED" then
        if Timing.time - ui.banter_t > 1.9 then
            ui.banter_idx = ui.banter_idx % #BANTER_POOL + 1
            if math.random()<0.25 then ui.banter_idx = math.random(1,#BANTER_POOL) end
            ui.banter_text = BANTER_POOL[ui.banter_idx]
            ui.banter_t = Timing.time
        end
    else
        ui.banter_text = BANTER_POOL[1]
    end
end

------------------------------------------------------------
-- DRAG
------------------------------------------------------------
local function update_drag(mx,my)
    local mouse_down=input.IsButtonDown(1)
    local header_hit=in_bounds(mx,my,ui.x,ui.y,ui.w,CONFIG.header_height)
    if mouse_down and header_hit and not ui.dragging then ui.dragging=true; ui.drag_x=mx-ui.x; ui.drag_y=my-ui.y end
    if not mouse_down then ui.dragging=false end
    if ui.dragging then ui.x=mx-ui.drag_x; ui.y=my-ui.drag_y end
end

------------------------------------------------------------
-- DRAW HEADER + GEAR
------------------------------------------------------------
local function draw_header()
    local x,y=ui.x,ui.y; local w,h=ui.w,CONFIG.header_height; local r=CONFIG.radius
    fill_rect(x+2,y+2,x+w+2,y+CONFIG.height+2,CONFIG.colors.shadow,40)
    rounded_fill(x,y,x+w,y+h,r,CONFIG.colors.header)
    fill_rect(x,y+h-r,x+w,y+h,CONFIG.colors.header)
    fill_rect(x,y+h-1,x+w,y+h,CONFIG.colors.border)
    fill_rect(x+1,y,x+w-1,y+1,CONFIG.colors.hairline,255)
    local logo_x=x+10; local logo_y=y+7; local logo_sz=18
    rounded_fill(logo_x,logo_y,logo_x+logo_sz,logo_y+logo_sz,3,CONFIG.colors.accent)
    draw_text_centered_box(Fonts.icon, logo_x,logo_y,logo_sz,logo_sz,"F",{18,18,18,255})
    draw_text_vcentered(Fonts.body, logo_x+logo_sz+8, y,h,"ForwardTrack",CONFIG.colors.text)
    draw.SetFont(Fonts.body) local tw,_=draw.GetTextSize("ForwardTrack")
    draw_text_vcentered(Fonts.info, logo_x+logo_sz+8+tw+6, y,h,"loader",CONFIG.colors.muted)
    local welcome="Welcome Bacak <3"
    draw.SetFont(Fonts.info) local wx,wy=draw.GetTextSize(welcome)
    local close_w=28; local close_x=x+w-close_w
    local gear_w=28; local gear_x=close_x - gear_w - 2
    -- welcome left of gear
    draw_text_vcentered(Fonts.info, gear_x-wx-10, y,h,welcome,CONFIG.colors.muted)
    -- gear wheel button
    local gear_hover = ui.gear_hover
    if gear_hover then fill_rect(gear_x,y, gear_x+gear_w, y+h-1, CONFIG.colors.panel_light, 255) end
    -- gear icon: filled circle + 4 ticks (aimware safe)
    local gx = gear_x + gear_w*0.5
    local gy = y + h*0.5
    local gear_col = gear_hover and CONFIG.colors.accent or CONFIG.colors.muted
    if ui.view=="settings" then gear_col = CONFIG.colors.accent end
    set_color(gear_col) draw.FilledCircle(gx,gy,6)
    set_color({18,18,18,255}) draw.FilledCircle(gx,gy,3)
    -- ticks
    set_color(gear_col)
    for a=0,3 do
        local ang = a*90 *3.14159/180
        local x1 = gx + l_cos(ang)*7
        local y1 = gy + l_sin(ang)*7
        local x2 = gx + l_cos(ang)*9
        local y2 = gy + l_sin(ang)*9
        draw.Line(x1,y1,x2,y2)
    end
    -- small dot if in settings
    if ui.view=="settings" then
        set_color(CONFIG.colors.accent,90) draw.FilledCircle(gx,gy,9)
    end
    -- close X
    local cx=close_x; local cy=y; local hx,hy=input.GetMousePos(); local hover_close=in_bounds(hx,hy,cx,cy,close_w,h)
    if hover_close then fill_rect(cx,cy,cx+close_w,cy+h-1,CONFIG.colors.button_hover,255) end
    draw_text_centered_box(Fonts.body, cx,cy,close_w,h,"x", hover_close and CONFIG.colors.text or CONFIG.colors.muted)
    rounded_fill(x,y+h,x+w,y+CONFIG.height,r,CONFIG.colors.background)
    fill_rect(x,y+h,x+w,y+h+r,CONFIG.colors.background)
    rounded_outline(x,y,x+w,y+CONFIG.height,r,CONFIG.colors.border)
end

------------------------------------------------------------
-- DRAW INFORMATION (subtitle removed)
------------------------------------------------------------
local function draw_information()
    local cx = ui.x + ui.w * 0.5
    local title_y = Layout.title_y
    local info_y = Layout.info_y
    draw_text_centered(Fonts.title, cx, title_y, "ForwardTrack.fck", CONFIG.colors.text)
    draw.SetFont(Fonts.title) local tw,th=draw.GetTextSize("ForwardTrack.fck")
    local ul_x0 = l_floor(cx - tw*0.5)
    local ul_x1 = l_floor(cx + tw*0.5)
    fill_rect(ul_x0, title_y+24, ul_x1, title_y+25, CONFIG.colors.accent, 90)
    fill_rect(ul_x0, title_y+25, ul_x1, title_y+26, CONFIG.colors.accent_glow, 255)
    local labels = {
        {"Version:",       CONFIG.version},
        {"Build date:",    CONFIG.build_date},
        {"Build type:",    CONFIG.build_type},
        {"Registered to:", CONFIG.registered_to},
    }
    for i, line in ipairs(labels) do
        local y = info_y + ((i-1)*18)
        draw_centered_kv(Fonts.info, cx, y, line[1], CONFIG.colors.muted, line[2], CONFIG.colors.accent, 6)
    end
    fill_rect(ui.x+Layout.pad_x, Layout.divider_y, ui.x+Layout.pad_x+Layout.content_w, Layout.divider_y+1, CONFIG.colors.border, 255)
end

------------------------------------------------------------
-- SYSTEM STATUS BAR (useful, replaces Loader Pipeline)
------------------------------------------------------------
local function draw_status_bar()
    -- Custom design: 3 natural pills, no duplicate labels, spacious
    local bar_x=ui.x+Layout.pad_x; local bar_y=Layout.status_bar_y; local bar_w=Layout.content_w; local bar_h=Layout.status_bar_h
    rounded_fill(bar_x,bar_y,bar_x+bar_w,bar_y+bar_h,8,CONFIG.colors.panel)
    rounded_outline(bar_x,bar_y,bar_x+bar_w,bar_y+bar_h,8,CONFIG.colors.border)
    fill_rect(bar_x+8,bar_y+1,bar_x+bar_w-8,bar_y+2,CONFIG.colors.hairline,255)

    local col_red    = {220, 60, 60, 255}
    local col_orange = {230,165, 60, 255}
    local col_green  = CONFIG.colors.accent
    local col_gray   = CONFIG.colors.muted_dark

    -- Live states - natural mapping, no duplicity
    local online_active = CONFIG.controls[2].state
    local online_label = online_active and "ONLINE" or "OFFLINE"
    local online_dot = online_active and col_green or col_red

    local secure_on = CONFIG.controls[1].state
    local secure_label, secure_dot, secure_active
    if not secure_on then
        secure_label = "INSECURE"; secure_dot = col_red; secure_active = true
    elseif Loader.state == "LOADED" then
        secure_label = "SECURE"; secure_dot = col_green; secure_active = true
    else
        secure_label = "SECURE"; secure_dot = col_orange; secure_active = true
        -- orange during LOADING/READY when Secure Boot ON but not yet verified
        if Loader.state == "READY" then secure_dot = col_orange end
    end
    -- keep single secure pill, color indicates level (red/orange/green)

    local todate_active = CONFIG.controls[2].state
    local todate_label = todate_active and "TO DATE" or "OUTDATE"
    local todate_dot = todate_active and col_green or col_orange

    local entries = {
        { label=online_label,  dot=online_dot,  active=online_active },
        { label=secure_label,  dot=secure_dot,  active=secure_active },
        { label=todate_label,  dot=todate_dot,  active=true },
    }
    -- sync back to CONFIG.features (first 3)
    for i=1,3 do CONFIG.features[i].label = entries[i].label; CONFIG.features[i].active = entries[i].active end

    local count=3; local gap=10; local pad=8
    local avail=bar_w - pad*2 - gap*(count-1)
    local pill_w=l_floor(avail/count)
    local pill_h = bar_h - 10
    for i=1,count do
        local e = entries[i]
        local px=bar_x+pad+(i-1)*(pill_w+gap); local py=bar_y+5; local pw=pill_w; local ph=pill_h
        local bg = CONFIG.colors.panel_light
        local bd = e.dot
        -- natural: active pill has soft glow, inactive has muted border (but all 3 are always active in new design)
        rounded_fill(px,py,px+pw,py+ph,ph/2,bg)
        rounded_outline(px,py,px+pw,py+ph,ph/2,bd,140)
        -- dot with glow
        local dot_cx=px+10; local dot_cy=py+ph*0.5
        set_color(e.dot,45) draw.FilledCircle(dot_cx,dot_cy,5)
        set_color(e.dot) draw.FilledCircle(dot_cx,dot_cy,3)
        local txt = truncate_text(Fonts.small, e.label, pw-22)
        draw.SetFont(Fonts.small) local tw,th=draw.GetTextSize(txt)
        local tx=l_floor(px+18+(pw-18-tw)*0.5); local ty=l_floor(py+(ph-th)*0.5)
        set_color(CONFIG.colors.text) draw.Text(tx,ty,txt)
    end
    draw_text_centered(Fonts.small, bar_x+bar_w*0.5, Layout.status_tag_y, "—  SYSTEM STATUS  —", CONFIG.colors.muted_dark)
end

------------------------------------------------------------
-- LOADER OPTIONS (main page shows 3)
------------------------------------------------------------
local function draw_loader_options()
    local ctrl_w = 90
    local ctrl_h = Layout.options_h
    local gap = 10
    local show_n = 3
    local total_w = show_n * ctrl_w + (show_n-1)*gap
    local x0 = l_floor(ui.x + (ui.w - total_w)*0.5)
    local ctrl_y = Layout.options_y
    local locked = Loader.state ~= "READY"
    local header_col = locked and CONFIG.colors.muted_dark or CONFIG.colors.muted_dark
    local header_txt = locked and "LOADER OPTIONS  •  LOCKED" or "LOADER OPTIONS"
    draw_text_centered(Fonts.small, ui.x + ui.w*0.5, Layout.options_tag_y, header_txt, header_col)
    for i=1, show_n do
        local ctrl = CONFIG.controls[i]
        local cx = x0 + (i-1)*(ctrl_w+gap)
        local hover = (not locked) and (ui.ctrl_hover == i)
        local bg = hover and CONFIG.colors.panel_light or CONFIG.colors.panel
        local bd = ctrl.state and CONFIG.colors.accent_dim or CONFIG.colors.border
        if locked then bg = CONFIG.colors.panel; bd = CONFIG.colors.border end
        rounded_fill(cx,ctrl_y,cx+ctrl_w,ctrl_y+ctrl_h, ctrl_h*0.5, bg, locked and 160 or 255)
        rounded_outline(cx,ctrl_y,cx+ctrl_w,ctrl_y+ctrl_h, ctrl_h*0.5, bd, hover and 200 or 160)
        -- lock overlay
        if locked then
            set_color(CONFIG.colors.muted_dark, 90) draw.FilledCircle(cx+ctrl_w-8, ctrl_y+6, 3)
            set_color(CONFIG.colors.muted_dark, 40) draw.FilledCircle(cx+ctrl_w-8, ctrl_y+6, 5)
        end
        local dot_x = cx + 8
        local dot_y = ctrl_y + ctrl_h*0.5
        local dot_col = locked and CONFIG.colors.muted_dark or (ctrl.state and CONFIG.colors.accent or CONFIG.colors.muted_dark)
        set_color(dot_col) draw.FilledCircle(dot_x, dot_y, 3)
        if ctrl.state and not locked then set_color(CONFIG.colors.accent, 30) draw.FilledCircle(dot_x, dot_y, 5) end
        local label = truncate_text(Fonts.small, ctrl.label, ctrl_w-20)
        draw.SetFont(Fonts.small) local tw,th=draw.GetTextSize(label)
        local tx = l_floor(cx + 14 + (ctrl_w-14 - tw)*0.5)
        local ty = l_floor(ctrl_y + (ctrl_h - th)*0.5)
        local txt_col = locked and CONFIG.colors.muted_dark or (ctrl.state and CONFIG.colors.text or CONFIG.colors.muted)
        set_color(txt_col) draw.Text(tx,ty,label)
        local state_txt = locked and "LOCK" or (ctrl.state and "ON" or "OFF")
        local sc = locked and CONFIG.colors.muted_dark or (ctrl.state and CONFIG.colors.accent or CONFIG.colors.muted_dark)
        draw_text_centered(Fonts.small, cx + ctrl_w*0.5, ctrl_y+ctrl_h+4, state_txt, sc)
    end
end

------------------------------------------------------------
-- SETTINGS PAGE
------------------------------------------------------------
local function draw_settings()
    local x = ui.x + Layout.pad_x
    local y0 = Layout.header_end
    local w = Layout.content_w
    local locked = Loader.state ~= "READY"
    -- panel bg
    rounded_fill(x, y0+8, x+w, y0+8+Layout.window_end - y0 -16, 6, CONFIG.colors.panel, 255)
    rounded_outline(x, y0+8, x+w, y0+8+Layout.window_end - y0 -16, 6, locked and CONFIG.colors.border or CONFIG.colors.border, 255)
    draw_text_centered(Fonts.title, ui.x+ui.w*0.5, Layout.settings_title_y, "Loader Settings", locked and CONFIG.colors.muted or CONFIG.colors.text)
    local sub = locked and "locked — inject in progress" or "configure loader behaviour"
    draw_text_centered(Fonts.small, ui.x+ui.w*0.5, Layout.settings_title_y+24, sub, locked and CONFIG.colors.muted_dark or CONFIG.colors.muted_dark)
    fill_rect(x+20, Layout.settings_title_y+34, x+w-20, Layout.settings_title_y+35, locked and {60,60,60,255} or CONFIG.colors.border, 255)
    if locked then
        -- locked banner
        local bx = x+20; local by = Layout.settings_title_y+42; local bw = w-40; local bh = 18
        rounded_fill(bx,by,bx+bw,by+bh,4, {35,25,25,255})
        rounded_outline(bx,by,bx+bw,by+bh,4, {220,60,60,180})
        draw_text_centered(Fonts.small, bx+bw*0.5, by+4, "⚠  Settings locked after LOAD — inject started", {220,60,60,255})
    end
    local row_w = 260
    local row_h = Layout.settings_row_h
    local start_y = Layout.settings_start_y
    local cx = l_floor(ui.x + (ui.w - row_w)*0.5)
    for i, ctrl in ipairs(CONFIG.controls) do
        local ry = start_y + (i-1)*(row_h+8)
        local hover = (not locked) and (ui.settings_hover == i)
        local bg = locked and CONFIG.colors.panel or (hover and CONFIG.colors.panel_light or CONFIG.colors.background)
        local bd = locked and CONFIG.colors.muted_dark or CONFIG.colors.border
        local alpha = locked and 140 or 255
        rounded_fill(cx, ry, cx+row_w, ry+row_h, 6, bg, alpha)
        rounded_outline(cx, ry, cx+row_w, ry+row_h, 6, bd, hover and 180 or 255)
        -- label centered left
        local label_col = locked and CONFIG.colors.muted_dark or CONFIG.colors.text
        draw_text_vcentered(Fonts.info, cx+12, ry, row_h, ctrl.label, label_col)
        -- toggle switch right
        local tx = cx + row_w - 54
        local ty = ry + 6
        local tw = 42
        local th = 16
        local track_col = locked and CONFIG.colors.panel or (ctrl.state and CONFIG.colors.accent_dim or CONFIG.colors.panel)
        rounded_fill(tx, ty, tx+tw, ty+th, th/2, track_col, locked and 120 or 255)
        rounded_outline(tx, ty, tx+tw, ty+th, th/2, locked and CONFIG.colors.muted_dark or (ctrl.state and CONFIG.colors.accent or CONFIG.colors.border), locked and 90 or 180)
        local knob_x = ctrl.state and (tx+tw-8) or (tx+8)
        local knob_col = locked and CONFIG.colors.muted_dark or (ctrl.state and CONFIG.colors.accent or CONFIG.colors.muted)
        set_color(knob_col, locked and 140 or 255) draw.FilledCircle(knob_x, ty+th*0.5, 6)
        set_color({245,245,245,255}, locked and 100 or 255) draw.FilledCircle(knob_x, ty+th*0.5, 4)
        local st = locked and "LOCK" or (ctrl.state and "ON" or "OFF")
        local st_col = locked and CONFIG.colors.muted_dark or (ctrl.state and CONFIG.colors.accent or CONFIG.colors.muted_dark)
        draw_text_centered(Fonts.small, tx+tw*0.5, ty+th+5, st, st_col)
    end
    -- hint at bottom centered
    local hint_y = start_y + #CONFIG.controls*(row_h+8) + 12
    draw_text_centered(Fonts.small, ui.x+ui.w*0.5, hint_y, "changes saved to forwardtrack_loader.txt", CONFIG.colors.muted_dark)
    draw_text_centered(Fonts.small, ui.x+ui.w*0.5, hint_y+14, "click gear again to return", CONFIG.colors.accent)
end

------------------------------------------------------------
-- DRAW BUTTON (with Loader Injected moved lower)
------------------------------------------------------------
local function draw_load_button()
    local bx=ui.x+Layout.pad_x; local by=Layout.button_y; local bw=Layout.content_w; local bh=Layout.button_h; local r=6
    local base=CONFIG.colors.button; local hover_col=CONFIG.colors.button_hover
    local t=ui.hover_anim
    local col={ l_floor(lerp(base[1],hover_col[1],t)), l_floor(lerp(base[2],hover_col[2],t)), l_floor(lerp(base[3],hover_col[3],t)), 255 }
    if ui.load_pressed then col=CONFIG.colors.button_pressed end
    rounded_fill(bx,by+2,bx+bw,by+bh+2,r,CONFIG.colors.shadow,30)
    rounded_fill(bx,by,bx+bw,by+bh,r,col)
    rounded_outline(bx,by,bx+bw,by+bh,r,CONFIG.colors.border)
    set_color(CONFIG.colors.shine, l_floor(18+18*(1-t))) draw.Line(bx+r,by+1,bx+bw-r,by+1)
    if ui.hover_anim>0.02 or Loader.state~="READY" then
        local a=l_floor(180*clamp(ui.hover_anim + (Loader.state~="READY" and 0.5 or 0),0,1))
        fill_rect(bx+r,by+bh-1,bx+bw-r,by+bh,CONFIG.colors.accent,a)
    end
    local text="LOAD"; local text_color=CONFIG.colors.accent
    if Loader.state=="LOADING" then text="LOADING..." elseif Loader.state=="LOADED" then text="LOADED!" end
    draw.SetFont(Fonts.body) local tw,th=draw.GetTextSize(text)
    local tx=l_floor(bx+(bw-tw)*0.5); local ty=l_floor(by+(bh-th)*0.5)
    if Loader.state=="LOADING" then
        local sp_r=7; local sp_x=tx-16; local sp_y=by+bh*0.5
        set_color(CONFIG.colors.progress_bg) draw.OutlinedCircle(sp_x,sp_y,sp_r)
        local ang=Timing.time*6; local hx=sp_x+l_cos(ang)*(sp_r-1); local hy=sp_y+l_sin(ang)*(sp_r-1)
        set_color(CONFIG.colors.accent) draw.FilledCircle(hx,hy,2)
        tx=tx+6
    elseif Loader.state=="LOADED" then
        local sp_x=l_floor(bx+(bw-tw)*0.5)-14; local sp_y=by+bh*0.5
        draw.SetFont(Fonts.body) tw,th=draw.GetTextSize(text) tx=l_floor(bx+(bw-tw)*0.5+8)
        set_color(CONFIG.colors.accent) draw.FilledCircle(sp_x+6,sp_y,7)
        set_color({18,18,18,255}) draw.SetFont(Fonts.small) local ctw,cth=draw.GetTextSize("✓") draw.Text(l_floor(sp_x+6-ctw*0.5), l_floor(sp_y-cth*0.5), "✓") draw.SetFont(Fonts.body)
    end
    set_color(text_color) draw.Text(tx,ty,text)
    -- duplicate Loader Injected removed (only progress stage shows it)
end

------------------------------------------------------------
-- DRAW PROGRESS (stage moved, own space)
------------------------------------------------------------
local function draw_progress()
    if Loader.state=="READY" then return end
    local x=ui.x+Layout.pad_x; local y=Layout.progress_y; local w=Layout.content_w; local h=Layout.progress_h; local r=h*0.5
    rounded_fill(x,y,x+w,y+h,r,CONFIG.colors.progress_bg)
    rounded_outline(x,y,x+w,y+h,r,CONFIG.colors.border)
    local prog=clamp(ui.progress_visual,0,1); local fill_w=l_floor(w*prog)
    if fill_w>0 then
        if prog>=0.985 then rounded_fill(x,y,x+fill_w,y+h,r,CONFIG.colors.accent)
        else
            rounded_fill(x,y,x+fill_w,y+h,r,CONFIG.colors.accent)
            if fill_w>r then fill_rect(x+fill_w-r,y,x+fill_w,y+h,CONFIG.colors.accent) end
            set_color(CONFIG.colors.accent,55) draw.FilledCircle(x+fill_w,y+h*0.5,6)
            set_color(CONFIG.colors.accent,22) draw.FilledCircle(x+fill_w,y+h*0.5,9)
        end
        if fill_w>6 then fill_rect(x+2,y+1,x+fill_w-2,y+2,CONFIG.colors.shine,26) end
        if Loader.state=="LOADING" and fill_w>20 then
            local sw=28; local sx=x+(fill_w+sw)*ui.shimmer-sw
            local sx1=l_max(sx,x); local sx2=l_min(sx+sw,x+fill_w)
            if sx2>sx1 then local mid=(sx1+sx2)*0.5 fill_rect(sx1,y,mid,y+h,{255,255,255,18}) fill_rect(mid,y,sx2,y+h,{255,255,255,7}) end
        end
    end
    local percent=l_floor(prog*100+0.5); local text=tostring(percent).."%"
    draw_text_centered(Fonts.info, x + w*0.5, Layout.percent_y, text, CONFIG.colors.muted)
    local stage = Loader.state=="LOADING" and phases[clamp(Loader.phase_index,1,#phases)].name or (Loader.state=="LOADED" and "Loader injected" or "")
    if stage~="" then draw_text_centered(Fonts.small, x + w*0.5, Layout.stage_y, truncate_text(Fonts.small, stage, w), CONFIG.colors.muted_dark) end
end

------------------------------------------------------------
-- DRAW DATA LOADING
------------------------------------------------------------
local function draw_data_loading()
    if Loader.state=="READY" then return end
    local x=ui.x+Layout.pad_x; local y=Layout.dataloading_y; local w=Layout.content_w; local h=Layout.dataloading_h; local r=6
    rounded_fill(x,y,x+w,y+h,r,CONFIG.colors.logger_bg)
    rounded_outline(x,y,x+w,y+h,r,CONFIG.colors.border)
    fill_rect(x+r,y,x+w-r,y+1,CONFIG.colors.hairline,255)
    fill_rect(x,y,x+w,y+18,CONFIG.colors.header)
    fill_rect(x,y+18,x+w,y+19,CONFIG.colors.border)
    draw_text_centered(Fonts.small, x + w*0.5, y+5, "DATA LOADING", CONFIG.colors.muted_dark)
    local dot_col=Loader.state=="LOADING" and CONFIG.colors.accent or CONFIG.colors.muted_dark
    local dot_a=Loader.state=="LOADING" and l_floor(160+90*ui.pulse) or 140
    set_color(dot_col,dot_a) draw.FilledCircle(x+w-10,y+9,3)
    set_color(dot_col,dot_a*0.6) draw.FilledCircle(x+10,y+9,2)
    local count=l_min(#Loader.logger,6)
    local max_text_w = w - 20
    for i=1,count do
        local entry=Loader.logger[#Loader.logger-count+i]
        local alpha_mul=0.55+0.45*(i/count)
        local y_off=y+26+((i-1)*13)
        local col=get_logger_color(entry.level)
        local c={col[1],col[2],col[3], l_floor((col[4] or 255)*alpha_mul)}
        local txt = truncate_text(Fonts.mono, "> "..entry.message, max_text_w)
        draw_text_centered(Fonts.mono, x + w*0.5, y_off, txt, c)
    end
end

------------------------------------------------------------
-- DRAW TRASH BANTER
------------------------------------------------------------
local function draw_trash_banter()
    if Loader.state=="READY" then return end
    local x=ui.x+Layout.pad_x; local y=Layout.banter_y; local w=Layout.content_w; local h=Layout.banter_h
    rounded_fill(x,y,x+w,y+h,4,CONFIG.colors.panel, 180)
    rounded_outline(x,y,x+w,y+h,4,CONFIG.colors.border, 90)
    local alpha = 200 + l_floor(30 * ui.pulse)
    local col = {CONFIG.colors.troll[1], CONFIG.colors.troll[2], CONFIG.colors.troll[3], alpha}
    local txt = truncate_text(Fonts.small, ui.banter_text, w-12)
    draw_text_centered(Fonts.small, x + w*0.5, y+4, txt, col)
end

------------------------------------------------------------
-- DRAW STATUS - custom card, natural, no duplicity
------------------------------------------------------------
local function draw_status()
    local x = ui.x + Layout.pad_x
    local y = Layout.status2_y
    local w = Layout.content_w
    local h = Layout.status_h
    -- LOADED: new custom - split design, different than before
    if Loader.state == "LOADED" then
        rounded_fill(x,y,x+w,y+h,8,CONFIG.colors.panel_active)
        rounded_outline(x,y,x+w,y+h,8,CONFIG.colors.accent, 180)
        fill_rect(x+8,y+1,x+w-8,y+2,CONFIG.colors.accent, 32)
        -- left checkmark with double glow
        local cx = x + 20
        local cy = y + h*0.5
        set_color(CONFIG.colors.accent, 28) draw.FilledCircle(cx,cy,15)
        set_color(CONFIG.colors.accent, 55) draw.FilledCircle(cx,cy,10)
        set_color(CONFIG.colors.accent) draw.FilledCircle(cx,cy,7)
        draw_text_centered_box(Fonts.icon, cx-6, cy-6, 12,12,"✓", {14,14,14,255})
        -- center LOADED
        local mid_x = x + w*0.5 - 8
        draw_text_centered(Fonts.body, mid_x, y+5, "LOADED", CONFIG.colors.accent)
        draw_text_centered(Fonts.small, mid_x, y+18, "Verified • Ready to inject • v"..CONFIG.version, CONFIG.colors.muted)
        -- right 100% + DONE
        local rx = x + w - 34
        draw_text_centered(Fonts.info, rx, y+5, "100%", CONFIG.colors.accent)
        draw_text_centered(Fonts.small, rx, y+18, "DONE", CONFIG.colors.muted_dark)
        -- bottom accent line
        fill_rect(x+12,y+h-1,x+w-12,y+h,CONFIG.colors.accent, 85)
        -- top subtle inner highlight
        fill_rect(x+12,y+1,x+w-12,y+2,CONFIG.colors.shine, 18)
        return
    end
    -- READY / LOADING: simple natural card
    rounded_fill(x,y,x+w,y+h,6,CONFIG.colors.panel)
    rounded_outline(x,y,x+w,y+h,6,CONFIG.colors.border)
    local accent = CONFIG.colors.muted
    if Loader.state=="LOADING" then accent = CONFIG.colors.accent end
    fill_rect(x+1,y+1,x+4,y+h-1,accent, Loader.state=="READY" and 60 or 255)
    if Loader.state=="LOADING" then
        set_color(accent, 25) draw.FilledCircle(x+12, y+h*0.5, 10)
    end
    local cx = x + w*0.5
    local color=CONFIG.colors.muted
    if Loader.state=="LOADING" then color=CONFIG.colors.accent end
    draw.SetFont(Fonts.info) local txt="Status: "..Loader.state; local tw,th=draw.GetTextSize(txt)
    local dot_x = l_floor(cx - tw*0.5 - 12)
    local dot_y = y + 8
    local pulsing=(Loader.state=="LOADING")
    set_color(color, pulsing and l_floor(70+60*ui.pulse) or 55) draw.FilledCircle(dot_x,dot_y, pulsing and 8 or 6)
    set_color(color,255) draw.FilledCircle(dot_x,dot_y,3)
    draw_text_centered(Fonts.info, cx+6, y+6, txt, color)
    local hint=Loader.state=="READY" and "Press LOAD to start loader" or "Loader working — do not close"
    draw_text_centered(Fonts.small, cx, y+18, hint, CONFIG.colors.muted_dark)
    fill_rect(x+10,y+h-1,x+w-10,y+h,CONFIG.colors.border, 40)
end

------------------------------------------------------------
-- DRAW (main)
------------------------------------------------------------
local function on_draw()
    if not menu_open:GetValue() then return end
    update_dt()
    updateLayout()
    local mx,my=input.GetMousePos()
    update_drag(mx,my); update_button(mx,my); update_loading()
    draw_header()
    if ui.view == "settings" then
        draw_settings()
        return
    end
    draw_information()
    draw_status_bar()
    draw_loader_options()
    draw_load_button()
    draw_progress()
    draw_data_loading()
    draw_trash_banter()
    draw_status()
end

------------------------------------------------------------
-- UNLOAD
------------------------------------------------------------
local function on_unload() save_loader_settings() ui.dragging=false; Loader.state="READY"; Loader.logger={} end

------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------
math.randomseed(l_floor((g_RealTime()+common.Time())*100000)%2147483647)
init_fonts()
load_loader_settings()
logger_add("Loader ready. Awaiting input.", "OK")
callbacks.Register("Draw", "Mictian_Loader_v029t_Draw", on_draw)
callbacks.Register("Unload", "Mictian_Loader_v029t_Unload", on_unload)
