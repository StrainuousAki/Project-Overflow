------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/render/renderer.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — Overflow HUD Renderer
--
-- Draws the additional health rings over the native RE4 Remake
-- health gauge. Geometry is recalculated from the live resolution,
-- and visibility follows VitalGuiBehavior's confirmed WaitEnd state.
------------------------------------------------------------

local overlay = {}
local ring = require("project_overflow.render.ring")

local function apply_alpha(color, alpha)
    alpha = math.max(
        0.0,
        math.min(tonumber(alpha) or 0.0, 1.0)
    )

    local original_alpha =
        math.floor(color / 0x1000000) % 0x100

    local rgb =
        color % 0x1000000

    local faded_alpha =
        math.floor(original_alpha * alpha)

    return faded_alpha * 0x1000000 + rgb
end

local function clamp01(value)
    value = tonumber(value) or 0.0

    return math.max(
        0.0,
        math.min(value, 1.0)
    )
end

local function get_preview_pulse_alpha(ctx)
    if ctx.state.overlay_preview_pulse_enabled ~= true then
        return 1.0
    end

    local hold_time =
        math.max(
            0.0,
            tonumber(ctx.state.overlay_preview_pulse_hold) or 0.50
        )

    local fade_time =
        math.max(
            0.001,
            tonumber(ctx.state.overlay_preview_pulse_fade) or 0.35
        )

    local full_alpha =
        clamp01(ctx.state.overlay_preview_pulse_full_alpha)

    local low_alpha =
        clamp01(ctx.state.overlay_preview_pulse_low_alpha)

    local fade_out_end =
        hold_time + fade_time

    local fade_in_end =
        fade_out_end + fade_time

    local cycle_length =
        fade_in_end

    local pulse_time =
        tonumber(ctx.state.overlay_preview_pulse_time) or 0.0

    local cycle_time =
        pulse_time % cycle_length

    if cycle_time < hold_time then
        return full_alpha
    end

    if cycle_time < fade_out_end then
        local t =
            (cycle_time - hold_time) /
            fade_time

        return
            full_alpha +
            (low_alpha - full_alpha) * t
    end

    local t =
        (cycle_time - fade_out_end) /
        fade_time

    return
        low_alpha +
        (full_alpha - low_alpha) * t
end

local function get_ratio_on_ring(
    ctx,
    total_hp,
    ring_index
)
    local overflow_start =
        tonumber(ctx.state.overflow_start_hp) or 2520.0

    local ring_capacity =
        tonumber(ctx.state.overflow_ring_hp) or 2520.0

    if ring_capacity <= 0.0 then
        ring_capacity = 2520.0
    end

    ring_index =
        math.max(
            0,
            tonumber(ring_index) or 0
        )

    local overflow_hp =
        math.max(
            0.0,
            (tonumber(total_hp) or 0.0) -
            overflow_start
        )

    local ring_start_hp =
        ring_index *
        ring_capacity

    local hp_on_ring =
        overflow_hp -
        ring_start_hp

    if hp_on_ring >= ring_capacity then
        return 1.0
    end

    if hp_on_ring <= 0.0 then
        return 0.0
    end

    return clamp01(
        hp_on_ring /
        ring_capacity
    )
end

local function get_ring_position(ctx, total_hp)
    local overflow_start =
        tonumber(ctx.state.overflow_start_hp) or 2520.0

    local ring_capacity =
        tonumber(ctx.state.overflow_ring_hp) or 2520.0

    if ring_capacity <= 0.0 then
        ring_capacity = 2520.0
    end

    local overflow_hp =
        math.max(
            0.0,
            (tonumber(total_hp) or 0.0) -
            overflow_start
        )

    local ring_index =
        math.floor(
            overflow_hp /
            ring_capacity
        )

    local hp_on_ring =
        overflow_hp -
        (ring_index * ring_capacity)

    -- Exact boundaries belong to the completed previous ring.
    if
        overflow_hp > 0.0 and
        hp_on_ring == 0.0
    then
        ring_index =
            math.max(
                0,
                ring_index - 1
            )

        hp_on_ring =
            ring_capacity
    end

    return
        ring_index,
        clamp01(
            hp_on_ring /
            ring_capacity
        )
end

local function finite_number(value, fallback)
    value = tonumber(value)

    if value == nil then
        return fallback or 0.0
    end

    -- NaN is the only Lua number not equal to itself.
    if value ~= value then
        return fallback or 0.0
    end

    -- Reject infinities and absurd renderer values.
    if value > 1000000.0 or value < -1000000.0 then
        return fallback or 0.0
    end

    return value
end

local function clamp_signed_sweep(value, max_sweep)
    value =
        finite_number(
            value,
            0.0
        )

    max_sweep =
        math.abs(
            finite_number(
                max_sweep,
                270.0
            )
        )

    return math.max(
        -max_sweep,
        math.min(
            value,
            max_sweep
        )
    )
end

local function get_ring_style(ctx, ring_index)
    local styles = ctx.ring_styles or {}
    if #styles == 0 then return nil end
    local index = math.max(1, math.min(math.floor(tonumber(ring_index) or 0) + 1, #styles))
    local style = styles[index]
    if style == nil or style.enabled == false then return nil end
    return style
end

local function sc(style, prefix, channel, fallback)
    if style == nil then return fallback end
    local value = tonumber(style[prefix .. "_" .. channel])
    if value == nil then return fallback end
    return math.max(0, math.min(value, 255))
end

local function pack_style(ctx, style, prefix, fr, fg, fb, fa, alpha_override)
    local alpha = alpha_override
    if alpha == nil then alpha = sc(style, prefix, "a", fa) end
    return ctx.rgba_to_u32(
        sc(style, prefix, "r", fr),
        sc(style, prefix, "g", fg),
        sc(style, prefix, "b", fb),
        alpha
    )
end

local function read_display_component(value, key, index)
    if value == nil then return nil end

    local result = nil
    pcall(function() result = value[key] end)

    if result ~= nil then
        return tonumber(result)
    end

    pcall(function() result = value[index] end)
    return tonumber(result)
end

local function query_live_display_size()
    local attempts = {
        {
            name = "imgui.get_display_size",
            call = function()
                if imgui.get_display_size == nil then return nil end
                return imgui.get_display_size()
            end
        },
        {
            name = "imgui.get_io().display_size",
            call = function()
                if imgui.get_io == nil then return nil end
                local io = imgui.get_io()
                if io == nil then return nil end
                return io.display_size
            end
        }
    }

    local last_error = ""

    for _, attempt in ipairs(attempts) do
        local ok, value = pcall(attempt.call)

        if ok and value ~= nil then
            local width = read_display_component(value, "x", 1)
            local height = read_display_component(value, "y", 2)

            if
                width ~= nil and height ~= nil and
                width > 0.0 and height > 0.0
            then
                return width, height, attempt.name, ""
            end
        elseif not ok then
            last_error = tostring(value)
        end
    end

    return nil, nil, "unavailable", last_error
end

local function refresh_live_resolution(ctx)
    local width, height, source, error_text =
        query_live_display_size()

    if width == nil or height == nil then
        ctx.screen.last_resolution_error =
            error_text ~= ""
            and error_text
            or "No supported display-size API returned a valid size."

        return false
    end

    local old_width = tonumber(ctx.screen.width) or width
    local old_height = tonumber(ctx.screen.height) or height

    local changed =
        math.abs(width - old_width) > 0.5 or
        math.abs(height - old_height) > 0.5

    ctx.screen.previous_width = old_width
    ctx.screen.previous_height = old_height
    ctx.screen.width = width
    ctx.screen.height = height
    ctx.screen.resolution_changed = changed

    if changed then
        ctx.screen.resolution_change_count =
            (tonumber(ctx.screen.resolution_change_count) or 0) + 1
    end

    ctx.screen.last_resolution_source = source
    ctx.screen.last_resolution_error = ""

    return true
end

-- Re-read the live display size before calculating the HUD center.
-- This prevents the overlay from staying at an old resolution.
local function get_scaled_geometry(ctx)
    refresh_live_resolution(ctx)

    local reference_width =
        tonumber(ctx.state.overlay_reference_width) or 2560.0

    local reference_height =
        tonumber(ctx.state.overlay_reference_height) or 1440.0

    local screen_width =
        tonumber(ctx.screen.width) or reference_width

    local screen_height =
        tonumber(ctx.screen.height) or reference_height

    local scale_x =
        screen_width / reference_width

    local scale_y =
        screen_height / reference_height

    local uniform_scale =
        math.min(scale_x, scale_y)

    local reference_x =
        tonumber(ctx.state.overlay_reference_x) or 2283.3

    local reference_y =
        tonumber(ctx.state.overlay_reference_y) or 1164.6

    local reference_radius =
        tonumber(ctx.state.overlay_reference_radius) or 84.2

    local right_offset =
        reference_width - reference_x

    local bottom_offset =
        reference_height - reference_y

    local cx =
        screen_width - (right_offset * uniform_scale)

    local cy =
        screen_height - (bottom_offset * uniform_scale)

    local radius =
        math.max(
            1.0,
            reference_radius *
            uniform_scale
        )

    local thickness =
        math.max(
            1.0,
            (tonumber(ctx.state.overlay_thickness) or 10.0) *
            uniform_scale
        )

    ctx.state.overlay_geometry_radius =
        radius

    ctx.screen.scale_x = scale_x
    ctx.screen.scale_y = scale_y
    ctx.screen.uniform_scale = uniform_scale
    ctx.screen.computed_center_x = cx
    ctx.screen.computed_center_y = cy
    ctx.screen.computed_radius = radius
    ctx.screen.computed_thickness = thickness

    return cx, cy, radius, thickness
end

local function get_colors(ctx, fade_alpha, active_ring_index)
    local style = get_ring_style(ctx, active_ring_index)

    local configured_bg_alpha =
        sc(style, "bg", "a", tonumber(ctx.ui.overlay_bg_a) or 100)

    local current_hp =
        tonumber(ctx.state.current_hp) or 0.0

    local current_max_hp =
        tonumber(ctx.state.max_hp) or 0.0

    local background_threshold =
        tonumber(ctx.state.overlay_bg_alpha_threshold_hp) or 2520.0

    local is_first_overflow_ring =
        (tonumber(active_ring_index) or 0) == 0

    -- Ring 1 occupies the same track as vanilla health. Its background must
    -- stay invisible while current HP is still entirely within vanilla HP,
    -- even when Max HP has already unlocked overflow capacity.
    local hide_ring_one_over_vanilla =
        is_first_overflow_ring and
        current_hp <= background_threshold

    local hide_before_overflow_unlock =
        current_max_hp <= background_threshold

    local force_background_hidden =
        ctx.state.overlay_bg_auto_alpha == true and
        (
            hide_ring_one_over_vanilla or
            hide_before_overflow_unlock
        )

    local effective_bg_alpha =
        force_background_hidden and 0 or configured_bg_alpha

    ctx.state.overlay_bg_effective_alpha = effective_bg_alpha
    ctx.state.overlay_bg_forced_hidden = force_background_hidden

    local fg_color = pack_style(ctx, style, "fg",
        ctx.ui.overlay_fg_r, ctx.ui.overlay_fg_g, ctx.ui.overlay_fg_b, ctx.ui.overlay_fg_a)

    local bg_color = pack_style(ctx, style, "bg",
        ctx.ui.overlay_bg_r, ctx.ui.overlay_bg_g, ctx.ui.overlay_bg_b, ctx.ui.overlay_bg_a,
        effective_bg_alpha)

    local damage_color = pack_style(ctx, style, "damage",
        ctx.state.overlay_damage_r, ctx.state.overlay_damage_g,
        ctx.state.overlay_damage_b, ctx.state.overlay_damage_a)

    local cap_color = pack_style(ctx, style, "cap",
        ctx.ui.overlay_cap_r, ctx.ui.overlay_cap_g,
        ctx.ui.overlay_cap_b, ctx.ui.overlay_cap_a)

    local heal_color = pack_style(ctx, style, "heal",
        ctx.state.overlay_heal_r, ctx.state.overlay_heal_g,
        ctx.state.overlay_heal_b, ctx.state.overlay_heal_a)

    local preview_color = pack_style(ctx, style, "preview",
        ctx.state.overlay_preview_r, ctx.state.overlay_preview_g,
        ctx.state.overlay_preview_b, ctx.state.overlay_preview_a)

    return
        apply_alpha(fg_color, fade_alpha),
        apply_alpha(bg_color, fade_alpha),
        apply_alpha(damage_color, fade_alpha),
        apply_alpha(cap_color, fade_alpha),
        apply_alpha(heal_color, fade_alpha),
        apply_alpha(preview_color, fade_alpha)
end

local function get_arc_state(ctx)
    local direction =
        tonumber(ctx.state.overlay_direction) or 1.0

    local max_sweep =
        tonumber(ctx.state.overlay_max_sweep) or 270.0

    local start_angle =
        (tonumber(ctx.state.overlay_start_angle) or 0.0) +
        (tonumber(ctx.state.overlay_rotation) or 0.0)

    -- During an actual heal, advance the normal current-HP fill with
    -- the animated healing endpoint. The gained portion is still drawn
    -- separately in green on top, so the base fill never snaps at the end.
    local live_ratio =
        ctx.state.overlay_heal_active == true
        and clamp01(ctx.state.overlay_heal_ratio)
        or clamp01(ctx.state.overflow_ratio)

    local damage_ratio =
        clamp01(
            tonumber(ctx.state.overlay_damage_ratio)
            or live_ratio
        )

    if damage_ratio < live_ratio then
        damage_ratio = live_ratio
    end

    local live_sweep =
        live_ratio * max_sweep * direction

    local damage_sweep =
        damage_ratio * max_sweep * direction

    return
        direction,
        max_sweep,
        start_angle,
        live_sweep,
        damage_sweep
end

local function get_damage_geometry(
    ctx,
    radius,
    thickness,
    direction,
    start_angle,
    live_sweep,
    damage_sweep
)
    local cap_length =
        tonumber(ctx.state.overlay_cap_length) or 0.28

    local cap_width =
        tonumber(ctx.state.overlay_cap_width) or 1.59

    local centered_radius =
        radius + ((thickness - 1.0) * 0.5)

    local cap_half_length =
        thickness * 0.5 * cap_length

    local cap_padding_pixels = 2.0

    local cap_padding_angle =
        math.deg(
            (cap_half_length + cap_padding_pixels) /
            math.max(centered_radius, 1.0)
        )

    local signed_padding =
        cap_padding_angle * direction

    local damage_start_angle =
        start_angle +
        live_sweep +
        signed_padding

    local damage_segment_sweep =
        damage_sweep -
        live_sweep -
        signed_padding

    return
        centered_radius,
        cap_length,
        cap_width,
        damage_start_angle,
        damage_segment_sweep
end

local function has_damage_segment(
    ctx,
    direction,
    damage_segment_sweep
)
    if ctx.state.overlay_damage_active ~= true then
        return false
    end

    if direction > 0.0 then
        return damage_segment_sweep > 0.001
    end

    if direction < 0.0 then
        return damage_segment_sweep < -0.001
    end

    return false
end

-- Draw only after the health systems have produced valid overflow
-- data. WaitEnd (CurrStep 4) is handled by the visibility gate.
function overlay.draw(ctx)
    if not ctx.state.overlay_enabled then
        return
    end

    if
        ctx.state.overlay_follow_native_hp_visibility == true and
        ctx.state.native_hp_bar_visibility_known == true and
        ctx.state.native_hp_bar_visible ~= true
    then
        return
    end

    if draw == nil then
        return
    end

    ctx.update_overflow_math()

    local current_hp =
        tonumber(ctx.state.current_hp) or 0.0

    local overflow_start =
        tonumber(ctx.state.overflow_start_hp) or 2520.0

    local can_draw_overflow =
        current_hp > overflow_start

    if (tonumber(ctx.state.overflow_max) or 0.0) <= 0.0 then
        return
    end

    local fade_alpha = 1.0

    if fade_alpha <= 0.001 then
        return
    end

    local cx,
          cy,
          radius,
          thickness =
        get_scaled_geometry(ctx)

    local segments =
        tonumber(ctx.state.overlay_segments) or 48

    local direction,
          max_sweep,
          start_angle,
          live_sweep,
          damage_sweep =
        get_arc_state(ctx)

    ------------------------------------------------------------
    -- Current and projected capacity
    ------------------------------------------------------------

    local current_max_hp =
        tonumber(ctx.state.max_hp) or 0.0

    local active_ring_index =
        tonumber(
            ctx.state.overflow_active_ring_index
        ) or 0

    local current_max_ratio =
        get_ratio_on_ring(
            ctx,
            current_max_hp,
            active_ring_index
        )

    local projected_max_hp =
        tonumber(
            ctx.state.preview_projected_max_hp
        ) or current_max_hp

    if
        ctx.state.overlay_preview_active ~= true or
        projected_max_hp < current_max_hp
    then
        projected_max_hp =
            current_max_hp
    end

    local projected_ring_index,
          projected_ring_ratio =
        get_ring_position(
            ctx,
            projected_max_hp
        )

    local crosses_ring =
        projected_ring_index >
        active_ring_index

    ctx.state.overlay_preview_current_ring_index =
        active_ring_index

    ctx.state.overlay_preview_current_ring_ratio =
        current_max_ratio

    ctx.state.overlay_preview_projected_ring_index =
        projected_ring_index

    ctx.state.overlay_preview_projected_ring_ratio =
        projected_ring_ratio

    ctx.state.overlay_preview_crosses_ring =
        crosses_ring

    -- A ring becomes eligible only after Max HP reaches its starting
    -- threshold. Ring 1 begins at 2520, Ring 2 at 5040, and so on.
    local overflow_start =
        tonumber(ctx.state.overflow_start_hp) or 2520.0

    local ring_capacity =
        math.max(
            1.0,
            tonumber(ctx.state.overflow_ring_hp) or 2520.0
        )

    local current_overflow =
        math.max(
            0.0,
            current_max_hp - overflow_start
        )

    local projected_overflow =
        math.max(
            0.0,
            projected_max_hp - overflow_start
        )

    ctx.state.overlay_visible_ring_count =
        current_overflow > 0.0
        and math.max(
            1,
            math.ceil(
                current_overflow /
                ring_capacity
            )
        )
        or 0

    ctx.state.overlay_projected_visible_ring_count =
        projected_overflow > 0.0
        and math.max(
            1,
            math.ceil(
                projected_overflow /
                ring_capacity
            )
        )
        or 0

    ctx.state.overlay_next_ring_threshold_hp =
        overflow_start +
        (
            ctx.state.overlay_visible_ring_count *
            ring_capacity
        )

    -- Stable renderer behavior: preview remains on the current ring.
    -- Cross-ring drawing will be reintroduced separately after validation.
    local projected_max_ratio =
        crosses_ring
        and current_max_ratio
        or projected_ring_ratio

    local projected_current_ratio =
        clamp01(
            ctx.state.overlay_preview_heal_ratio
        )

    local current_max_sweep =
        current_max_ratio *
        max_sweep *
        direction

    local projected_max_sweep =
        projected_max_ratio *
        max_sweep *
        direction

    local projected_current_sweep =
        projected_current_ratio *
        max_sweep *
        direction

    ------------------------------------------------------------
    -- Colors
    ------------------------------------------------------------

    local fg_color,
          bg_color,
          damage_color,
          cap_color,
          heal_color,
          preview_color =
        get_colors(
            ctx,
            fade_alpha,
            active_ring_index
        )

    local projected_style =
        get_ring_style(
            ctx,
            projected_ring_index
        )

    local next_ring_preview_color =
        pack_style(
            ctx,
            projected_style,
            "preview",
            ctx.state.overlay_preview_r,
            ctx.state.overlay_preview_g,
            ctx.state.overlay_preview_b,
            ctx.state.overlay_preview_a
        )

    local preview_pulse_alpha =
        get_preview_pulse_alpha(ctx)

    preview_color =
        apply_alpha(
            preview_color,
            preview_pulse_alpha
        )

    next_ring_preview_color =
        apply_alpha(
            next_ring_preview_color,
            fade_alpha * preview_pulse_alpha
        )

    ------------------------------------------------------------
    -- Damage geometry
    ------------------------------------------------------------

    local centered_radius,
          cap_length,
          cap_width,
          damage_start_angle,
          damage_segment_sweep =
        get_damage_geometry(
            ctx,
            radius,
            thickness,
            direction,
            start_angle,
            live_sweep,
            damage_sweep
        )

    ------------------------------------------------------------
    -- Max-HP preview geometry
    ------------------------------------------------------------

    local max_preview_start_angle =
        start_angle +
        current_max_sweep

    local max_preview_segment_sweep =
        projected_max_sweep -
        current_max_sweep

    local has_max_preview =
        ctx.state.overlay_preview_active == true
        and
        (
            (
                direction > 0.0 and
                max_preview_segment_sweep > 0.001
            )
            or
            (
                direction < 0.0 and
                max_preview_segment_sweep < -0.001
            )
        )

    ------------------------------------------------------------
    -- Safe next-ring Max-HP preview geometry
    ------------------------------------------------------------

    local previews_exactly_next_ring =
        projected_ring_index ==
        active_ring_index + 1

    local next_ring_preview_ratio =
        clamp01(
            projected_ring_ratio
        )

    local next_ring_preview_sweep =
        clamp_signed_sweep(
            next_ring_preview_ratio *
            max_sweep *
            direction,
            max_sweep
        )

    -- Keep the projected segment visually attached to the health bar,
    -- but shift its centerline slightly inward so the completed current
    -- ring cannot fully cover it.
    local preview_radial_offset =
        math.max(
            -thickness * 0.45,
            math.min(
                finite_number(
                    ctx.state.overlay_next_ring_preview_radial_offset,
                    -2.5
                ),
                thickness * 0.45
            )
        )

    local next_ring_radius =
        math.max(
            1.0,
            finite_number(
                radius,
                1.0
            )
        )

    -- Retain the setting for compatibility, but geometry is locked to the
    -- native track while alignment is being validated.
    preview_radial_offset = 0.0

    local has_next_ring_preview =
        ctx.state.overlay_next_ring_preview_enabled == true
        and
        ctx.state.overlay_preview_active == true
        and
        crosses_ring
        and
        previews_exactly_next_ring
        and
        math.abs(next_ring_preview_sweep) > 0.001

    ctx.state.overlay_next_ring_preview_radius =
        next_ring_radius

    ctx.state.overlay_next_ring_preview_sweep =
        next_ring_preview_sweep

    ctx.state.overlay_next_ring_preview_drawn =
        has_next_ring_preview

    ------------------------------------------------------------
    -- Healing preview geometry
    ------------------------------------------------------------

    local heal_preview_start_angle =
        start_angle +
        live_sweep

    local heal_preview_segment_sweep =
        projected_current_sweep -
        live_sweep

    local has_heal_preview =
        ctx.state.overlay_preview_active == true
        and
        (
            (
                direction > 0.0 and
                heal_preview_segment_sweep > 0.001
            )
            or
            (
                direction < 0.0 and
                heal_preview_segment_sweep < -0.001
            )
        )

    ------------------------------------------------------------
    -- Actual healing geometry
    ------------------------------------------------------------

    -- The green layer represents the complete projected heal immediately.
    -- The normal current-HP layer advances underneath it over time, causing
    -- the remaining green segment to shrink until the target is reached.
    local actual_heal_ratio =
        clamp01(
            ctx.state.overlay_heal_target_ratio
        )

    local actual_heal_sweep =
        actual_heal_ratio *
        max_sweep *
        direction

    local actual_heal_start_angle =
        start_angle +
        live_sweep

    local actual_heal_segment_sweep =
        actual_heal_sweep -
        live_sweep

    local has_actual_heal_segment =
        ctx.state.overlay_heal_active == true
        and
        (
            (
                direction > 0.0 and
                actual_heal_segment_sweep > 0.001
            )
            or
            (
                direction < 0.0 and
                actual_heal_segment_sweep < -0.001
            )
        )

    ------------------------------------------------------------
    -- 1. Current Max HP capacity
    ------------------------------------------------------------

    if math.abs(current_max_sweep) > 0.001 then
        ring.draw_arc(
            cx,
            cy,
            radius,
            thickness,
            start_angle,
            current_max_sweep,
            bg_color,
            segments
        )
    end

    ------------------------------------------------------------
    -- 2. Projected Max HP extension
    ------------------------------------------------------------

    if has_max_preview and not crosses_ring then
        ring.draw_arc(
            cx,
            cy,
            radius,
            thickness,
            max_preview_start_angle,
            max_preview_segment_sweep,
            preview_color,
            segments
        )
    end

    ------------------------------------------------------------
    -- 3. Recently lost HP
    ------------------------------------------------------------

    if
        can_draw_overflow and
        has_damage_segment(
            ctx,
            direction,
            damage_segment_sweep
        )
    then
        ring.draw_arc(
            cx,
            cy,
            radius,
            thickness,
            damage_start_angle,
            damage_segment_sweep,
            damage_color,
            segments
        )
    end

    ------------------------------------------------------------
    -- 4. Projected healing
    ------------------------------------------------------------

    if
        can_draw_overflow and
        has_heal_preview
    then
        ring.draw_arc(
            cx,
            cy,
            radius,
            thickness,
            heal_preview_start_angle,
            heal_preview_segment_sweep,
            preview_color,
            segments
        )
    end

    ------------------------------------------------------------
    -- 5. Current HP, including the animated healing endpoint
    ------------------------------------------------------------

    if
        can_draw_overflow and
        math.abs(live_sweep) > 0.001
    then
        ring.draw_arc(
            cx,
            cy,
            radius,
            thickness,
            start_angle,
            live_sweep,
            fg_color,
            segments
        )
    end

    ------------------------------------------------------------
    -- 6. Remaining projected healing from animated HP to target HP
    ------------------------------------------------------------

    if
        can_draw_overflow and
        has_actual_heal_segment
    then
        ring.draw_arc(
            cx,
            cy,
            radius,
            thickness,
            actual_heal_start_angle,
            actual_heal_segment_sweep,
            heal_color,
            segments
        )
    end

    ------------------------------------------------------------
    -- 7. Projected next-ring Max HP, drawn on top of the live bar
    ------------------------------------------------------------

    -- Render after live HP and use a slight inward centerline offset so
    -- the segment reads as part of the same bar without being overdrawn.
    if has_next_ring_preview then
        ring.draw_arc(
            cx,
            cy,
            next_ring_radius,
            thickness,
            start_angle,
            next_ring_preview_sweep,
            next_ring_preview_color,
            segments
        )
    end

    ------------------------------------------------------------
    -- 8. Current endpoint cap
    ------------------------------------------------------------

    -- The cap follows the gradually advancing current-health endpoint.
    -- The projected green endpoint remains an uncapped target segment.
    local endpoint_sweep =
        live_sweep

    local endpoint_cap_color =
        cap_color

    if
        can_draw_overflow and
        ctx.state.overlay_cap_enabled == true and
        math.abs(endpoint_sweep) > 0.001
    then
        ring.draw_flat_cap(
            cx,
            cy,
            centered_radius,
            thickness,
            start_angle + endpoint_sweep,
            endpoint_cap_color,
            cap_length,
            cap_width
        )
    end
end

return overlay