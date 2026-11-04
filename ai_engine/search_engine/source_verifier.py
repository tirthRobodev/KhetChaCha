"""Source verification and credibility scoring for agricultural evidence."""

from __future__ import annotations

import re
from typing import Optional
from urllib.parse import urlparse

# Authoritative agricultural and government domains in India
TIER_1_AUTHORITY_DOMAINS = {
    # ICAR & KVK
    "icar.org.in",
    "icar.gov.in",
    "kvk.icar.gov.in",
    "cicr.org.in",  # Central Institute for Cotton Research
    "iari.res.in",  # Indian Agricultural Research Institute
    "crida.in",     # Central Research Institute for Dryland Agriculture
    "nbair.res.in", # National Bureau of Agricultural Insect Resources
    # Government Portals & Departments
    "agricoop.nic.in",
    "agricoop.gov.in",
    "farmer.gov.in",
    "cibrc.nic.in",   # Central Insecticides Board & Registration Committee
    "ppqs.gov.in",    # Directorate of Plant Protection, Quarantine & Storage
    "agmarknet.gov.in",
    "enam.gov.in",
    "imd.gov.in",     # India Meteorological Department
    "pmkisan.gov.in",
    "soilhealth.dac.gov.in",
    # State Agricultural Universities (SAUs)
    "aau.in",         # Anand Agricultural University (Gujarat)
    "jau.in",         # Junagadh Agricultural University (Gujarat)
    "nau.in",         # Navsari Agricultural University (Gujarat)
    "sdau.in",        # Sardarkrushinagar Dantiwada Agricultural University (Gujarat)
    "kamdhenuuni.edu.in",
    "pau.edu",        # Punjab Agricultural University
    "tnaun.ac.in",    # Tamil Nadu Agricultural University
    "agritech.tnau.ac.in",
    "uasd.edu",       # University of Agricultural Sciences, Dharwad
    "uasbangalore.edu.in",
    "angrau.ac.in",   # Acharya N.G. Ranga Agricultural University
    "pjtsau.edu.in",  # PJTSAU Telangana
    "hau.ac.in",      # CCS Haryana Agricultural University
    "mpkv.ac.in",     # Mahatma Phule Krishi Vidyapeeth, Maharashtra
    "pdkv.ac.in",     # Dr. PDKV Akola
    "bau.edu.in",     # Birsa Agricultural University
    "yspuniversity.ac.in",
}

TIER_2_AUTHORITY_DOMAINS = {
    "vikaspedia.in",
    "kisanportal.bihar.gov.in",
    "krishi.icar.gov.in",
    "krishisewa.com",
    "agrifarming.in",
    "fao.org",
    "cabi.org",
}

SUSPICIOUS_OR_SPAM_PATTERNS = [
    re.compile(r"buy-cheap-pesticide", re.I),
    re.compile(r"casino|betting|crypto|loan-instant", re.I),
    re.compile(r"free-download-pdf", re.I),
]


class SourceVerifier:
    """Evaluates the authority, domain trust, and safety of source URLs."""

    @staticmethod
    def extract_domain(url: Optional[str]) -> str:
        """Extracts normalized hostname from URL."""
        if not url:
            return ""
        try:
            parsed = urlparse(url)
            netloc = parsed.netloc.lower()
            # Remove port if present
            if ":" in netloc:
                netloc = netloc.split(":")[0]
            # Strip www prefix
            if netloc.startswith("www."):
                netloc = netloc[4:]
            return netloc
        except Exception:
            return ""

    @classmethod
    def get_authority_tier(cls, url: Optional[str]) -> int:
        """Determines authority tier: 1 (Highest ICAR/SAU/Govt), 2 (Trusted Ag Portal), 3 (Standard Web)."""
        domain = cls.extract_domain(url)
        if not domain:
            return 3

        # Check Tier 1
        for auth in TIER_1_AUTHORITY_DOMAINS:
            if domain == auth or domain.endswith("." + auth) or domain.endswith(".gov.in") or domain.endswith(".nic.in"):
                return 1

        # Check Tier 2
        for auth in TIER_2_AUTHORITY_DOMAINS:
            if domain == auth or domain.endswith("." + auth):
                return 2

        return 3

    @classmethod
    def calculate_authority_multiplier(cls, url: Optional[str]) -> float:
        """Returns scoring multiplier based on domain credibility."""
        tier = cls.get_authority_tier(url)
        if tier == 1:
            return 1.4  # 40% boost for ICAR, KVK, Govt, SAU
        elif tier == 2:
            return 1.15 # 15% boost for recognized ag resources
        return 1.0

    @classmethod
    def is_credible_source(cls, url: Optional[str]) -> bool:
        """Validates that a URL is safe and credible."""
        if not url:
            return False
        for pattern in SUSPICIOUS_OR_SPAM_PATTERNS:
            if pattern.search(url):
                return False
        return True

