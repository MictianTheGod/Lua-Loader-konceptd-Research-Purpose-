--[[
Forward Loader v0.3.2
Loader-Only / Research Build

v0.3.2
- [FIX] Loader v0.3.1.lua:2142 fill_rect nil - added local fill_rect helper before use
- [FIX] Loader v0.3.1.lua:1834 abs nil - added local abs = math.abs
- [AUDIT] Full API check vs Aimware v5 API docs (Globals/Callbacks/Ressources) - draw.CreateFont 3-arg, draw.* , input.* , file.* , globals.* , callbacks.* verified

Based on:
    Forward Loader v0.2.7

v0.2.8
------------------------------------------------------------
UI / UX
- Reworked SYSTEM STATUS
- Removed duplicated status information
- Separated SYSTEM STATUS from LOADER STATUS
- Reworked LOADER OPTIONS into independent cards
- Improved main-page spacing
- Improved settings-page spacing
- Dedicated button hitboxes
- Dedicated settings-toggle hitboxes
- Centralized layout ownership

Loader
- Preserved READY -> LOADING -> LOADED lifecycle
- Preserved slow randomized loading
- Preserved progress smoothing
- Preserved boot logger
- Preserved banter

API
- common.Time() used as primary timing source
- gui.Reference() created once
- callbacks use unique identifiers
- documented draw/input/file APIs only

Safety
- Loader only
- No injection implementation
- Auto Inject remains a UI setting only
- Telemetry handoff remains disabled until explicitly implemented

NOTE:
Paste this as raw Lua source.
Do NOT include Markdown ``` fences in the file.

]]



local MENU_REFERENCE = gui.Reference("MENU")



local floor = math.floor
local min = math.min
local max = math.max
local sin = math.sin
local cos = math.cos
local abs = math.abs
local exp = math.exp
local random = math.random



local CONFIG = {

width = 375,
height = 590,

header_height = 32,
radius = 6,

version = "0.3.2",
build_date = "Aug 29 2026",
build_type = "x64",
registered_to = "Mictian",

min_boot_time = 4.70,
random_variation = 0.18,

smooth_progress = 8.0,
smooth_hover = 14.0,

--------------------------------------------------------
-- Loader options
--------------------------------------------------------

controls = {

    {
        id = "secure",
        label = "Secure Boot",
        state = true
    },

    {
        id = "cloud",
        label = "Cloud Sync",
        state = true
    },

    {
        id = "debug",
        label = "Debug",
        state = false
    },

    {
        id = "autoinj",
        label = "Auto Inject",
        state = false
    },

    {
        id = "notify",
        label = "Notifications",
        state = true
    }
},

--------------------------------------------------------
-- Theme
--------------------------------------------------------

colors = {

    background = {
        14, 14, 14, 255
    },

    background_2 = {
        17, 17, 17, 255
    },

    header = {
        18, 18, 18, 255
    },

    panel = {
        22, 22, 22, 255
    },

    panel_light = {
        28, 28, 28, 255
    },

    panel_active = {
        26, 34, 22, 255
    },

    border = {
        38, 38, 38, 255
    },

    border_light = {
        54, 54, 54, 255
    },

    text = {
        242, 242, 242, 255
    },

    text_dim = {
        190, 190, 190, 255
    },

    muted = {
        145, 145, 145, 255
    },

    muted_dark = {
        108, 108, 108, 255
    },

    accent = {
        118, 210, 0, 255
    },

    accent_dim = {
        80, 145, 0, 255
    },

    accent_soft = {
        118, 210, 0, 16
    },

    red = {
        220, 60, 60, 255
    },

    orange = {
        230, 165, 60, 255
    },

    button = {
        30, 30, 30, 255
    },

    button_hover = {
        46, 46, 46, 255
    },

    button_pressed = {
        36, 36, 36, 255
    },

    progress_bg = {
        39, 39, 39, 255
    },

    logger_bg = {
        12, 12, 12, 255
    },

    shadow = {
        0, 0, 0, 80
    },

    shine = {
        255, 255, 255, 36
    },

    troll = {
        155, 155, 155, 255
    },

    troll_dim = {
        120, 120, 120, 255
    }
}

}



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
"[DATA] Estimating IQ... two digits",
"[DATA] Loading confidence... ego heavy",
"[DATA] Syncing skill issue... confirmed",
"[DATA] Next death... queued [OK]"

}



local UI = {

x = 320,
y = 200,

w = CONFIG.width,
h = CONFIG.height,

visible = true,

dragging = false,
drag_x = 0,
drag_y = 0,

load_hover = false,
load_pressed = false,

gear_hover = false,
close_hover = false,

ctrl_hover = -1,
settings_hover = -1,

hover_anim = 0,
progress_visual = 0,

shimmer = 0,
pulse = 0,

banter_idx = 1,
banter_text = BANTER_POOL[1],
banter_t = 0,

last_save_t = 0,
save_error_printed = false,

view = "main"

}



local Loader = {

state = "READY",

start_time = 0,
state_time = 0,

progress = 0,

phase_index = 0,

phase_start_progress = 0,
phase_target_progress = 0,

phase_duration = 0,

handoff_started = false,

logger = {}

}



local Timing = {

last = common.Time(),
dt = 0,
time = 0

}

local function update_timing()

local current = common.Time()

local dt =
    current - Timing.last

if dt < 0 then
    dt = 0
end

if dt > 0.05 then
    dt = 0.05
end

Timing.last = current
Timing.time = current
Timing.dt = dt

end



local function clamp(
value,
minimum,
maximum
)

if value < minimum then
    return minimum
end

if value > maximum then
    return maximum
end

return value

end


local function lerp(
a,
b,
t
)

return a + (b - a) * t

end


local function exp_smooth(
current,
target,
speed
)

local dt =
    Timing.dt

if dt <= 0 then
    return current
end

local factor =
    1 - exp(
        -speed * dt
    )

factor =
    clamp(
        factor,
        0,
        1
    )

return current +
    (target - current) *
    factor

end


local function ease_in_out(
t
)

t =
    clamp(
        t,
        0,
        1
    )

if t < 0.5 then
    return 2 * t * t
end

return 1 -
    (
        ((-2 * t + 2) ^ 2) /
        2
    )

end


local function in_bounds(
mx,
my,
x,
y,
w,
h
)

return mx >= x
   and mx <= x + w
   and my >= y
   and my <= y + h

end



local Fonts = {

title = nil,
body = nil,
info = nil,
small = nil,
mono = nil,
icon = nil,
gear = nil

}


local function create_font(
name,
size,
weight
)

local ok, font =
    pcall(
        draw.CreateFont,
        name,
        size,
        weight
    )

if ok and font ~= nil then
    return font
end

local fallback_ok, fallback =
    pcall(
        draw.CreateFont,
        "Verdana",
        size,
        weight
    )

if fallback_ok then
    return fallback
end

return nil

end


local function init_fonts()

Fonts.title =
    create_font(
        "Bahnschrift",
        22,
        700
    )

Fonts.body =
    create_font(
        "Bahnschrift",
        16,
        700
    )

Fonts.info =
    create_font(
        "Bahnschrift",
        14,
        600
    )

Fonts.small =
    create_font(
        "Verdana",
        11,
        600
    )

Fonts.mono =
    create_font(
        "Consolas",
        11,
        500
    )

Fonts.icon =
    create_font(
        "Verdana",
        11,
        700
    )

Fonts.gear =
    create_font(
        "Verdana",
        14,
        700
    )

end



local function set_color(
color,
alpha
)

draw.Color(
    color[1],
    color[2],
    color[3],
    alpha or color[4]
)

end


local function fill_rect(
x1,
y1,
x2,
y2,
color,
alpha
)

set_color(
    color,
    alpha
)

draw.FilledRect(
    x1,
    y1,
    x2,
    y2
)

end


local function rounded_fill(
x1,
y1,
x2,
y2,
radius,
color,
alpha
)

set_color(
    color,
    alpha
)

draw.RoundedRectFill(
    x1,
    y1,
    x2,
    y2,
    radius,
    1,
    1,
    1,
    1
)

end


local function rounded_outline(
x1,
y1,
x2,
y2,
radius,
color,
alpha
)

set_color(
    color,
    alpha
)

draw.RoundedRect(
    x1,
    y1,
    x2,
    y2,
    radius,
    1,
    1,
    1,
    1
)

end


local function draw_text(
font,
x,
y,
text,
color,
alpha
)

if font == nil then
    return
end

draw.SetFont(font)

set_color(
    color,
    alpha
)

draw.Text(
    floor(x),
    floor(y),
    text
)

end


local function text_size(
font,
text
)

if font == nil then
    return 0, 0
end

draw.SetFont(font)

return draw.GetTextSize(
    text
)

end


local function draw_text_centered(
font,
center_x,
y,
text,
color,
alpha
)

local tw =
    text_size(
        font,
        text
    )

draw_text(
    font,
    center_x -
    tw * 0.5,
    y,
    text,
    color,
    alpha
)

end


local function draw_text_vcentered(
font,
x,
y,
h,
text,
color,
alpha
)

local _, th =
    text_size(
        font,
        text
    )

draw_text(
    font,
    x,
    y +
    (h - th) *
    0.5,
    text,
    color,
    alpha
)

end


local function draw_text_centered_box(
font,
x,
y,
w,
h,
text,
color,
alpha
)

local tw, th =
    text_size(
        font,
        text
    )

draw_text(
    font,
    x +
    (w - tw) *
    0.5,
    y +
    (h - th) *
    0.5,
    text,
    color,
    alpha
)

end


local function draw_centered_kv(
font,
center_x,
y,
key,
key_color,
value,
value_color,
gap
)

gap = gap or 6

local kw =
    text_size(
        font,
        key
    )

local vw =
    text_size(
        font,
        value
    )

local total =
    kw +
    gap +
    vw

local start_x =
    floor(
        center_x -
        total * 0.5
    )

draw_text(
    font,
    start_x,
    y,
    key,
    key_color
)

draw_text(
    font,
    start_x +
    kw +
    gap,
    y,
    value,
    value_color
)

end


local function truncate_text(
font,
text,
max_width
)

local tw =
    text_size(
        font,
        text
    )

if tw <= max_width then
    return text
end

local suffix = "..."

local suffix_w =
    text_size(
        font,
        suffix
    )

local allowed =
    max_width -
    suffix_w

if allowed <= 0 then
    return suffix
end

local length =
    #text

while length > 0 do

    local part =
        text:sub(
            1,
            length
        )

    local pw =
        text_size(
            font,
            part
        )

    if pw <= allowed then
        return part ..
            suffix
    end

    length =
        length - 1
end

return suffix

end



local SETTINGS_FILE =
"forwardtrack_loader.txt"


local function save_loader_settings()

if Timing.time -
    UI.last_save_t < 0.30 then

    return
end

UI.last_save_t =
    Timing.time

local payload =
    string.format(
        "secure=%d\ncloud=%d\ndebug=%d\nautoinj=%d\nnotify=%d\n",

        CONFIG.controls[1].state
        and 1
        or 0,

        CONFIG.controls[2].state
        and 1
        or 0,

        CONFIG.controls[3].state
        and 1
        or 0,

        CONFIG.controls[4].state
        and 1
        or 0,

        CONFIG.controls[5].state
        and 1
        or 0
    )

local ok, err =
    pcall(
        function()
            file.Write(
                SETTINGS_FILE,
                payload
            )
        end
    )

if not ok then

    if not UI.save_error_printed then

        print(
            "[Loader] save failed: " ..
            tostring(err)
        )

        UI.save_error_printed =
            true
    end

else

    UI.save_error_printed =
        false
end

end


local function load_loader_settings()

local exists = false

local enum_ok =
    pcall(
        function()

            file.Enumerate(
                function(
                    name
                )

                    if name ==
                        SETTINGS_FILE then

                        exists = true
                    end
                end
            )
        end
    )

if not enum_ok
   or not exists then

    return
end

local ok, content =
    pcall(
        function()

            return file.Read(
                SETTINGS_FILE
            )
        end
    )

if not ok
   or content == nil then

    return
end

for line in
    content:gmatch(
        "[^\r\n]+"
    ) do

    local key, value =
        line:match(
            "(%w+)=(%d+)"
        )

    if key == "secure" then

        CONFIG.controls[1].state =
            value == "1"

    elseif key == "cloud" then

        CONFIG.controls[2].state =
            value == "1"

    elseif key == "debug" then

        CONFIG.controls[3].state =
            value == "1"

    elseif key == "autoinj" then

        CONFIG.controls[4].state =
            value == "1"

    elseif key == "notify" then

        CONFIG.controls[5].state =
            value == "1"
    end
end

end



local function logger_add(
message,
level
)

Loader.logger[
    #Loader.logger + 1
] = {

    message = message,
    level = level or "INFO",
    time = Timing.time
}

if #Loader.logger > 7 then

    table.remove(
        Loader.logger,
        1
    )
end

end


local function logger_color(
level
)

if level == "OK" then
    return CONFIG.colors.accent
end

if level == "WARN" then
    return CONFIG.colors.orange
end

if level == "ERROR" then
    return CONFIG.colors.red
end

if level == "TROLL" then
    return CONFIG.colors.troll
end

return CONFIG.colors.muted

end



local phases = {

{
    name = "Preparing interface...",
    target = 0.12,
    duration = 0.58
},

{
    name = "Loading typography...",
    target = 0.27,
    duration = 0.64
},

{
    name = "Building overlay...",
    target = 0.45,
    duration = 0.52
},

{
    name = "Initializing animations...",
    target = 0.67,
    duration = 0.77
},

{
    name = "Validating components...",
    target = 0.83,
    duration = 0.68
},

{
    name = "Preparing telemetry...",
    target = 0.95,
    duration = 0.71
},

{
    name = "Finalizing...",
    target = 1.00,
    duration = 0.65
}

}


local function randomized_duration(
base
)

local variation =
    base *
    CONFIG.random_variation

return base +
    (
        random() * 2 -
        1
    ) *
    variation

end



local function start_loading()

if Loader.state ~=
    "READY" then

    return
end

Loader.state =
    "LOADING"

Loader.start_time =
    Timing.time

Loader.state_time =
    Timing.time

Loader.progress =
    0

Loader.phase_index =
    1

Loader.phase_start_progress =
    0

Loader.phase_target_progress =
    phases[1].target

Loader.phase_duration =
    randomized_duration(
        phases[1].duration
    )

Loader.handoff_started =
    false

Loader.logger = {}

UI.progress_visual =
    0

UI.banter_idx =
    random(
        1,
        #BANTER_POOL
    )

UI.banter_text =
    BANTER_POOL[
        UI.banter_idx
    ]

UI.banter_t =
    Timing.time

logger_add(
    "Starting ForwardTrack Loader...",
    "INFO"
)

logger_add(
    phases[1].name,
    "INFO"
)

if CONFIG.controls[1].state then

    logger_add(
        "Secure Boot enabled",
        "INFO"
    )

else

    logger_add(
        "Secure Boot disabled",
        "WARN"
    )
end

if CONFIG.controls[2].state then

    logger_add(
        "Cloud Sync enabled",
        "INFO"
    )

else

    logger_add(
        "Cloud Sync disabled",
        "INFO"
    )
end

end



local function update_loading()

if Loader.state ~=
    "LOADING" then

    return
end

local now =
    Timing.time

local phase =
    phases[
        Loader.phase_index
    ]

--------------------------------------------------------
-- Safety completion.
--------------------------------------------------------

if phase == nil then

    Loader.progress =
        1

    Loader.state =
        "LOADED"

    Loader.state_time =
        now

    logger_add(
        "All loader tasks complete.",
        "OK"
    )

    return
end

local elapsed =
    now -
    Loader.state_time

local phase_t =
    clamp(
        elapsed /
        Loader.phase_duration,
        0,
        1
    )

local eased =
    ease_in_out(
        phase_t
    )

Loader.progress =
    lerp(
        Loader.phase_start_progress,
        Loader.phase_target_progress,
        eased
    )

--------------------------------------------------------
-- Explicit phase snap.
--------------------------------------------------------

if phase_t >= 1 then

    Loader.progress =
        Loader.phase_target_progress

    logger_add(
        phase.name ..
        " ready.",
        "OK"
    )

    Loader.phase_index =
        Loader.phase_index + 1

    local next_phase =
        phases[
            Loader.phase_index
        ]

    if next_phase ~= nil then

        Loader.phase_start_progress =
            Loader.progress

        Loader.phase_target_progress =
            next_phase.target

        Loader.phase_duration =
            randomized_duration(
                next_phase.duration
            )

        Loader.state_time =
            now

        logger_add(
            next_phase.name,
            "INFO"
        )

    else

        Loader.progress =
            1

        Loader.state =
            "LOADED"

        Loader.state_time =
            now

        logger_add(
            "All systems loaded.",
            "OK"
        )
    end
end

--------------------------------------------------------
-- Minimum visible duration.
--------------------------------------------------------

if Loader.state == "LOADED" then

    local total_elapsed =
        now -
        Loader.start_time

    if total_elapsed <
        CONFIG.min_boot_time then

        Loader.state =
            "LOADING"

        Loader.phase_index =
            #phases

        Loader.phase_start_progress =
            max(
                Loader.progress,
                0.95
            )

        Loader.phase_target_progress =
            1.0

        Loader.phase_duration =
            max(
                CONFIG.min_boot_time -
                total_elapsed,
                0.18
            )

        Loader.state_time =
            now
    end
end

end



local function update_input(
mx,
my
)

--------------------------------------------------------
-- Header controls
--------------------------------------------------------

local close_w =
    28

local close_x =
    UI.x +
    UI.w -
    close_w

UI.close_hover =
    in_bounds(
        mx,
        my,
        close_x,
        UI.y,
        close_w,
        CONFIG.header_height
    )

local gear_w =
    28

local gear_x =
    close_x -
    gear_w -
    2

UI.gear_hover =
    in_bounds(
        mx,
        my,
        gear_x,
        UI.y,
        gear_w,
        CONFIG.header_height
    )

if UI.gear_hover
   and input.IsButtonPressed(1) then

    if UI.view ==
        "main" then

        UI.view =
            "settings"

    else

        UI.view =
            "main"
    end

    return
end

if UI.close_hover
   and input.IsButtonPressed(1) then

    UI.visible =
        false

    return
end

--------------------------------------------------------
-- Settings page
--------------------------------------------------------

if UI.view ==
    "settings" then

    UI.settings_hover =
        -1

    local row_w =
        275

    local row_h =
        34

    local start_y =
        Layout.settings_start_y

    local row_x =
        floor(
            UI.x +
            (
                UI.w -
                row_w
            ) * 0.5
        )

    for i, ctrl in
        ipairs(
            CONFIG.controls
        ) do

        local row_y =
            start_y +
            (i - 1) *
            (
                row_h +
                Layout.settings_gap
            )

        local toggle_w =
            48

        local toggle_h =
            18

        local toggle_x =
            row_x +
            row_w -
            toggle_w -
            10

        local toggle_y =
            row_y +
            (
                row_h -
                toggle_h
            ) * 0.5

        if in_bounds(
            mx,
            my,
            toggle_x,
            toggle_y,
            toggle_w,
            toggle_h
        ) then

            UI.settings_hover =
                i

            if input.IsButtonPressed(1) then

                ctrl.state =
                    not ctrl.state

                save_loader_settings()

                logger_add(
                    ctrl.label ..
                    " " ..
                    (
                        ctrl.state
                        and "ON"
                        or "OFF"
                    ),
                    "INFO"
                )
            end
        end
    end

    return
end

--------------------------------------------------------
-- Main LOAD button
--------------------------------------------------------

local bx =
    UI.x +
    Layout.pad_x

local by =
    Layout.button_y

local bw =
    Layout.content_w

local bh =
    Layout.button_h

UI.load_hover =
    in_bounds(
        mx,
        my,
        bx,
        by,
        bw,
        bh
    )

UI.load_pressed =
    false

if Loader.state ==
    "READY"
    and UI.load_hover
    and input.IsButtonPressed(1) then

    UI.load_pressed =
        true

    start_loading()
end

--------------------------------------------------------
-- Loader Option cards
--------------------------------------------------------

UI.ctrl_hover =
    -1

local count =
    3

local card_w =
    98

local card_gap =
    7

local total_w =
    count * card_w +
    (count - 1) *
    card_gap

local start_x =
    floor(
        UI.x +
        (
            UI.w -
            total_w
        ) * 0.5
    )

for i = 1, count do

    local ctrl =
        CONFIG.controls[i]

    local cx =
        start_x +
        (i - 1) *
        (
            card_w +
            card_gap
        )

    local cy =
        Layout.options_y

    if in_bounds(
        mx,
        my,
        cx,
        cy,
        card_w,
        Layout.options_h
    ) then

        UI.ctrl_hover =
            i

        if input.IsButtonPressed(1) then

            ctrl.state =
                not ctrl.state

            save_loader_settings()

            logger_add(
                ctrl.label ..
                " " ..
                (
                    ctrl.state
                    and "ON"
                    or "OFF"
                ),
                "INFO"
            )
        end
    end
end

end



local function update_drag(
mx,
my
)

if UI.view ==
    "settings" then

    UI.dragging =
        false

    return
end

local mouse_down =
    input.IsButtonDown(1)

local header_hit =
    in_bounds(
        mx,
        my,
        UI.x,
        UI.y,
        UI.w,
        CONFIG.header_height
    )

local close_area =
    UI.close_hover
    or UI.gear_hover

if mouse_down
   and header_hit
   and not close_area
   and not UI.dragging then

    UI.dragging =
        true

    UI.drag_x =
        mx -
        UI.x

    UI.drag_y =
        my -
        UI.y
end

if not mouse_down then

    UI.dragging =
        false

    return
end

if UI.dragging then

    UI.x =
        mx -
        UI.drag_x

    UI.y =
        my -
        UI.drag_y

    update_layout()
end

end



local function update_visuals()

local hover_target =
    (
        UI.load_hover
        and Loader.state ==
        "READY"
    )
    and 1
    or 0

if UI.load_pressed then
    hover_target = 0.55
end

UI.hover_anim =
    exp_smooth(
        UI.hover_anim,
        hover_target,
        CONFIG.smooth_hover
    )

UI.progress_visual =
    exp_smooth(
        UI.progress_visual,
        Loader.progress,
        CONFIG.smooth_progress
    )

if abs(
    UI.progress_visual -
    Loader.progress
) < 0.0005 then

    UI.progress_visual =
        Loader.progress
end

UI.shimmer =
    (
        Timing.time *
        0.55
    ) %
    1

UI.pulse =
    0.5 +
    0.5 *
    sin(
        Timing.time *
        3.2
    )

if Loader.state ==
    "LOADING"
    or Loader.state ==
    "LOADED" then

    if Timing.time -
        UI.banter_t >
        1.9 then

        UI.banter_idx =
            (
                UI.banter_idx %
                #BANTER_POOL
            ) + 1

        if random() < 0.25 then

            UI.banter_idx =
                random(
                    1,
                    #BANTER_POOL
                )
        end

        UI.banter_text =
            BANTER_POOL[
                UI.banter_idx
            ]

        UI.banter_t =
            Timing.time
    end

else

    UI.banter_text =
        BANTER_POOL[1]
end

end



Layout = {}

function update_layout()

local y0 =
    UI.y

Layout.pad_x =
    25

Layout.content_w =
    CONFIG.width -
    Layout.pad_x * 2

Layout.header_end =
    y0 +
    CONFIG.header_height

--------------------------------------------------------
-- Identity
--------------------------------------------------------

Layout.title_y =
    Layout.header_end +
    20

Layout.info_y =
    Layout.title_y +
    31

Layout.info_row_h =
    18

Layout.info_end =
    Layout.info_y +
    Layout.info_row_h *
    4

Layout.divider_y =
    Layout.info_end +
    14

--------------------------------------------------------
-- Main LOAD button
--------------------------------------------------------

Layout.button_y =
    Layout.divider_y +
    12

Layout.button_h =
    36

Layout.button_end =
    Layout.button_y +
    Layout.button_h

--------------------------------------------------------
-- System status
--------------------------------------------------------

Layout.status_tag_y =
    Layout.button_end +
    12

Layout.status_bar_y =
    Layout.status_tag_y +
    15

Layout.status_bar_h =
    30

Layout.status_bar_end =
    Layout.status_bar_y +
    Layout.status_bar_h

--------------------------------------------------------
-- Options
--------------------------------------------------------

Layout.options_tag_y =
    Layout.status_bar_end +
    12

Layout.options_y =
    Layout.options_tag_y +
    15

Layout.options_h =
    34

Layout.options_end =
    Layout.options_y +
    Layout.options_h

--------------------------------------------------------
-- Progress
--------------------------------------------------------

Layout.stage_y =
    Layout.options_end +
    12

Layout.progress_y =
    Layout.options_end +
    29

Layout.progress_h =
    7

Layout.percent_y =
    Layout.progress_y +
    Layout.progress_h +
    11

--------------------------------------------------------
-- Boot log
--------------------------------------------------------

Layout.dataloading_y =
    Layout.percent_y +
    23

Layout.dataloading_h =
    103

Layout.dataloading_end =
    Layout.dataloading_y +
    Layout.dataloading_h

--------------------------------------------------------
-- Banter
--------------------------------------------------------

Layout.banter_y =
    Layout.dataloading_end +
    8

Layout.banter_h =
    18

Layout.banter_end =
    Layout.banter_y +
    Layout.banter_h

--------------------------------------------------------
-- Final loader status
--------------------------------------------------------

Layout.status2_y =
    Layout.banter_end +
    10

Layout.status_h =
    31

Layout.window_end =
    Layout.status2_y +
    Layout.status_h

--------------------------------------------------------
-- Settings
--------------------------------------------------------

Layout.settings_title_y =
    Layout.header_end +
    22

Layout.settings_start_y =
    Layout.settings_title_y +
    42

Layout.settings_row_h =
    34

Layout.settings_gap =
    9

Layout.settings_end =
    Layout.settings_start_y +
    #CONFIG.controls *
    (
        Layout.settings_row_h +
        Layout.settings_gap
    )

Layout.settings_hint_y =
    Layout.settings_end +
    4

local required_height =
    Layout.window_end -
    y0 +
    10

UI.h =
    max(
        CONFIG.height,
        required_height
    )

end



local function draw_header()

local x =
    UI.x

local y =
    UI.y

local w =
    UI.w

local h =
    CONFIG.header_height

--------------------------------------------------------
-- Main panel shadow.
--------------------------------------------------------

draw.ShadowRect(
    x,
    y,
    x + w,
    y + UI.h,
    20
)

--------------------------------------------------------
-- Header.
--------------------------------------------------------

rounded_fill(
    x,
    y,
    x + w,
    y + h,
    CONFIG.radius,
    CONFIG.colors.header
)

fill_rect(
    x,
    y + h - 5,
    x + w,
    y + h,
    CONFIG.colors.header
)

fill_rect(
    x,
    y + h - 1,
    x + w,
    y + h,
    CONFIG.colors.border
)

--------------------------------------------------------
-- Accent logo.
--------------------------------------------------------

local logo_x =
    x + 10

local logo_y =
    y + 7

local logo_s =
    18

rounded_fill(
    logo_x,
    logo_y,
    logo_x + logo_s,
    logo_y + logo_s,
    3,
    CONFIG.colors.accent
)

draw_text_centered_box(
    Fonts.icon,
    logo_x,
    logo_y,
    logo_s,
    logo_s,
    "F",
    CONFIG.colors.background
)

--------------------------------------------------------
-- Product.
--------------------------------------------------------

draw_text_vcentered(
    Fonts.body,
    logo_x + logo_s + 8,
    y,
    h,
    "ForwardTrack",
    CONFIG.colors.text
)

local product_w =
    text_size(
        Fonts.body,
        "ForwardTrack"
    )

draw_text_vcentered(
    Fonts.info,
    logo_x +
    logo_s +
    8 +
    product_w +
    6,
    y,
    h,
    "loader",
    CONFIG.colors.muted
)

--------------------------------------------------------
-- Header welcome.
--------------------------------------------------------

local welcome =
    "Welcome Bacak <3"

local close_w =
    28

local close_x =
    x + w -
    close_w

local gear_w =
    28

local gear_x =
    close_x -
    gear_w -
    2

local welcome_w =
    text_size(
        Fonts.info,
        welcome
    )

draw_text_vcentered(
    Fonts.info,
    gear_x -
    welcome_w -
    10,
    y,
    h,
    welcome,
    CONFIG.colors.muted
)

--------------------------------------------------------
-- Gear.
--------------------------------------------------------

if UI.gear_hover then

    fill_rect(
        gear_x,
        y,
        gear_x + gear_w,
        y + h - 1,
        CONFIG.colors.panel_light
    )
end

local gx =
    gear_x +
    gear_w * 0.5

local gy =
    y +
    h * 0.5

local gear_color =
    UI.view == "settings"
    and CONFIG.colors.accent
    or (
        UI.gear_hover
        and CONFIG.colors.accent
        or CONFIG.colors.muted
    )

set_color(
    gear_color
)

draw.FilledCircle(
    gx,
    gy,
    6
)

set_color(
    CONFIG.colors.header
)

draw.FilledCircle(
    gx,
    gy,
    3
)

set_color(
    gear_color
)

for i = 0, 3 do

    local angle =
        i *
        90 *
        math.pi /
        180

    draw.Line(
        gx +
        cos(angle) * 7,

        gy +
        sin(angle) * 7,

        gx +
        cos(angle) * 9,

        gy +
        sin(angle) * 9
    )
end

--------------------------------------------------------
-- Close.
--------------------------------------------------------

if UI.close_hover then

    fill_rect(
        close_x,
        y,
        close_x + close_w,
        y + h - 1,
        CONFIG.colors.button_hover
    )
end

draw_text_centered_box(
    Fonts.body,
    close_x,
    y,
    close_w,
    h,
    "x",
    UI.close_hover
    and CONFIG.colors.text
    or CONFIG.colors.muted
)

end



local function draw_information()

local center_x =
    UI.x +
    UI.w * 0.5

draw_text_centered(
    Fonts.title,
    center_x,
    Layout.title_y,
    "ForwardTrack.fck",
    CONFIG.colors.text
)

local title_w =
    text_size(
        Fonts.title,
        "ForwardTrack.fck"
    )

fill_rect(
    center_x -
    title_w * 0.5,
    Layout.title_y + 25,
    center_x +
    title_w * 0.5,
    Layout.title_y + 26,
    CONFIG.colors.accent,
    110
)

local rows = {

    {
        "Version:",
        CONFIG.version
    },

    {
        "Build date:",
        CONFIG.build_date
    },

    {
        "Build type:",
        CONFIG.build_type
    },

    {
        "Registered to:",
        CONFIG.registered_to
    }
}

for i, row in
    ipairs(rows) do

    local row_y =
        Layout.info_y +
        (i - 1) *
        Layout.info_row_h

    draw_centered_kv(
        Fonts.info,
        center_x,
        row_y,
        row[1],
        CONFIG.colors.muted,
        row[2],
        CONFIG.colors.accent
    )
end

fill_rect(
    UI.x +
    Layout.pad_x,

    Layout.divider_y,

    UI.x +
    Layout.pad_x +
    Layout.content_w,

    Layout.divider_y + 1,

    CONFIG.colors.border
)

end



local function draw_status_bar()

local x =
    UI.x +
    Layout.pad_x

local y =
    Layout.status_bar_y

local w =
    Layout.content_w

local h =
    Layout.status_bar_h

rounded_fill(
    x,
    y,
    x + w,
    y + h,
    6,
    CONFIG.colors.panel
)

rounded_outline(
    x,
    y,
    x + w,
    y + h,
    6,
    CONFIG.colors.border
)

local online =
    CONFIG.controls[2].state

local secure =
    CONFIG.controls[1].state

local loaded =
    Loader.state ==
    "LOADED"

local entries = {

    {
        label =
            online
            and "ONLINE"
            or "OFFLINE",

        color =
            online
            and CONFIG.colors.accent
            or CONFIG.colors.red
    },

    {
        label =
            not secure
            and "INSECURE"
            or (
                loaded
                and "SECURE"
                or "VERIFYING"
            ),

        color =
            not secure
            and CONFIG.colors.red
            or (
                loaded
                and CONFIG.colors.accent
                or CONFIG.colors.orange
            )
    },

    {
        label =
            loaded
            and "TO DATE"
            or "CHECKING",

        color =
            loaded
            and CONFIG.colors.accent
            or CONFIG.colors.orange
    }
}

local gap =
    7

local pad =
    7

local pill_w =
    floor(
        (
            w -
            pad * 2 -
            gap * 2
        ) / 3
    )

local pill_h =
    h - 10

for i = 1, 3 do

    local entry =
        entries[i]

    local px =
        x +
        pad +
        (i - 1) *
        (
            pill_w +
            gap
        )

    local py =
        y + 5

    rounded_fill(
        px,
        py,
        px + pill_w,
        py + pill_h,
        pill_h * 0.5,
        entry.color,
        18
    )

    rounded_outline(
        px,
        py,
        px + pill_w,
        py + pill_h,
        pill_h * 0.5,
        entry.color,
        125
    )

    set_color(
        entry.color
    )

    draw.FilledCircle(
        px + 9,
        py +
        pill_h * 0.5,
        3
    )

    draw_text_centered(
        Fonts.small,
        px +
        pill_w * 0.5 +
        3,
        py + 4,
        entry.label,
        CONFIG.colors.text
    )
end

draw_text_centered(
    Fonts.small,
    x + w * 0.5,
    Layout.status_tag_y,
    "— SYSTEM STATUS —",
    CONFIG.colors.muted_dark
)

end



local function draw_loader_options()

local card_w =
    98

local card_gap =
    7

local count =
    3

local total_w =
    count * card_w +
    (
        count - 1
    ) *
    card_gap

local x0 =
    floor(
        UI.x +
        (
            UI.w -
            total_w
        ) * 0.5
    )

draw_text_centered(
    Fonts.small,
    UI.x +
    UI.w * 0.5,
    Layout.options_tag_y,
    "LOADER OPTIONS",
    CONFIG.colors.muted_dark
)

for i = 1, count do

    local ctrl =
        CONFIG.controls[i]

    local cx =
        x0 +
        (i - 1) *
        (
            card_w +
            card_gap
        )

    local cy =
        Layout.options_y

    local hovered =
        UI.ctrl_hover == i

    local background =
        ctrl.state
        and (
            hovered
            and CONFIG.colors.panel_active
            or CONFIG.colors.panel
        )
        or (
            hovered
            and CONFIG.colors.panel_light
            or CONFIG.colors.panel
        )

    local border =
        ctrl.state
        and CONFIG.colors.accent_dim
        or CONFIG.colors.border

    rounded_fill(
        cx,
        cy,
        cx + card_w,
        cy + Layout.options_h,
        6,
        background
    )

    rounded_outline(
        cx,
        cy,
        cx + card_w,
        cy + Layout.options_h,
        6,
        border,
        hovered
        and 220
        or 150
    )

    ----------------------------------------------------
    -- Indicator
    ----------------------------------------------------

    local dot_x =
        cx + 10

    local dot_y =
        cy +
        Layout.options_h *
        0.5

    set_color(
        ctrl.state
        and CONFIG.colors.accent
        or CONFIG.colors.muted_dark
    )

    draw.FilledCircle(
        dot_x,
        dot_y,
        3
    )

    ----------------------------------------------------
    -- Label
    ----------------------------------------------------

    local label =
        truncate_text(
            Fonts.small,
            ctrl.label,
            54
        )

    draw_text_vcentered(
        Fonts.small,
        cx + 18,
        cy,
        Layout.options_h,
        label,
        ctrl.state
        and CONFIG.colors.text
        or CONFIG.colors.muted
    )

    ----------------------------------------------------
    -- State
    ----------------------------------------------------

    draw_text_centered(
        Fonts.small,
        cx +
        card_w -
        17,
        cy + 10,
        ctrl.state
        and "ON"
        or "OFF",
        ctrl.state
        and CONFIG.colors.accent
        or CONFIG.colors.muted_dark
    )
end

end



local function draw_load_button()

local bx =
    UI.x +
    Layout.pad_x

local by =
    Layout.button_y

local bw =
    Layout.content_w

local bh =
    Layout.button_h

local t =
    UI.hover_anim

local base =
    CONFIG.colors.button

local hover =
    CONFIG.colors.button_hover

local background = {

    floor(
        lerp(
            base[1],
            hover[1],
            t
        )
    ),

    floor(
        lerp(
            base[2],
            hover[2],
            t
        )
    ),

    floor(
        lerp(
            base[3],
            hover[3],
            t
        )
    ),

    255
}

if UI.load_pressed then

    background =
        CONFIG.colors.button_pressed
end

rounded_fill(
    bx + 1,
    by + 2,
    bx + bw + 1,
    by + bh + 2,
    6,
    CONFIG.colors.shadow,
    35
)

rounded_fill(
    bx,
    by,
    bx + bw,
    by + bh,
    6,
    background
)

rounded_outline(
    bx,
    by,
    bx + bw,
    by + bh,
    6,
    CONFIG.colors.border
)

fill_rect(
    bx + 7,
    by + bh - 1,
    bx + bw - 7,
    by + bh,
    CONFIG.colors.accent,
    Loader.state ==
        "READY"
        and floor(
            130 +
            60 *
            UI.hover_anim
        )
        or 120
)

local text

if Loader.state ==
    "READY" then

    text =
        "LOAD"

elseif Loader.state ==
    "LOADING" then

    text =
        "LOADING..."

else

    text =
        "LOADED!"
end

local tw, th =
    text_size(
        Fonts.body,
        text
    )

local tx =
    bx +
    (
        bw -
        tw
    ) * 0.5

local ty =
    by +
    (
        bh -
        th
    ) * 0.5

draw_text(
    Fonts.body,
    tx,
    ty,
    text,
    CONFIG.colors.accent
)

--------------------------------------------------------
-- Loading spinner
--------------------------------------------------------

if Loader.state ==
    "LOADING" then

    local spinner_x =
        tx - 17

    local spinner_y =
        by +
        bh * 0.5

    local spinner_r =
        7

    set_color(
        CONFIG.colors.progress_bg
    )

    draw.OutlinedCircle(
        spinner_x,
        spinner_y,
        spinner_r
    )

    local angle =
        Timing.time * 6

    set_color(
        CONFIG.colors.accent
    )

    draw.FilledCircle(
        spinner_x +
        cos(angle) *
        (
            spinner_r - 1
        ),

        spinner_y +
        sin(angle) *
        (
            spinner_r - 1
        ),

        2
    )
end

--------------------------------------------------------
-- Loaded state
--------------------------------------------------------

if Loader.state ==
    "LOADED" then

    local check_x =
        tx - 17

    local check_y =
        by +
        bh * 0.5

    set_color(
        CONFIG.colors.accent
    )

    draw.FilledCircle(
        check_x,
        check_y,
        7
    )

    draw_text_centered(
        Fonts.small,
        check_x,
        check_y - 6,
        "✓",
        CONFIG.colors.background
    )
end

end



local function draw_progress()

if Loader.state ==
    "READY" then

    return
end

local x =
    UI.x +
    Layout.pad_x

local y =
    Layout.progress_y

local w =
    Layout.content_w

local h =
    Layout.progress_h

local progress =
    clamp(
        UI.progress_visual,
        0,
        1
    )

--------------------------------------------------------
-- Background
--------------------------------------------------------

rounded_fill(
    x,
    y,
    x + w,
    y + h,
    h * 0.5,
    CONFIG.colors.progress_bg
)

rounded_outline(
    x,
    y,
    x + w,
    y + h,
    h * 0.5,
    CONFIG.colors.border
)

--------------------------------------------------------
-- Fill
--------------------------------------------------------

local fill_w =
    floor(
        w * progress
    )

if fill_w > 0 then

    rounded_fill(
        x,
        y,
        x + fill_w,
        y + h,
        h * 0.5,
        CONFIG.colors.accent
    )

    if Loader.state ==
        "LOADING"
        and fill_w > 12 then

        set_color(
            CONFIG.colors.accent,
            35
        )

        draw.FilledCircle(
            x + fill_w,
            y + h * 0.5,
            6
        )
    end
end

--------------------------------------------------------
-- Percentage
--------------------------------------------------------

local percent =
    floor(
        progress * 100 +
        0.5
    )

draw_text_centered(
    Fonts.info,
    x + w * 0.5,
    Layout.percent_y,
    tostring(percent) ..
    "%",
    CONFIG.colors.muted
)

--------------------------------------------------------
-- Stage
--------------------------------------------------------

local stage = ""

if Loader.state ==
    "LOADING" then

    local idx =
        clamp(
            Loader.phase_index,
            1,
            #phases
        )

    stage =
        phases[idx].name

elseif Loader.state ==
    "LOADED" then

    stage =
        "All systems initialized"
end

if stage ~= "" then

    draw_text_centered(
        Fonts.small,
        x + w * 0.5,
        Layout.stage_y,
        truncate_text(
            Fonts.small,
            stage,
            w
        ),
        CONFIG.colors.muted_dark
    )
end

end



local function draw_boot_log()

if Loader.state ==
    "READY" then

    return
end

local x =
    UI.x +
    Layout.pad_x

local y =
    Layout.dataloading_y

local w =
    Layout.content_w

local h =
    Layout.dataloading_h

rounded_fill(
    x,
    y,
    x + w,
    y + h,
    6,
    CONFIG.colors.logger_bg
)

rounded_outline(
    x,
    y,
    x + w,
    y + h,
    6,
    CONFIG.colors.border
)

--------------------------------------------------------
-- Header
--------------------------------------------------------

fill_rect(
    x,
    y,
    x + w,
    y + 20,
    CONFIG.colors.header
)

fill_rect(
    x,
    y + 19,
    x + w,
    y + 20,
    CONFIG.colors.border
)

draw_text_centered(
    Fonts.small,
    x + w * 0.5,
    y + 5,
    "BOOT LOG",
    CONFIG.colors.muted_dark
)

--------------------------------------------------------
-- Activity dots
--------------------------------------------------------

local dot_alpha =
    Loader.state ==
    "LOADING"
    and floor(
        150 +
        70 *
        UI.pulse
    )
    or 100

set_color(
    CONFIG.colors.accent,
    dot_alpha
)

draw.FilledCircle(
    x + 10,
    y + 10,
    2
)

draw.FilledCircle(
    x + w - 10,
    y + 10,
    2
)

--------------------------------------------------------
-- Log lines
--------------------------------------------------------

local count =
    min(
        #Loader.logger,
        6
    )

for i = 1, count do

    local entry =
        Loader.logger[
            #Loader.logger -
            count +
            i
        ]

    local color =
        logger_color(
            entry.level
        )

    local alpha_scale =
        0.55 +
        0.45 *
        (
            i /
            max(
                count,
                1
            )
        )

    local line_color = {

        color[1],
        color[2],
        color[3],
        floor(
            (
                color[4] or 255
            ) *
            alpha_scale
        )
    }

    local line_y =
        y +
        29 +
        (
            i - 1
        ) *
        13

    draw_text(
        Fonts.mono,
        x + 9,
        line_y,
        truncate_text(
            Fonts.mono,
            "> " ..
            entry.message,
            w - 18
        ),
        line_color
    )
end

end



local function draw_banter()

if Loader.state ==
    "READY" then

    return
end

local x =
    UI.x +
    Layout.pad_x

local y =
    Layout.banter_y

local w =
    Layout.content_w

local h =
    Layout.banter_h

rounded_fill(
    x,
    y,
    x + w,
    y + h,
    4,
    CONFIG.colors.panel,
    180
)

rounded_outline(
    x,
    y,
    x + w,
    y + h,
    4,
    CONFIG.colors.border,
    90
)

local alpha =
    floor(
        185 +
        30 *
        UI.pulse
    )

draw_text_centered(
    Fonts.small,
    x + w * 0.5,
    y + 4,
    truncate_text(
        Fonts.small,
        UI.banter_text,
        w - 12
    ),
    CONFIG.colors.troll,
    alpha
)

end



local function draw_loader_status()

local x =
    UI.x +
    Layout.pad_x

local y =
    Layout.status2_y

local w =
    Layout.content_w

local h =
    Layout.status_h

rounded_fill(
    x,
    y,
    x + w,
    y + h,
    6,
    CONFIG.colors.panel
)

rounded_outline(
    x,
    y,
    x + w,
    y + h,
    6,
    CONFIG.colors.border
)

local status
local message
local color

if Loader.state ==
    "READY" then

    status =
        "READY"

    message =
        "Waiting for user input"

    color =
        CONFIG.colors.muted

elseif Loader.state ==
    "LOADING" then

    status =
        "LOADING"

    message =
        "Initialization in progress"

    color =
        CONFIG.colors.accent

elseif Loader.state ==
    "LOADED" then

    status =
        "LOADED"

    message =
        "All systems initialized"

    color =
        CONFIG.colors.accent

else

    status =
        tostring(
            Loader.state
        )

    message =
        "Unknown loader state"

    color =
        CONFIG.colors.red
end

--------------------------------------------------------
-- Indicator
--------------------------------------------------------

if Loader.state ==
    "LOADING" then

    set_color(
        color,
        floor(
            70 +
            60 *
            UI.pulse
        )
    )

    draw.FilledCircle(
        x + 12,
        y + h * 0.5,
        7
    )
end

set_color(
    color
)

draw.FilledCircle(
    x + 12,
    y + h * 0.5,
    3
)

--------------------------------------------------------
-- Text
--------------------------------------------------------

draw_text_vcentered(
    Fonts.info,
    x + 22,
    y,
    h,
    status,
    color
)

draw_text_vcentered(
    Fonts.small,
    x + 105,
    y,
    h,
    message,
    CONFIG.colors.muted_dark
)

end



local function draw_settings()

local x =
    UI.x +
    Layout.pad_x

local y =
    Layout.header_end +
    10

local w =
    Layout.content_w

local h =
    UI.h -
    (
        Layout.header_end -
        UI.y
    ) -
    20

rounded_fill(
    x,
    y,
    x + w,
    y + h,
    6,
    CONFIG.colors.panel
)

rounded_outline(
    x,
    y,
    x + w,
    y + h,
    6,
    CONFIG.colors.border
)

draw_text_centered(
    Fonts.title,
    UI.x +
    UI.w * 0.5,
    Layout.settings_title_y,
    "Loader Settings",
    CONFIG.colors.text
)

draw_text_centered(
    Fonts.small,
    UI.x +
    UI.w * 0.5,
    Layout.settings_title_y + 26,
    "configure loader behaviour",
    CONFIG.colors.muted_dark
)

fill_rect(
    x + 20,
    Layout.settings_title_y + 37,
    x + w - 20,
    Layout.settings_title_y + 38,
    CONFIG.colors.border
)

--------------------------------------------------------
-- Rows
--------------------------------------------------------

local row_w =
    275

local row_h =
    Layout.settings_row_h

local row_x =
    floor(
        UI.x +
        (
            UI.w -
            row_w
        ) * 0.5
    )

for i, ctrl in
    ipairs(
        CONFIG.controls
    ) do

    local row_y =
        Layout.settings_start_y +
        (i - 1) *
        (
            row_h +
            Layout.settings_gap
        )

    local hovered =
        UI.settings_hover == i

    local bg =
        hovered
        and CONFIG.colors.panel_light
        or CONFIG.colors.background_2

    rounded_fill(
        row_x,
        row_y,
        row_x + row_w,
        row_y + row_h,
        6,
        bg
    )

    rounded_outline(
        row_x,
        row_y,
        row_x + row_w,
        row_y + row_h,
        6,
        hovered
        and CONFIG.colors.border_light
        or CONFIG.colors.border
    )

    draw_text_vcentered(
        Fonts.info,
        row_x + 12,
        row_y,
        row_h,
        ctrl.label,
        CONFIG.colors.text
    )

    ----------------------------------------------------
    -- Toggle
    ----------------------------------------------------

    local toggle_w =
        48

    local toggle_h =
        18

    local tx =
        row_x +
        row_w -
        toggle_w -
        10

    local ty =
        row_y +
        (
            row_h -
            toggle_h
        ) * 0.5

    local track =
        ctrl.state
        and CONFIG.colors.accent_dim
        or CONFIG.colors.background

    rounded_fill(
        tx,
        ty,
        tx + toggle_w,
        ty + toggle_h,
        toggle_h * 0.5,
        track
    )

    rounded_outline(
        tx,
        ty,
        tx + toggle_w,
        ty + toggle_h,
        toggle_h * 0.5,
        ctrl.state
        and CONFIG.colors.accent
        or CONFIG.colors.border,
        190
    )

    local knob_x =
        ctrl.state
        and (
            tx +
            toggle_w -
            8
        )
        or (
            tx + 8
        )

    set_color(
        ctrl.state
        and CONFIG.colors.accent
        or CONFIG.colors.muted
    )

    draw.FilledCircle(
        knob_x,
        ty +
        toggle_h * 0.5,
        6
    )
end

--------------------------------------------------------
-- Footer hint
--------------------------------------------------------

draw_text_centered(
    Fonts.small,
    UI.x +
    UI.w * 0.5,
    Layout.settings_hint_y,
    "changes saved to forwardtrack_loader.txt",
    CONFIG.colors.muted_dark
)

draw_text_centered(
    Fonts.small,
    UI.x +
    UI.w * 0.5,
    Layout.settings_hint_y + 15,
    "click the gear to return",
    CONFIG.colors.accent
)

end



local function on_draw()

if not MENU_REFERENCE:GetValue() then
    return
end

if not UI.visible then
    return
end

update_timing()

update_layout()

local mx, my =
    input.GetMousePos()

update_drag(
    mx,
    my
)

update_input(
    mx,
    my
)

update_loading()

update_visuals()

--------------------------------------------------------
-- Render
--------------------------------------------------------

draw_header()

if UI.view ==
    "settings" then

    draw_settings()

    return
end

draw_information()

draw_load_button()

draw_status_bar()

draw_loader_options()

draw_progress()

draw_boot_log()

draw_banter()

draw_loader_status()

end



local function on_unload()

UI.dragging =
    false

UI.visible =
    false

Loader.state =
    "READY"

Loader.progress =
    0

Loader.logger =
    {}

Loader.handoff_started =
    false

end



math.randomseed(
floor(
common.Time() *
100000
) %
2147483647
)

init_fonts()

load_loader_settings()

update_layout()

logger_add(
"Loader ready. Awaiting input.",
"OK"
)



callbacks.Register(
"Draw",
"Mictian_Loader_v032_Draw",
on_draw
)

callbacks.Register(
"Unload",
"Mictian_Loader_v032_Unload",
on_unload
)

