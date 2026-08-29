local menu_open = gui.Reference("MENU")

-- Konfigurace a stav okna
local ui = {
    x = 300, y = 200, w = 340, h = 480,
    dragging = false, drag_x = 0, drag_y = 0
}

local settings = { auto_save = true }

-- Pomocná funkce pro kolize myši
local function in_bounds(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local function on_draw()
    if not menu_open:GetValue() then return end

    local mx, my = input.GetMousePos()
    local m_down = input.IsButtonDown(1)
    local m_pressed = input.IsButtonPressed(1)

    -- 1. Logika pro přesouvání okna (chytnutí za horní lištu 30px)
    if m_down and in_bounds(mx, my, ui.x, ui.y, ui.w, 30) and not ui.dragging then
        ui.dragging = true
        ui.drag_x, ui.drag_y = mx - ui.x, my - ui.y
    elseif not m_down then
        ui.dragging = false
    end

    if ui.dragging then
        ui.x, ui.y = mx - ui.drag_x, my - ui.drag_y
    end

    -- 2. Vykreslení pozadí a hlavičky
    draw.Color(18, 18, 18, 255)
    draw.FilledRect(ui.x, ui.y, ui.x + ui.w, ui.y + ui.h)

    draw.Color(24, 24, 24, 255)
    draw.FilledRect(ui.x, ui.y, ui.x + ui.w, ui.y + 30)

    draw.Color(240, 240, 240, 255)
    draw.Text(ui.x + 12, ui.y + 8, "Welcome Bacak <3")
    draw.Color(150, 150, 150, 255)
    draw.Text(ui.x + ui.w - 20, ui.y + 8, "X")

    -- Nadpis a Info texty
    draw.Color(240, 240, 240, 255)
    draw.Text(ui.x + 25, ui.y + 50, "ForwardTrack.fck")

    local info_y = ui.y + 100
    local labels = {
        {"Version:", "1.0.0"},
        {"Build date:", "Aug 14 2021"},
        {"Build type:", "x64"},
        {"Registered to:", "Andrus"}
    }

    for i, line in ipairs(labels) do
        draw.Color(240, 240, 240, 255)
        draw.Text(ui.x + 25, info_y + (i - 1) * 22, line[1])
        draw.Color(118, 210, 0, 255)
        draw.Text(ui.x + 130, info_y + (i - 1) * 22, line[2])
    end

    -- Tlačítko LOAD s Hover efektem
    local btn_y = info_y + 100
    local btn_hover = in_bounds(mx, my, ui.x + 25, btn_y, ui.w - 50, 35)
    
    if btn_hover then draw.Color(50, 50, 50, 255) else draw.Color(30, 30, 30, 255) end
    draw.FilledRect(ui.x + 25, btn_y, ui.x + ui.w - 25, btn_y + 35)
    draw.Color(118, 210, 0, 255)
    draw.Text(ui.x + (ui.w / 2) - 15, btn_y + 10, "Load")

    -- 3. Oddělovač a Auto Save Toggle s interakcí
    draw.Color(35, 35, 35, 255)
    draw.Line(ui.x + 10, btn_y + 50, ui.x + ui.w - 10, btn_y + 50)

    local toggle_y = btn_y + 70
    draw.Color(240, 240, 240, 255)
    draw.Text(ui.x + 25, toggle_y, "Auto save")

    -- Interakce kliknutí na toggle
    if m_pressed and in_bounds(mx, my, ui.x + ui.w - 60, toggle_y, 40, 16) then
        settings.auto_save = not settings.auto_save
    end

    -- Vykreslení toggle
    if settings.auto_save then
        draw.Color(118, 210, 0, 255) -- Zelená (Zapnuto)
        draw.FilledRect(ui.x + ui.w - 55, toggle_y, ui.x + ui.w - 25, toggle_y + 14)
    else
        draw.Color(60, 60, 60, 255) -- Šedá (Vypnuto)
        draw.FilledRect(ui.x + ui.w - 55, toggle_y, ui.x + ui.w - 25, toggle_y + 14)
    end
end

callbacks.Register("Draw", on_draw)