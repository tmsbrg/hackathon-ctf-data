#!/usr/bin/env python3
"""Generate advanced CTF artifacts: scanned PDF, PNG, XLSX, EML, EXIF JPG, nested 7z."""
from __future__ import annotations

import os
import random
import subprocess
import textwrap
from pathlib import Path

from openpyxl import Workbook
from PIL import Image, ImageDraw, ImageFont
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

DUMP = Path(os.environ["DUMP"])
DEJAVU = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
NOTO_CJK = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"


def load_font(path: str, size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def add_scan_noise(img: Image.Image) -> Image.Image:
    """Light speckle so the page looks scanned rather than digitally perfect."""
    pixels = img.load()
    rng = random.Random(42)
    for _ in range(8000):
        x = rng.randint(0, img.width - 1)
        y = rng.randint(0, img.height - 1)
        base = pixels[x, y]
        delta = rng.randint(-18, 18)
        pixels[x, y] = tuple(max(0, min(255, c + delta)) for c in base)
    return img


def make_scanned_pdf(out_path: Path, lines: list[str]) -> None:
    """Image-only PDF — no text layer; needs OCR or visual inspection."""
    img = Image.new("RGB", (850, 1100), color=(248, 246, 242))
    draw = ImageDraw.Draw(img)
    title_font = load_font(DEJAVU, 22)
    body_font = load_font(DEJAVU, 20)

    draw.text((60, 50), "NORDWIND LOGISTICS BV", fill=(40, 40, 40), font=title_font)
    draw.text((60, 85), "HR — Contract scan (fax archive)", fill=(80, 80, 80), font=body_font)

    y = 160
    for line in lines:
        draw.text((60, y), line, fill=(25, 25, 25), font=body_font)
        y += 36

    add_scan_noise(img)
    png_tmp = out_path.with_name(out_path.stem + "_render.png")
    img.save(png_tmp)

    pdf = canvas.Canvas(str(out_path), pagesize=A4)
    pdf.drawImage(str(png_tmp), 25, 120, width=545, height=700)
    pdf.save()
    png_tmp.unlink(missing_ok=True)


def make_terminal_screenshot(out_path: Path) -> None:
    """Fake WMS terminal screenshot — text is pixels only."""
    w, h = 1024, 640
    img = Image.new("RGB", (w, h), color=(24, 28, 32))
    draw = ImageDraw.Draw(img)
    mono = load_font(DEJAVU, 16)
    cjk = load_font(NOTO_CJK, 22)

    draw.rectangle([0, 0, w, 36], fill=(0, 90, 160))
    draw.text((12, 8), "Nordwind WMS — Shanghai CN-SHA-01", fill=(255, 255, 255), font=mono)

    lines = [
        (40, 70, "C:\\wms> login wms_service", mono, (180, 220, 180)),
        (40, 100, "[OK] Session established", mono, (140, 200, 140)),
        (40, 150, "Integration settings (do not share):", mono, (200, 200, 200)),
        (40, 190, "用户名: wms_service", cjk, (220, 220, 220)),
        (40, 230, "密码: ShaWMS-2024-Rot", cjk, (0, 255, 120)),
        (40, 270, "API endpoint: wms.nordwind-logistics.cn", mono, (160, 160, 160)),
        (40, 520, "Photo taken by li.wei — 2024-08-14 (Slack upload)", mono, (100, 100, 100)),
    ]
    for x, y, text, font, color in lines:
        draw.text((x, y), text, fill=color, font=font)

    img.save(out_path)


def make_hidden_sheet_xlsx(out_path: Path) -> None:
    wb = Workbook()
    visible = wb.active
    visible.title = "Salary Bands"
    visible.append(["Grade", "Role", "Min EUR", "Max EUR"])
    visible.append(["L1", "Warehouse associate", 2800, 3400])
    visible.append(["L2", "Coordinator", 3400, 4200])
    visible.append(["L3", "Team lead", 4200, 5200])
    visible.append(["L4", "Manager", 5200, 7200])

    hidden = wb.create_sheet("geheim")
    hidden.sheet_state = "hidden"
    hidden["A1"] = "Bonus pool API key (Exact Online integration)"
    hidden["A2"] = "fin_api_NwQ3_8842secret"
    hidden["A3"] = "Rotated Q1 2025 — delete this sheet after migration"

    wb.save(out_path)


def make_helpdesk_eml(out_path: Path) -> None:
    out_path.write_text(
        textwrap.dedent(
            """\
            From: helpdesk@nordwind-logistics.nl
            To: m.vandenberg@nordwind-logistics.nl
            Subject: RE: Executive portal password reset
            Date: Thu, 7 Nov 2024 09:41:22 +0100
            Message-ID: <IT-8842-reset-vdb@nw-dc01>
            Content-Type: text/plain; charset=utf-8

            Beste Mark,

            Zoals gevraagd tijdelijke toegang tot het executive portal
            (billing dashboard) tot uw VPN-provisioning morgen af is.

            URL: https://portal.nordwind-logistics.nl/exec
            Gebruikersnaam: m.vandenberg

            Tijdelijk_wachtwoord: PortalReset-2024-xK9

            Wijzig dit wachtwoord bij eerste login. Dit bericht na
            activatie verwijderen a.u.b.

            Met vriendelijke groet,
            IT Helpdesk Nordwind Logistics
            """
        ),
        encoding="utf-8",
    )


def make_office_party_jpg(out_path: Path) -> None:
    """Decoy-looking party photo; real secret lives in EXIF metadata."""
    img = Image.new("RGB", (640, 480), color=(70, 110, 160))
    draw = ImageDraw.Draw(img)
    font = load_font(DEJAVU, 28)
    draw.text((80, 200), "Nordwind Summer BBQ 2024", fill=(255, 255, 255), font=font)
    draw.text((120, 250), "(everyone says cheese)", fill=(220, 220, 220), font=load_font(DEJAVU, 16))
    img.save(out_path, quality=85)

    subprocess.run(
        [
            "exiftool",
            "-overwrite_original",
            "-ImageDescription=Nordwind HQ terrace, August 2024",
            "-UserComment=bonus_flag: BONUS{exif_metadata_dig}",
            "-Artist=Marketing Team",
            str(out_path),
        ],
        check=True,
        capture_output=True,
    )


def make_nested_7z_zip(out_path: Path) -> None:
    """ZIP containing 7z — rga cannot recurse into 7z; needs manual 7z extract."""
    tmp = out_path.parent / ".tmp_7z_build"
    if tmp.exists():
        import shutil

        shutil.rmtree(tmp)
    tmp.mkdir(parents=True)

    inner_txt = tmp / "oracle_legacy.txt"
    inner_txt.write_text(
        textwrap.dedent(
            """\
            Nordwind Logistics — Legacy Oracle ERP (decommissioned 2019)
            =============================================================
            Host: nw-oracle-legacy.internal
            SID: NWERP
            Service account (DO NOT USE — archival reference only):

              user=SYSBACKUP
              password=OrclNw2019!sys

            Migrated to PostgreSQL 2020. Retained for audit trail only.
            """
        ),
        encoding="utf-8",
    )

    seven_z = tmp / "configs.7z"
    subprocess.run(["7z", "a", "-t7z", str(seven_z), str(inner_txt)], check=True, capture_output=True)

    outer_readme = tmp / "README.txt"
    outer_readme.write_text(
        "Legacy Oracle configs archive — 2019 decommission project.\n"
        "Inner archive: configs.7z (use 7z x configs.7z to extract).\n",
        encoding="utf-8",
    )

    subprocess.run(
        ["zip", "-q", "-j", str(out_path), str(outer_readme), str(seven_z)],
        check=True,
    )

    import shutil

    shutil.rmtree(tmp)


def main() -> None:
    DUMP.mkdir(parents=True, exist_ok=True)

    make_scanned_pdf(
        DUMP / "HR/exit_interviews/Mulder_contract_scan.pdf",
        [
            "Contractor agreement — Erik Mulder",
            "Department: Operations (temp)",
            "Start date: 14 February 2023",
            "",
            "BSN (burgerservicenummer): 147258364",
            "",
            "Hourly rate: EUR 42,50",
            "Signed: _________________________",
        ],
    )

    make_terminal_screenshot(DUMP / "China_Office/training/wms_terminal_screenshot.png")
    make_hidden_sheet_xlsx(DUMP / "Finance/payroll/salary_bands_2024.xlsx")
    make_helpdesk_eml(DUMP / "IT/tickets/helpdesk_reset_vandenberg.eml")
    make_office_party_jpg(DUMP / "Shared/office_party_2024.jpg")
    make_nested_7z_zip(DUMP / "IT/backups/legacy_oracle_2019.zip")

    print("Advanced artifacts generated (PDF scan, PNG, XLSX, EML, JPG+EXIF, zip>7z).")


if __name__ == "__main__":
    main()
