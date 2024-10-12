const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    const winWidth: i32 = 800;
    const winHeight: i32 = 450;
    const winTitle = "Circles";
    rl.InitWindow(winWidth, winHeight, winTitle);

    const circle = struct { center: rl.Vector2, outerRadius: f32, startAngle: f32, endAngle: f32, segments: f32 };

    rl.SetTargetFPS(120);

    var isDrawingCircle: bool = false;
    var drawCenter = rl.Vector2{ .x = 0.0, .y = 0.0 };
    var drawOuterRadius: f32 = 0.0;

    const listAllocator = std.heap.page_allocator;
    var circleList = std.ArrayList(circle).init(listAllocator);
    defer circleList.deinit();

    while (!rl.WindowShouldClose()) {
        const mousePos: rl.Vector2 = rl.GetMousePosition();

        rl.BeginDrawing();

        rl.ClearBackground(rl.RAYWHITE);

        if (rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT) and !isDrawingCircle) {
            drawCenter = rl.Vector2{ .x = mousePos.x, .y = mousePos.y };
            isDrawingCircle = true;
        }

        if (isDrawingCircle) {
            drawOuterRadius = std.math.sqrt(std.math.pow(f32, (mousePos.x - drawCenter.x), 2.0) + std.math.pow(f32, (mousePos.y - drawCenter.y), 2.0));

            rl.DrawCircleSector(drawCenter, drawOuterRadius, 0, 360, 32, rl.Fade(rl.RED, 0.3));

            if (drawOuterRadius > 1.0 and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT)) {
                isDrawingCircle = false;
                const newCircle = circle{ .center = drawCenter, .outerRadius = drawOuterRadius, .startAngle = 0.0, .endAngle = 360.0, .segments = 32.0 };

                try circleList.append(newCircle);
            }
        }

        for (circleList.items) |c| {
            rl.DrawCircleSector(c.center, c.outerRadius, 0, 360, 32, rl.Fade(rl.BLUE, 0.3));
        }

        if (isDrawingCircle) {
            const deltaX = (mousePos.x - drawCenter.x);
            const deltaY = (mousePos.y - drawCenter.y);

            var stPointX = @as(i32, @intFromFloat(drawCenter.x));
            var stPointY = @as(i32, @intFromFloat(drawCenter.y));

            const iter = @as(usize, @intFromFloat(drawOuterRadius / 2));

            for (0..iter) |_| {
                const distanceToCenter = std.math.sqrt(std.math.pow(f32, @as(f32, @floatFromInt(stPointX)) - drawCenter.x, 2) +
                    std.math.pow(f32, @as(f32, @floatFromInt(stPointY)) - drawCenter.y, 2));

                if (distanceToCenter <= drawOuterRadius) {
                    rl.DrawPixel(stPointX, stPointY, rl.WHITE);
                }

                stPointX += @as(i32, @intFromFloat(deltaX / 16));
                stPointY += @as(i32, @intFromFloat(deltaY / 16));
            }
        }

        rl.EndDrawing();
    }

    rl.CloseWindow();
}
