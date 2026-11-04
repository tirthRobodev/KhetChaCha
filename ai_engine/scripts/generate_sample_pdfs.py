"""Utility script to generate official-style sample agricultural advisory PDFs for indexing."""

from __future__ import annotations

import sys
from pathlib import Path

# Add project root to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer

from ai_engine.backend.config import get_settings


def create_cotton_advisory_pdf(output_path: Path):
    doc = SimpleDocTemplate(str(output_path), pagesize=letter, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        "DocTitle",
        parent=styles["Heading1"],
        fontSize=16,
        leading=20,
        textColor=colors.HexColor("#1b5e20"),
        alignment=1,
    )
    subtitle_style = ParagraphStyle(
        "DocSubTitle",
        parent=styles["Normal"],
        fontSize=11,
        leading=14,
        textColor=colors.HexColor("#2e7d32"),
        alignment=1,
    )
    h2_style = ParagraphStyle(
        "DocH2",
        parent=styles["Heading2"],
        fontSize=12,
        leading=16,
        textColor=colors.HexColor("#2e7d32"),
        spaceBefore=10,
        spaceAfter=6,
    )
    body_style = ParagraphStyle(
        "DocBody",
        parent=styles["Normal"],
        fontSize=10,
        leading=14,
        textColor=colors.HexColor("#212121"),
    )

    story = []
    story.append(Paragraph("ICAR - CENTRAL INSTITUTE FOR COTTON RESEARCH (CICR)", title_style))
    story.append(Paragraph("National Agricultural Advisory Bulletin: Comprehensive Cotton Health & Pest Management", subtitle_style))
    story.append(Spacer(1, 15))

    story.append(Paragraph("1. Cotton Leaf Yellowing and Chlorosis Management", h2_style))
    p1 = (
        "Leaf yellowing (chlorosis) in cotton is primarily caused by micronutrient deficiency, specifically Magnesium "
        "deficiency or Nitrogen deficiency, often exacerbated by waterlogging. When veins remain green while interveinal "
        "areas turn pale yellow or reddish (known locally as Lalio in Gujarat), foliar nutrition is urgent. "
        "Recommended Advisory: Spray Magnesium Sulphate (MgSO4) @ 10 grams per liter of water (150 grams per 15-liter pump) "
        "along with Urea @ 10-15 grams per liter. Apply 2 sprays at 15-day intervals during flowering and boll development."
    )
    story.append(Paragraph(p1, body_style))
    story.append(Spacer(1, 10))

    story.append(Paragraph("2. Pink Bollworm (Pectinophora gossypiella) Control Strategy", h2_style))
    p2 = (
        "Pink bollworm is a destructive pest causing rosetted flowers and locule damage. Monitoring must begin 45 days after sowing. "
        "Install pheromone traps @ 5 traps per acre with Gossyplure lures. If trap catches exceed 8 moths per night for 3 consecutive days "
        "or 10% rosette flowers are observed, initiate chemical intervention. "
        "Recommended Spray: Emamectin Benzoate 5% SG @ 9-10 grams per 15-liter spray pump (200 g/ha) OR Chlorantraniliprole 18.5% SC @ 6-7 ml "
        "per 15-liter spray pump. Avoid continuous use of synthetic pyrethroids to prevent pest resistance."
    )
    story.append(Paragraph(p2, body_style))
    story.append(Spacer(1, 10))

    story.append(Paragraph("3. Sucking Pests (Aphids, Jassids, and Thrips)", h2_style))
    p3 = (
        "Sucking pests infest the undersides of cotton leaves, draining sap and causing downward leaf curling, yellowing, and stunted growth. "
        "Bio-control Action: Spray commercial Neem Seed Kernel Extract (NSKE 5%) or Neem Oil (1500 PPM) @ 45-50 ml per 15-liter spray pump. "
        "Chemical Intervention: If pest population exceeds Economic Threshold Level (ETL) of 5 nymphs per leaf, spray Imidacloprid 17.8% SL "
        "@ 4-5 ml per 15-liter spray pump or Thiamethoxam 25% WG @ 6-8 grams per 15-liter pump."
    )
    story.append(Paragraph(p3, body_style))
    story.append(Spacer(1, 10))

    story.append(Paragraph("4. Agro-Chemical Safety and Personal Protective Equipment (PPE)", h2_style))
    p4 = (
        "Farmer Safety Protocol: Always wear personal protective equipment including face mask, safety goggles, rubber gloves, and protective clothing. "
        "Always spray in the direction of the wind; never spray against wind direction. Spray strictly during cool hours (morning before 10 AM or evening after 4 PM). "
        "Strictly avoid banned compounds including Endosulfan and Monocrotophos. Maintain a mandatory 15-day pre-harvest interval (PHI)."
    )
    story.append(Paragraph(p4, body_style))

    doc.build(story)
    print(f"Generated: {output_path}")


def create_groundnut_guide_pdf(output_path: Path):
    doc = SimpleDocTemplate(str(output_path), pagesize=letter, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        "DocTitle",
        parent=styles["Heading1"],
        fontSize=15,
        leading=18,
        textColor=colors.HexColor("#0d47a1"),
        alignment=1,
    )
    subtitle_style = ParagraphStyle(
        "DocSubTitle",
        parent=styles["Normal"],
        fontSize=10,
        leading=13,
        textColor=colors.HexColor("#1565c0"),
        alignment=1,
    )
    h2_style = ParagraphStyle(
        "DocH2",
        parent=styles["Heading2"],
        fontSize=12,
        leading=15,
        textColor=colors.HexColor("#1565c0"),
        spaceBefore=8,
        spaceAfter=4,
    )
    body_style = ParagraphStyle(
        "DocBody",
        parent=styles["Normal"],
        fontSize=10,
        leading=14,
        textColor=colors.HexColor("#212121"),
    )

    story = []
    story.append(Paragraph("ANAND AGRICULTURAL UNIVERSITY (AAU)", title_style))
    story.append(Paragraph("Department of Plant Pathology - Groundnut Disease Advisory", subtitle_style))
    story.append(Spacer(1, 15))

    story.append(Paragraph("1. Tikka Leaf Spot (Cercospora) and Rust Management", h2_style))
    p1 = (
        "Groundnut Tikka disease produces circular dark brown to black spots with yellow halos on leaves, resulting in premature leaf shed. "
        "Management: At first appearance of spots (usually 35-40 days after sowing), spray Mancozeb 75% WP @ 30-35 grams per 15-liter pump "
        "or Hexaconazole 5% EC @ 25-30 ml per 15-liter pump. Repeat after 15 days if cloudy humid weather persists."
    )
    story.append(Paragraph(p1, body_style))
    story.append(Spacer(1, 10))

    story.append(Paragraph("2. Collar Rot and Stem Rot (Sclerotium rolfsii)", h2_style))
    p2 = (
        "Collar rot causes sudden seedling wilting with white mycelial growth and mustard-seed like sclerotia at the soil line. "
        "Bio-fungicide Treatment: Apply Trichoderma viride @ 50-60 grams per 15-liter pump around root zones or mix 2.5 kg Trichoderma with "
        "500 kg well-decomposed farmyard manure (FYM) per acre prior to sowing. Avoid excessive irrigation that stagnates water around collars."
    )
    story.append(Paragraph(p2, body_style))

    doc.build(story)
    print(f"Generated: {output_path}")


def main():
    settings = get_settings()
    pdf_dir = settings.pdf_dir
    pdf_dir.mkdir(parents=True, exist_ok=True)

    cotton_pdf = pdf_dir / "ICAR_CICR_Cotton_Crop_Advisory.pdf"
    groundnut_pdf = pdf_dir / "AAU_Groundnut_Disease_Management_Guide.pdf"

    create_cotton_advisory_pdf(cotton_pdf)
    create_groundnut_guide_pdf(groundnut_pdf)
    print("[SUCCESS] Sample agricultural PDFs generated successfully.")


if __name__ == "__main__":
    main()
