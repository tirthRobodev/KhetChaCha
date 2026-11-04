"""Pydantic data models for KhetChacha 300-Crop Agricultural Knowledge Intelligence System."""

from __future__ import annotations

from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class ChemicalTreatmentOption(BaseModel):
    """Verified chemical treatment recommendation conforming strictly to CIBRC & ICAR standards."""
    active_ingredient: str = Field(..., description="Active chemical ingredient name (e.g. 'Chlorantraniliprole').")
    formulation: str = Field(..., description="Formulation strength & type (e.g. '18.5% SC').")
    exact_crop: str = Field(..., description="Target crop for which this label is verified.")
    target_problem: str = Field(..., description="Disease, insect, or pest targeted.")
    jurisdiction: str = Field(default="India (CIBRC / ICAR)", description="Regulatory jurisdiction.")
    registration_status: str = Field(
        default="registered",
        description="'registered', 'label_authorized', or 'not_verified'."
    )
    dose: Optional[str] = Field(default=None, description="Recommended dose value.")
    unit: Optional[str] = Field(default=None, description="Dose unit (e.g. 'ml', 'g', 'kg').")
    dilution: Optional[str] = Field(default=None, description="Water dilution guide (e.g. 'per 15L spray pump' or 'per acre in 200L water').")
    application_method: str = Field(default="Foliar spray", description="Application method (e.g. 'Foliar spray', 'Seed treatment', 'Soil drenching').")
    timing: Optional[str] = Field(default=None, description="Application timing or Economic Threshold Level (ETL).")
    maximum_applications: Optional[int] = Field(default=None, description="Maximum permitted applications per season.")
    pre_harvest_interval_days: Optional[int] = Field(default=None, description="Pre-harvest interval (PHI) in days.")
    re_entry_interval_hours: Optional[int] = Field(default=24, description="Re-entry interval (REI) in hours.")
    ppe_requirements: List[str] = Field(
        default_factory=lambda: ["Chemical-resistant gloves", "Protective face mask", "Eye goggles", "Full-sleeve protective clothing"],
        description="Mandatory Personal Protective Equipment."
    )
    mixing_warnings: List[str] = Field(default_factory=list, description="Chemical incompatibility or phytotoxicity warnings.")
    source_ids: List[str] = Field(default_factory=list, description="Traceable source identifiers from source registry.")


class OrganicTreatmentOption(BaseModel):
    """Certified organic or traditional biological agronomic intervention."""
    treatment_name: str = Field(..., description="Name of organic treatment (e.g. 'Neem Oil (1500 PPM)', 'Trichoderma viride').")
    preparation_or_formulation: Optional[str] = Field(default=None, description="Preparation instructions or bio-formulation type.")
    dosage: Optional[str] = Field(default=None, description="Recommended dosage rate.")
    application_method: str = Field(default="Foliar spray", description="Foliar, seed, or soil application.")
    timing: Optional[str] = Field(default=None, description="Application timing.")
    evidence_level: str = Field(
        default="ICAR_evaluated",
        description="'ICAR_evaluated', 'university_tested', or 'traditional_certified_organic'."
    )
    limitations: List[str] = Field(default_factory=list, description="Limitations or conditions under which treatment is ineffective.")
    source_ids: List[str] = Field(default_factory=list, description="Traceable source identifiers.")


class PlantProblemRecord(BaseModel):
    """Structured agronomic record for diseases, insect pests, and nutrient disorders."""
    problem_id: str = Field(..., description="Stable unique problem ID (e.g. 'cotton_pink_bollworm').")
    crop_id: str = Field(..., description="Stable canonical crop ID (e.g. 'cotton').")
    name: Dict[str, str] = Field(..., description="Multilingual name {'en': '...', 'gu': '...', 'hi': '...'}")
    type: str = Field(
        ...,
        description="Problem classification: 'fungal_disease', 'bacterial_disease', 'viral_disease', "
                    "'oomycete', 'insect_pest', 'mite', 'nematode', 'nutrient_disorder', "
                    "'abiotic_disorder', 'weed', 'post_harvest'."
    )
    causal_agent: Optional[str] = Field(default=None, description="Scientific pathogen or insect binomial (e.g. 'Pectinophora gossypiella').")
    affected_parts: List[str] = Field(default_factory=list, description="Leaves, stems, roots, flowers, pods, bolls, fruits.")
    symptoms: List[str] = Field(default_factory=list, description="Field identification signs.")
    lookalikes: List[str] = Field(default_factory=list, description="Similar disorders to avoid misdiagnosis.")
    favourable_conditions: List[str] = Field(default_factory=list, description="Weather, humidity, temperature fostering problem.")
    season_or_growth_stage: List[str] = Field(default_factory=list, description="Susceptible crop development phases.")
    monitoring_and_confirmation: List[str] = Field(default_factory=list, description="Monitoring traps, scouting frequency, ETL.")
    prevention: List[str] = Field(default_factory=list, description="Preventive agronomic practices.")
    cultural_management: List[str] = Field(default_factory=list, description="Field sanitation, rotation, solarization.")
    mechanical_management: List[str] = Field(default_factory=list, description="Pheromone traps, light traps, clipping, handpicking.")
    biological_management: List[str] = Field(default_factory=list, description="Parasitoids, predators, beneficial microbes.")
    organic_options: List[OrganicTreatmentOption] = Field(default_factory=list, description="Verified organic treatments.")
    chemical_options: List[ChemicalTreatmentOption] = Field(default_factory=list, description="Verified chemical controls with exact doses.")
    resistance_management: List[str] = Field(default_factory=list, description="Pesticide rotation and IRM strategy.")
    expert_referral_conditions: List[str] = Field(
        default_factory=lambda: ["Contact local KVK agronomist or Kisan Call Centre (1800-180-1551) if infestation exceeds threshold."],
        description="Conditions requiring in-person extension referral."
    )
    confidence: str = Field(default="high", description="'high', 'medium', 'low', 'insufficient'.")
    last_verified_date: Optional[str] = Field(default=None, description="ISO timestamp of last verification.")
    source_ids: List[str] = Field(default_factory=list, description="Traceable source identifiers.")


class CropProfile(BaseModel):
    """Complete canonical crop knowledge profile."""
    crop_id: str = Field(..., description="Canonical snake_case ID (e.g. 'cotton').")
    names: Dict[str, Any] = Field(
        ...,
        description="{'en': '...', 'gu': '...', 'hi': '...', 'botanical': '...', 'family': '...', 'aliases': [...]}"
    )
    catalogue_entries: List[int] = Field(default_factory=list, description="Indices from original 1-300 user list.")
    categories: List[str] = Field(default_factory=list, description="Agricultural categories (e.g. ['Commercial and Fibre Crops']).")
    cultivation_relevance: str = Field(default="", description="Economic and agricultural relevance in India.")
    climate_and_soil: Dict[str, Any] = Field(
        default_factory=dict,
        description="Climate type, temperature, rainfall, soil types, optimal pH, drainage."
    )
    suitable_regions: List[str] = Field(default_factory=list, description="Indian states & agro-climatic zones.")
    seasons: List[str] = Field(default_factory=list, description="Growing seasons (Kharif, Rabi, Zaid).")
    planting_details: Dict[str, Any] = Field(
        default_factory=dict,
        description="Sowing time, seed rate, spacing, depth, notable varieties."
    )
    water_management: Dict[str, Any] = Field(
        default_factory=dict,
        description="Critical growth stages, irrigation methods, water requirements."
    )
    nutrient_management: Dict[str, Any] = Field(
        default_factory=dict,
        description="FYM organic manure, recommended NPK, biofertilizers, micronutrients."
    )
    growth_stages: List[str] = Field(default_factory=list, description="Sequential development stages.")
    harvest_and_yield: Dict[str, Any] = Field(
        default_factory=dict,
        description="Maturity duration, harvesting signs, expected yield/acre, storage advice."
    )
    major_problems_summary: Dict[str, List[str]] = Field(
        default_factory=lambda: {"diseases": [], "pests": [], "nutrient_deficiencies": []},
        description="Summary list of major problems."
    )
    status: str = Field(
        default="verified",
        description="'verified', 'partial', 'needs_review', 'researching', 'not_started', 'outdated'."
    )
    last_updated: Optional[str] = Field(default=None, description="ISO timestamp.")
    source_ids: List[str] = Field(default_factory=list, description="Traceable source identifiers.")


class SourceRecord(BaseModel):
    """Authoritative citation document in the source registry."""
    source_id: str = Field(..., description="Unique source slug (e.g. 'icar_cicr_cotton_advisory_2024').")
    title: str = Field(..., description="Official title of bulletin, book, portal, or paper.")
    institution: str = Field(..., description="Publishing body (e.g. 'ICAR-CICR', 'AAU Anand', 'CIBRC').")
    document_type: str = Field(
        default="official_advisory",
        description="'local_pdf', 'official_advisory', 'university_package_of_practices', 'regulatory_label', 'research_paper'."
    )
    url: Optional[str] = Field(default=None, description="Official web address.")
    local_path: Optional[str] = Field(default=None, description="Relative path in ai_engine if archived locally.")
    publication_year: Optional[int] = Field(default=None, description="Year of publication.")
    jurisdiction: str = Field(default="India", description="Geographic jurisdiction.")
    verification_tier: int = Field(default=1, description="1 (ICAR/KVK/SAU/Govt), 2 (Trusted Portal), 3 (General).")


class ResearchJobRecord(BaseModel):
    """Manifest job record for tracking research pipeline progress on a single crop."""
    crop_id: str
    catalogue_entry_number: int
    source_name: str
    canonical_name: str
    status: str = "not_started"  # not_started, researching, partial, needs_review, verified, outdated
    confidence_level: str = "insufficient"
    local_pdf_sources_found: int = 0
    online_sources_found: int = 0
    diseases_recorded: int = 0
    pests_recorded: int = 0
    nutrient_disorders_recorded: int = 0
    chemical_options_verified: int = 0
    organic_options_verified: int = 0
    last_researched_at: Optional[str] = None
    notes: List[str] = Field(default_factory=list)
    error_message: Optional[str] = None

