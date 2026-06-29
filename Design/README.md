# Design assets

Nơi chứa **file ảnh gốc** của app (export từ Figma, icon, illustration…).
Đây là nguồn để tham chiếu & version control — **không** được app build trực tiếp.

## Cấu trúc

| Thư mục | Nội dung |
|---|---|
| `svg/` | File vector gốc (`.svg`) — logo, icon, illustration |
| `png/` | File raster gốc (`.png`) export từ Figma |

## Quy trình dùng ảnh trong app

1. Lưu file gốc vào `Design/svg` hoặc `Design/png`.
2. Để dùng được trong code (`UIImage(named:)`), ảnh phải nằm trong
   **`Feelit/Assets.xcassets`** dưới dạng `*.imageset`:
   - Tạo folder `<Tên>.imageset` trong nhóm phù hợp (Branding / Welcome / Icons…)
   - Bỏ file `@2x.png`, `@3x.png` vào + `Contents.json` khai báo scale.
3. Gọi trong code bằng đúng tên imageset, ví dụ `UIImage(named: "WelcomeCharts")`.

> Tên ảnh trong asset catalog là **phẳng** (không kèm tên nhóm), nên các
> nhóm Branding/Welcome/Icons chỉ để sắp xếp cho gọn — không đổi tên gọi.

## SVG → PNG (nền trong suốt)

> ⚠️ Xcode `actool` **không** render đúng SVG phức tạp (clip-path/mask/filter
> như `welcome.svg`) — sẽ vỡ hình. Quick Look thì lại tô **nền trắng đục**.
> Vì thẻ biểu đồ cũng màu trắng nên không key-out trắng được.

Dùng `Design/svg2png.swift` (render qua `NSImage`, giữ nền trong suốt):

```sh
swiftc Design/svg2png.swift -o /tmp/svg2png
/tmp/svg2png Design/svg/welcome.svg welcome@2x.png 2
/tmp/svg2png Design/svg/welcome.svg welcome@3x.png 3
# rồi copy welcome@2x/3x.png vào Feelit/Assets.xcassets/Welcome/WelcomeIllustration.imageset
```

## Figma

File: `Feelit_app` — `https://www.figma.com/design/8GTvsXFZBoGZ8wSa4vzdSC/Feelit_app`
Export PNG: scale 2x/3x, nền trong suốt.
