------------------------------------------------------------
-- Maintenance classification — Build 49.39
-- Module: autorun/project_overflow/xp/renderer.lua
-- Role: HUD, XP, material, geometry, or rendering implementation.
-- Status: active renderer.
--
-- Compatibility policy:
--   Existing functions, hooks, module paths, and diagnostics are
--   intentionally retained in this maintenance pass.
--   `DEPRECATED` marks a supported legacy path, not removed code.
------------------------------------------------------------

------------------------------------------------------------
-- Project: Overflow — xp/renderer.lua
-- XP-ring state, geometry, visibility, material, and rendering.
------------------------------------------------------------

local renderer = {}
local source = require("project_overflow.xp.source")
local geometry = require("project_overflow.xp.geometry")
local visibility = require("project_overflow.xp.visibility")
local material = require("project_overflow.xp.material")
local state = require("project_overflow.xp.state")

local function point(cx, cy, radius, degrees)
    local radians = math.rad(degrees)

    return cx + math.cos(radians) * radius,
        cy + math.sin(radians) * radius
end

local function draw_filled_quad(
    x1,
    y1,
    x2,
    y2,
    x3,
    y3,
    x4,
    y4,
    color
)
    if draw == nil or draw.filled_quad == nil then
        return false
    end

    return pcall(function()
        draw.filled_quad(
            x1,
            y1,
            x2,
            y2,
            x3,
            y3,
            x4,
            y4,
            color
        )
    end)
end

-- Independent rectangular arc-band renderer.
-- This copies only the HP ring's polar layout approach; it does not call
-- health state, health rendering, or shared HP draw functions.
local function draw_arc_band(
    cx,
    cy,
    inner_radius,
    thickness,
    start_angle,
    sweep,
    segments,
    color_for_segment
)
    if draw == nil or draw.filled_quad == nil then
        return
    end

    if math.abs(sweep) <= 0.001 then
        return
    end

    inner_radius = math.max(
        1.0,
        tonumber(inner_radius) or 1.0
    )

    thickness = math.max(
        0.5,
        tonumber(thickness) or 1.0
    )

    segments = math.max(
        1,
        math.floor(tonumber(segments) or 1)
    )

    local outer_radius =
        inner_radius + thickness

    local previous_angle =
        start_angle

    local previous_inner_x,
          previous_inner_y =
        point(
            cx,
            cy,
            inner_radius,
            previous_angle
        )

    local previous_outer_x,
          previous_outer_y =
        point(
            cx,
            cy,
            outer_radius,
            previous_angle
        )

    for segment = 1, segments do
        local progress =
            segment / segments

        local angle =
            start_angle + sweep * progress

        local current_inner_x,
              current_inner_y =
            point(
                cx,
                cy,
                inner_radius,
                angle
            )

        local current_outer_x,
              current_outer_y =
            point(
                cx,
                cy,
                outer_radius,
                angle
            )

        draw_filled_quad(
            previous_inner_x,
            previous_inner_y,
            previous_outer_x,
            previous_outer_y,
            current_outer_x,
            current_outer_y,
            current_inner_x,
            current_inner_y,
            color_for_segment(
                progress,
                segment
            )
        )

        previous_angle =
            angle

        previous_inner_x =
            current_inner_x

        previous_inner_y =
            current_inner_y

        previous_outer_x =
            current_outer_x

        previous_outer_y =
            current_outer_y
    end
end

local function draw_arc_line(
    cx,
    cy,
    radius,
    start_angle,
    sweep,
    segments,
    color_for_segment
)
    if draw == nil or draw.line == nil then
        return
    end

    if math.abs(sweep) <= 0.001 then
        return
    end

    segments = math.max(
        1,
        math.floor(tonumber(segments) or 1)
    )

    local last_x,
          last_y =
        point(
            cx,
            cy,
            radius,
            start_angle
        )

    for segment = 1, segments do
        local progress = segment / segments
        local angle = start_angle + sweep * progress
        local x, y = point(cx, cy, radius, angle)

        draw.line(
            last_x,
            last_y,
            x,
            y,
            color_for_segment(progress, segment)
        )

        last_x = x
        last_y = y
    end
end

local function draw_radial_marker(
    g,
    angle,
    radial_extension,
    tangent_width,
    radial_offset,
    color
)
    if draw == nil or draw.filled_quad == nil then
        return
    end

    local radians = math.rad(angle)
    local radial_x = math.cos(radians)
    local radial_y = math.sin(radians)
    local tangent_x = -radial_y
    local tangent_y = radial_x

    local inner_radius =
        g.radius
        - radial_extension * 0.5
        + radial_offset

    local outer_radius =
        g.radius
        + g.thickness
        + radial_extension * 0.5
        + radial_offset

    local half_tangent =
        math.max(0.5, tangent_width * 0.5)

    local inner_x = g.center_x + radial_x * inner_radius
    local inner_y = g.center_y + radial_y * inner_radius
    local outer_x = g.center_x + radial_x * outer_radius
    local outer_y = g.center_y + radial_y * outer_radius

    draw_filled_quad(
        inner_x - tangent_x * half_tangent,
        inner_y - tangent_y * half_tangent,
        outer_x - tangent_x * half_tangent,
        outer_y - tangent_y * half_tangent,
        outer_x + tangent_x * half_tangent,
        outer_y + tangent_y * half_tangent,
        inner_x + tangent_x * half_tangent,
        inner_y + tangent_y * half_tangent,
        color
    )
end

local function draw_track_border(g, sweep, alpha)
    if state.border_enabled ~= true then
        return
    end

    local width =
        math.max(
            1.0,
            (tonumber(state.border_width) or 1.0) * g.scale
        )

    width =
        math.min(
            width,
            math.max(
                0.5,
                g.thickness * 0.5
            )
        )

    local color =
        material.border_color(
            state,
            alpha
        )

    -- Both lines inset into the background band. They are drawn before the
    -- XP foreground, so the filled portion masks them instead of the border
    -- drawing over the active XP meter.
    draw_arc_band(
        g.center_x,
        g.center_y,
        g.radius,
        width,
        g.start_angle,
        sweep,
        g.segments,
        function()
            return color
        end
    )

    draw_arc_band(
        g.center_x,
        g.center_y,
        g.radius
            + g.thickness
            - width,
        width,
        g.start_angle,
        sweep,
        g.segments,
        function()
            return color
        end
    )

    -- Background end borders are also masked by any foreground fill.
    draw_radial_marker(
        g,
        g.start_angle,
        0.0,
        width,
        0.0,
        color
    )

    draw_radial_marker(
        g,
        g.start_angle + sweep,
        0.0,
        width,
        0.0,
        color
    )
end

local function smoothstep(edge0, edge1, value)
    if edge1 <= edge0 then
        return value >= edge1 and 1.0 or 0.0
    end

    local t =
        math.max(
            0.0,
            math.min(
                (value - edge0)
                    / (edge1 - edge0),
                1.0
            )
        )

    return t * t * (3.0 - 2.0 * t)
end

local function draw_background_edge_blur(
    g,
    sweep,
    alpha,
    phase
)
    if state.highlight_enabled ~= true then
        return
    end

    local border_width =
        state.border_enabled == true
        and math.max(
            0.0,
            (tonumber(state.border_width) or 1.0)
                * g.scale
        )
        or 0.0

    -- Start the blur exactly at the inside edges of the two border lines.
    -- No extra one-pixel inset is used, so there is no detached bright line.
    local interior_inner_radius =
        g.radius
        + border_width

    local interior_outer_radius =
        g.radius
        + g.thickness
        - border_width

    local interior_width =
        interior_outer_radius
        - interior_inner_radius

    if interior_width <= 0.5 then
        return
    end

    local requested_blur_depth =
        math.min(
            interior_width * 0.5,
            math.max(
                0.0,
                (tonumber(state.highlight_blur_radius) or 0.0)
                    * g.scale
            )
        )

    -- filled_quad rasterizes any positive sub-pixel band as a hard one-pixel
    -- line. Do not emit blur geometry until the requested depth reaches one
    -- physical pixel.
    local minimum_blur_depth =
        math.max(
            1.0,
            g.scale
        )

    if requested_blur_depth < minimum_blur_depth then
        return
    end

    local blur_depth =
        requested_blur_depth

    local blur_samples =
        math.max(
            3,
            math.min(
                16,
                math.floor(
                    tonumber(state.highlight_blur_samples) or 7
                )
            )
        )

    local edge_strength =
        math.max(
            0.0,
            tonumber(state.highlight_blur_alpha) or 0.34
        )

    local end_fade_degrees =
        math.max(
            0.0,
            tonumber(state.highlight_end_fade_degrees) or 4.0
        )

    local sweep_magnitude =
        math.max(
            0.001,
            math.abs(sweep)
        )

    local end_fade_ratio =
        math.min(
            0.45,
            end_fade_degrees / sweep_magnitude
        )

    local band_width =
        blur_depth / blur_samples

    for sample = 1, blur_samples do
        local radial_progress =
            (sample - 0.5)
            / blur_samples

        -- Sample at each band's center. This keeps the first band attached to
        -- the border while avoiding a separate full-strength one-pixel stripe.
        local radial_falloff =
            math.exp(
                -3.4
                * radial_progress
                * radial_progress
            )

        local opacity_scale =
            edge_strength
            * radial_falloff

        local inner_band_radius =
            interior_inner_radius
            + band_width
            * (sample - 1)

        local outer_band_radius =
            interior_outer_radius
            - band_width
            * sample

        local function blurred_color(
            segment_progress,
            edge_kind
        )
            -- Do not blur the angular start/end caps. Fade in only after the
            -- start edge and fade out before the level-threshold edge.
            local angular_fade =
                smoothstep(
                    0.0,
                    end_fade_ratio,
                    segment_progress
                )
                * smoothstep(
                    0.0,
                    end_fade_ratio,
                    1.0 - segment_progress
                )

            return material.highlight_color(
                state,
                segment_progress,
                phase,
                alpha,
                opacity_scale * angular_fade,
                edge_kind
            )
        end

        draw_arc_band(
            g.center_x,
            g.center_y,
            inner_band_radius,
            band_width,
            g.start_angle,
            sweep,
            g.segments,
            function(segment_progress)
                return blurred_color(
                    segment_progress,
                    "background_inner"
                )
            end
        )

        draw_arc_band(
            g.center_x,
            g.center_y,
            outer_band_radius,
            band_width,
            g.start_angle,
            sweep,
            g.segments,
            function(segment_progress)
                return blurred_color(
                    segment_progress,
                    "background_outer"
                )
            end
        )
    end
end

local function draw_fill_end_cap(g, angle, alpha)
    if state.cap_enabled ~= true then
        return
    end

    draw_radial_marker(
        g,
        angle,
        math.max(
            0.0,
            (tonumber(state.cap_extension) or 0.0) * g.scale
        ),
        math.max(
            0.5,
            (tonumber(state.cap_width) or 1.0) * g.scale
        ),
        (tonumber(state.cap_radial_offset) or 0.0) * g.scale,
        material.cap_color(state, alpha)
    )
end

local function draw_level_threshold(g, angle, alpha)
    if state.threshold_enabled ~= true then
        return
    end

    draw_radial_marker(
        g,
        angle,
        math.max(
            0.0,
            (tonumber(state.threshold_extension) or 2.0) * g.scale
        ),
        math.max(
            0.5,
            (tonumber(state.threshold_width) or 1.0) * g.scale
        ),
        (tonumber(state.threshold_radial_offset) or 0.0) * g.scale,
        material.threshold_color(state, alpha)
    )
end

local function clamp01(value)
    return math.max(
        0.0,
        math.min(
            1.0,
            tonumber(value) or 0.0
        )
    )
end

local function update_delay_fill(
    live_ratio,
    live_level
)
    local now =
        os.clock()

    live_ratio =
        clamp01(
            live_ratio
        )

    live_level =
        math.max(
            1,
            math.floor(
                tonumber(live_level) or 1
            )
        )

    local previous_level =
        tonumber(state.delay_fill_last_level)

    local previous_live_ratio =
        tonumber(state.delay_fill_last_live_ratio)

    local delay_ratio =
        clamp01(
            state.delay_fill_ratio
        )

    local last_update =
        tonumber(state.delay_fill_last_update_time)
            or now

    local delta_time =
        math.max(
            0.0,
            math.min(
                now - last_update,
                0.1
            )
        )

    state.delay_fill_last_update_time =
        now

    -- First valid live sample: initialize without animating from zero.
    if previous_level == nil
        or previous_live_ratio == nil
    then
        state.delay_fill_ratio =
            live_ratio

        state.delay_fill_target_ratio =
            live_ratio

        state.delay_fill_last_live_ratio =
            live_ratio

        state.delay_fill_last_level =
            live_level

        state.delay_fill_change_time =
            now

        return live_ratio
    end

    -- Level-up, reset, or XP removal: snap. This prevents the solid gain arc
    -- from sweeping backward across the threshold.
    if live_level ~= previous_level
        or live_ratio < previous_live_ratio - 0.0001
    then
        delay_ratio =
            live_ratio

        state.delay_fill_change_time =
            now
    elseif live_ratio > previous_live_ratio + 0.0001 then
        -- New XP: preserve the old gold ratio and expose the newly gained
        -- section in the configured raw gain color until catch-up begins.
        delay_ratio =
            math.min(
                delay_ratio,
                previous_live_ratio
            )

        state.delay_fill_change_time =
            now
    end

    state.delay_fill_target_ratio =
        live_ratio

    local wait_time =
        math.max(
            0.0,
            tonumber(state.delay_fill_wait) or 0.65
        )

    if now - (tonumber(state.delay_fill_change_time) or now)
        >= wait_time
    then
        local catchup_speed =
            math.max(
                0.0,
                tonumber(state.delay_fill_catchup_speed) or 0.55
            )

        delay_ratio =
            math.min(
                live_ratio,
                delay_ratio
                    + catchup_speed
                    * delta_time
            )
    end

    state.delay_fill_ratio =
        clamp01(
            delay_ratio
        )

    state.delay_fill_last_live_ratio =
        live_ratio

    state.delay_fill_last_level =
        live_level

    return state.delay_fill_ratio
end

local function draw_delay_fill(
    g,
    displayed_ratio,
    live_ratio,
    alpha,
    phase
)
    if state.delay_fill_enabled ~= true then
        return
    end

    displayed_ratio =
        clamp01(
            displayed_ratio
        )

    live_ratio =
        clamp01(
            live_ratio
        )

    local minimum_visible =
        math.max(
            0.0,
            tonumber(state.delay_fill_min_visible) or 0.0025
        )

    if live_ratio - displayed_ratio
        <= minimum_visible
    then
        return
    end

    local start_sweep =
        g.max_sweep
        * displayed_ratio
        * g.direction

    local delayed_sweep =
        g.max_sweep
        * (live_ratio - displayed_ratio)
        * g.direction

    draw_arc_band(
        g.center_x,
        g.center_y,
        g.radius,
        g.thickness,
        g.start_angle + start_sweep,
        delayed_sweep,
        math.max(
            1,
            math.ceil(
                g.segments
                * (live_ratio - displayed_ratio)
            )
        ),
        function(progress)
            return material.delay_fill_color(
                state,
                progress,
                phase,
                alpha
            )
        end
    )
end

local function draw_impl(ctx)
    local visible,
          alpha =
        visibility.resolve(
            ctx,
            state
        )

    if not visible or draw == nil then
        return
    end

    local g =
        geometry.resolve(
            ctx,
            state
        )

    local live =
        source.snapshot()

    state.live_level =
        live.level

    state.live_current_xp =
        live.current_xp

    state.live_required_xp =
        live.required_xp

    state.live_levels_gained =
        live.levels_gained

    state.live_source_status =
        live.status

    local live_ratio =
        state.preview_enabled == true
            and 0.65
            or live.ratio

    live_ratio =
        clamp01(
            live_ratio
        )

    local ratio =
        state.preview_enabled == true
            and live_ratio
            or update_delay_fill(
                live_ratio,
                live.level
            )

    if state.delay_fill_enabled ~= true then
        ratio =
            live_ratio

        state.delay_fill_ratio =
            live_ratio

        state.delay_fill_target_ratio =
            live_ratio
    end

    state.last_ratio =
        live_ratio

    local direction =
        g.direction

    local track_sweep =
        g.max_sweep * direction

    local fill_sweep =
        g.max_sweep
        * ratio
        * direction

    local phase =
        os.clock()
        * (tonumber(state.shader_speed) or 19.0)

    -- True rectangular gold track, matching the native HP band's silhouette.
    draw_arc_band(
        g.center_x,
        g.center_y,
        g.radius,
        g.thickness,
        g.start_angle,
        track_sweep,
        g.segments,
        function(progress)
            return material.background_color(
                state,
                progress,
                phase,
                alpha
            )
        end
    )

    draw_background_edge_blur(
        g,
        track_sweep,
        alpha,
        phase
    )

    -- Background-only inset border. The foreground pass below masks this
    -- wherever XP has filled the meter.
    draw_track_border(
        g,
        track_sweep,
        alpha
    )

    draw_level_threshold(
        g,
        g.start_angle + track_sweep,
        alpha
    )

    -- Solid-color gain preview sits between the delayed gold value and the
    -- current live XP value.
    draw_delay_fill(
        g,
        ratio,
        live_ratio,
        alpha,
        phase
    )

    -- Gold animated XP fill catches up after the configured delay.
    if ratio > 0.0 then
        draw_arc_band(
            g.center_x,
            g.center_y,
            g.radius,
            g.thickness,
            g.start_angle,
            fill_sweep,
            g.segments,
            function(progress)
                return material.fill_color(
                    state,
                    progress,
                    phase,
                    alpha
                )
            end
        )

        draw_fill_end_cap(
            g,
            g.start_angle
                + g.max_sweep
                * live_ratio
                * g.direction,
            alpha
        )
    end

    state.draw_calls =
        (tonumber(state.draw_calls) or 0)
        + 1

    state.status =
        "XP ring draw completed."
end

function renderer.draw(ctx)
    local ok,
          error_message =
        pcall(
            draw_impl,
            ctx
        )

    if not ok then
        state.last_error =
            tostring(error_message)

        state.status =
            "XP ring disabled after draw error."

        state.enabled =
            false
    end
end

return renderer
