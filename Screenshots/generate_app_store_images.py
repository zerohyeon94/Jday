from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS = ROOT / "Screenshots"
OUT_IOS = SCREENSHOTS / "AppStore" / "iOS"
OUT_MAC = SCREENSHOTS / "AppStore" / "macOS"

FONT_PATH = Path("/System/Library/Fonts/AppleSDGothicNeo.ttc")
ICON_PATH = ROOT / "Jday/Resources/Assets.xcassets/AppIcon.appiconset/JdayIcon-iOS-1024.png"

IOS_SIZE = (1290, 2796)
MAC_SIZE = (2880, 1800)

BLUE = (56, 103, 163)
DARK_BLUE = (31, 66, 116)
INK = (22, 32, 48)
MUTED = (79, 94, 113)
WHITE = (255, 255, 255)


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_PATH), size=size)


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGB", size)
    pixels = image.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(width):
            pixels[x, y] = color
    return image.convert("RGBA")


def add_subtle_pattern(canvas: Image.Image, accent: tuple[int, int, int]) -> None:
    draw = ImageDraw.Draw(canvas, "RGBA")
    width, height = canvas.size
    for x in range(-height, width, 86):
        draw.line([(x, 0), (x + height, height)], fill=(*accent, 11), width=2)
    for y in range(180, height, 260):
        draw.rounded_rectangle(
            (width - 330, y, width - 90, y + 18),
            radius=9,
            fill=(*accent, 22),
        )


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def paste_shadowed(canvas: Image.Image, image: Image.Image, xy: tuple[int, int], radius: int, shadow: int) -> None:
    x, y = xy
    mask = rounded_mask(image.size, radius)
    shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_shape = Image.new("RGBA", image.size, (0, 0, 0, 88))
    shadow_layer.paste(shadow_shape, (x, y + shadow), mask)
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(shadow))
    canvas.alpha_composite(shadow_layer)
    canvas.paste(image, (x, y), mask)


def draw_text_block(
    draw: ImageDraw.ImageDraw,
    title: str,
    subtitle: str,
    *,
    center_x: int,
    top: int,
    title_size: int,
    subtitle_size: int,
    max_width: int,
    align: str = "center",
    title_fill: tuple[int, int, int] = INK,
) -> int:
    title_font = font(title_size)
    subtitle_font = font(subtitle_size)
    line_gap = int(title_size * 0.22)
    subtitle_gap = int(title_size * 0.34)

    lines = title.split("\n")
    y = top
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=title_font)
        line_w = bbox[2] - bbox[0]
        x = center_x - line_w // 2 if align == "center" else center_x
        draw.text((x, y), line, font=title_font, fill=title_fill)
        y += title_size + line_gap

    y += subtitle_gap
    sub_lines = wrap_text(draw, subtitle, subtitle_font, max_width)
    for line in sub_lines:
        bbox = draw.textbbox((0, 0), line, font=subtitle_font)
        line_w = bbox[2] - bbox[0]
        x = center_x - line_w // 2 if align == "center" else center_x
        draw.text((x, y), line, font=subtitle_font, fill=MUTED)
        y += subtitle_size + 14
    return y


def wrap_text(draw: ImageDraw.ImageDraw, text: str, text_font: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    words = text.split(" ")
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        if draw.textbbox((0, 0), candidate, font=text_font)[2] <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def draw_brand_pill(canvas: Image.Image, x: int, y: int) -> None:
    draw = ImageDraw.Draw(canvas, "RGBA")
    icon = Image.open(ICON_PATH).convert("RGBA").resize((58, 58), Image.Resampling.LANCZOS)
    draw.rounded_rectangle((x, y, x + 198, y + 78), radius=39, fill=(255, 255, 255, 210))
    canvas.alpha_composite(icon, (x + 12, y + 10))
    draw.text((x + 82, y + 22), "Jday", font=font(30), fill=DARK_BLUE)


def make_phone_frame(screen_path: Path, target_width: int) -> Image.Image:
    screen = Image.open(screen_path).convert("RGBA")
    target_height = round(target_width * screen.height / screen.width)
    screen = screen.resize((target_width, target_height), Image.Resampling.LANCZOS)

    bezel = 22
    outer = Image.new("RGBA", (target_width + bezel * 2, target_height + bezel * 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(outer, "RGBA")
    draw.rounded_rectangle((0, 0, outer.width, outer.height), radius=84, fill=(9, 14, 22, 255))
    inner_mask = rounded_mask(screen.size, 64)
    outer.paste(screen, (bezel, bezel), inner_mask)
    draw.rounded_rectangle((0, 0, outer.width - 1, outer.height - 1), radius=84, outline=(255, 255, 255, 120), width=3)
    return outer


def make_ios_image(source: str, title: str, subtitle: str, output: str, accent: tuple[int, int, int]) -> None:
    canvas = gradient(IOS_SIZE, (244, 249, 255), (219, 235, 251))
    add_subtle_pattern(canvas, accent)
    draw = ImageDraw.Draw(canvas, "RGBA")
    draw_brand_pill(canvas, 84, 86)
    draw_text_block(
        draw,
        title,
        subtitle,
        center_x=IOS_SIZE[0] // 2,
        top=232,
        title_size=98,
        subtitle_size=38,
        max_width=920,
    )

    frame = make_phone_frame(SCREENSHOTS / "iOS" / source, 858)
    x = (IOS_SIZE[0] - frame.width) // 2
    y = 750
    paste_shadowed(canvas, frame, (x, y), radius=92, shadow=34)

    OUT_IOS.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(OUT_IOS / output, quality=95)


def crop_black_edges(image: Image.Image) -> Image.Image:
    rgb = image.convert("RGB")
    px = rgb.load()
    width, height = rgb.size
    min_x, min_y, max_x, max_y = width, height, 0, 0
    for y in range(height):
        for x in range(width):
            r, g, b = px[x, y]
            if max(r, g, b) > 18:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if min_x > max_x:
        return image
    pad = 4
    return image.crop((max(min_x - pad, 0), max(min_y - pad, 0), min(max_x + pad, width), min(max_y + pad, height)))


def make_mac_frame(screen_path: Path, target_width: int) -> Image.Image:
    screen = crop_black_edges(Image.open(screen_path).convert("RGBA"))
    target_height = round(target_width * screen.height / screen.width)
    screen = screen.resize((target_width, target_height), Image.Resampling.LANCZOS)

    frame = Image.new("RGBA", (target_width, target_height), (0, 0, 0, 0))
    mask = rounded_mask(screen.size, 42)
    frame.paste(screen, (0, 0), mask)
    draw = ImageDraw.Draw(frame, "RGBA")
    draw.rounded_rectangle((0, 0, frame.width - 1, frame.height - 1), radius=42, outline=(255, 255, 255, 170), width=3)
    return frame


def make_mac_image(source: str, title: str, subtitle: str, output: str, accent: tuple[int, int, int]) -> None:
    canvas = gradient(MAC_SIZE, (246, 250, 255), (224, 236, 250))
    add_subtle_pattern(canvas, accent)
    draw = ImageDraw.Draw(canvas, "RGBA")
    draw_brand_pill(canvas, 140, 100)
    draw_text_block(
        draw,
        title,
        subtitle,
        center_x=MAC_SIZE[0] // 2,
        top=150,
        title_size=96,
        subtitle_size=36,
        max_width=1720,
    )

    frame = make_mac_frame(SCREENSHOTS / "macOS" / source, 2400)
    x = (MAC_SIZE[0] - frame.width) // 2
    y = 470
    paste_shadowed(canvas, frame, (x, y), radius=48, shadow=42)

    OUT_MAC.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(OUT_MAC / output, quality=95)


def main() -> None:
    ios_items = [
        ("Jday_iOS_home.png", "오늘 업무를\n한 화면에서", "할 일, 일정, 진행률을 빠르게 확인하세요.", "01_today_dashboard.png", BLUE),
        ("Jday_iOS_add.png", "떠오른 일은\n바로 추가", "할 일, 일정, 이슈를 흐름 그대로 기록하세요.", "02_quick_add.png", (45, 121, 184)),
        ("Jday_iOS_calendar.png", "계획과 기록을\n날짜별로", "오늘과 선택 날짜를 구분하고 흐름을 확인하세요.", "03_calendar.png", (57, 132, 112)),
        ("Jday_iOS_issue.png", "놓치면 안 되는\n이슈까지", "미해결 이슈와 알림을 함께 관리하세요.", "04_issues.png", (72, 91, 156)),
        ("Jday_iOS_settings.png", "내 방식대로\n조정하는 Jday", "알림, 시작 화면, 작업 공간을 설정하세요.", "05_settings.png", (91, 104, 128)),
    ]

    mac_items = [
        ("Jday_macOS_home.png", "Mac에서 한눈에 보는 오늘", "넓은 화면에서 할 일과 일정을 함께 확인하세요.", "01_mac_today.png", BLUE),
        ("Jday_macOS_calendar.png", "월간 캘린더와 선택일 패널", "일정, 할 일, 완료 기록을 날짜별로 정리하세요.", "02_mac_calendar.png", (57, 132, 112)),
        ("Jday_macOS_add.png", "키보드 흐름 그대로 빠른 추가", "업무 중 떠오른 할 일과 이슈를 빠르게 기록하세요.", "03_mac_quick_add.png", (45, 121, 184)),
        ("Jday_macOS_issue.png", "이슈 목록과 상세를 나란히", "미해결 항목을 확인하고 바로 해결 상태를 바꾸세요.", "04_mac_issues.png", (72, 91, 156)),
        ("Jday_macOS_settings.png", "업무 환경을 내 방식대로", "알림과 기본 화면을 내 하루에 맞게 설정하세요.", "05_mac_settings.png", (91, 104, 128)),
    ]

    for item in ios_items:
        make_ios_image(*item)
    for item in mac_items:
        make_mac_image(*item)

    print(f"Created {len(ios_items)} iOS screenshots in {OUT_IOS}")
    print(f"Created {len(mac_items)} macOS screenshots in {OUT_MAC}")


if __name__ == "__main__":
    main()
