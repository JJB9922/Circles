const std = @import("std");
const rlzb = @import("rlzb");
const rl = rlzb.raylib;
const rg = rlzb.raygui;

const ShapeType = enum {
    circle,
};

const Shape = struct {
    type: ShapeType,
    origin: rl.Vector2,
    outerBound: f32,
};

const SelectedTool = enum {
    none,
    draw_circle,
};

var selectedTool: SelectedTool = SelectedTool.none;

fn draw_ui(shapeList: *std.ArrayList(Shape)) !void {
    rl.DrawFPS(2, 64);
    rl.DrawText("Circles Present:", 2, 86, 22, rl.Fade(rl.DARKBLUE, 0.8));

    const n = shapeList.items.len;
    var buf: [10]u8 = undefined;
    const str = try std.fmt.bufPrintZ(&buf, "{}", .{n});

    rl.DrawText(str, 2, 112, 22, rl.Fade(rl.DARKBLUE, 0.8));
    rl.DrawLine(0, 64, rl.GetScreenWidth(), 64, rl.Fade(rl.BLACK, 0.3));
    rl.DrawRectangle(0, 0, rl.GetScreenWidth(), 64, rl.Fade(rl.LIGHTGRAY, 0.8));

    const circleBtn = rl.Rectangle{ .x = 8, .y = 8, .width = 86, .height = 48 };
    if (rg.GuiButton(circleBtn, "Circle Tool") == 1) {
        selectedTool = SelectedTool.draw_circle;
    }
}

fn draw_circle_mode(isDrawingShape: *bool, drawOrigin: *rl.Vector2, drawOuterBound: *f32, mousePos: *const rl.Vector2, shapeList: *std.ArrayList(Shape)) !void {
    if (rl.IsMouseButtonPressed(rl.MOUSE_LEFT_BUTTON.toCInt()) and !isDrawingShape.* and mousePos.y > 64) {
        drawOrigin.* = rl.Vector2{ .x = mousePos.*.x, .y = mousePos.*.y };
        isDrawingShape.* = true;
    }

    if (isDrawingShape.*) {
        drawOuterBound.* = std.math.sqrt(std.math.pow(f32, (mousePos.*.x - drawOrigin.*.x), 2.0) + std.math.pow(f32, (mousePos.*.y - drawOrigin.*.y), 2.0));

        rl.DrawCircleSector(drawOrigin.*, drawOuterBound.*, 0, 360, 32, rl.Fade(rl.RED, 0.3));

        if (drawOuterBound.* > 1.0 and rl.IsMouseButtonPressed(rl.MOUSE_LEFT_BUTTON.toCInt())) {
            isDrawingShape.* = false;
            const newCircle = Shape{ .type = ShapeType.circle, .origin = drawOrigin.*, .outerBound = drawOuterBound.* };

            try shapeList.*.append(newCircle);
        }
    }

    for (shapeList.*.items) |c| {
        rl.DrawCircleSector(c.origin, c.outerBound, 0, 360, 32, rl.Fade(rl.BLUE, 0.3));
    }

    if (isDrawingShape.*) {
        const deltaX = (mousePos.*.x - drawOrigin.*.x);
        const deltaY = (mousePos.*.y - drawOrigin.*.y);

        var stPointX: i32 = @intFromFloat(drawOrigin.*.x);
        var stPointY: i32 = @intFromFloat(drawOrigin.*.y);

        const iter: usize = @intFromFloat(drawOuterBound.* / 2);

        for (0..iter) |_| {
            const distanceToCenter = std.math.sqrt(std.math.pow(f32, @as(f32, @floatFromInt(stPointX)) - drawOrigin.*.x, 2) +
                std.math.pow(f32, @as(f32, @floatFromInt(stPointY)) - drawOrigin.*.y, 2));

            if (distanceToCenter <= drawOuterBound.*) {
                rl.DrawPixel(stPointX, stPointY, rl.WHITE);
            }

            stPointX += @as(i32, @intFromFloat(deltaX / 16));
            stPointY += @as(i32, @intFromFloat(deltaY / 16));
        }
    }
}

pub fn main() !void {
    const winWidth: i32 = 1200;
    const winHeight: i32 = 850;
    const winTitle = "Circles";
    rl.InitWindow(winWidth, winHeight, winTitle);

    rl.SetTargetFPS(120);

    var isDrawingShape: bool = false;
    var drawOrigin = rl.Vector2{ .x = 0.0, .y = 0.0 };
    var drawOuterBound: f32 = 0.0;

    const listAllocator = std.heap.page_allocator;
    var shapeList = std.ArrayList(Shape).init(listAllocator);
    defer shapeList.deinit();

    while (!rl.WindowShouldClose()) {
        const mousePos: rl.Vector2 = rl.GetMousePosition();

        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        switch (selectedTool) {
            SelectedTool.none => {},
            SelectedTool.draw_circle => try draw_circle_mode(&isDrawingShape, &drawOrigin, &drawOuterBound, &mousePos, &shapeList),
        }

        try draw_ui(&shapeList);
        rl.EndDrawing();
    }

    rl.CloseWindow();
}
