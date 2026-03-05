#!/usr/bin/env python3
"""
Clean raw eClaim datasets and build optimized reference databases.

Inputs from raw_data:
- *.xls / *.xlsx raw reference files
- xml_input_examples/*.xml sample claim files

Outputs in assets/db_seed:
- reference_seed.sqlite
- seed_manifest.json
- xml_crossmatch_report.json
"""

from __future__ import annotations

import gzip
import json
import re
import sqlite3
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from datetime import date, datetime
from pathlib import Path
from typing import Any

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "raw_data"
XML_EXAMPLES_DIR = ROOT / "raw_data" / "xml_input_examples"
OUT_DIR = ROOT / "assets" / "db_seed"


def _to_text(value: Any) -> str:
    if pd.isna(value):
        return ""
    return str(value).strip()


def _normalize_numeric_code(code: str) -> str:
    raw = code.strip()
    if not raw:
        return ""
    if not re.fullmatch(r"[-+]?\d+(\.\d+)?", raw):
        return raw.upper()
    negative = raw.startswith("-")
    if negative:
        raw = raw[1:]
    if "." in raw:
        left, right = raw.split(".", 1)
        right = right.rstrip("0")
        raw = left if not right else f"{left}.{right}"
    if negative:
        raw = f"-{raw}"
    return raw


def _normalize_cpt_code(code: str) -> str:
    raw = _to_text(code)
    if not raw:
        return ""
    if re.fullmatch(r"\d+(\.0+)?", raw):
        numeric = str(int(float(raw)))
        return numeric.zfill(5)
    return raw.upper()


def _normalize_icd_code(code: str) -> str:
    return _to_text(code).upper()


def _normalize_service_code(service_type: str, code: str) -> str:
    clean = _to_text(code)
    if not clean:
        return ""
    st = service_type.upper()
    if st == "CPT":
        return _normalize_cpt_code(clean)
    if st == "DSL":
        return _normalize_numeric_code(clean)
    return clean.upper()


def _bool_to_int(value: Any) -> int:
    if isinstance(value, bool):
        return 1 if value else 0
    txt = _to_text(value).lower()
    if txt in {"1", "true", "t", "yes", "y", "active"}:
        return 1
    return 0


def _parse_date(value: Any) -> date | None:
    if value is None or pd.isna(value):
        return None
    if isinstance(value, datetime):
        return value.date()
    txt = _to_text(value)
    if not txt:
        return None
    for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%m/%d/%Y"):
        try:
            return datetime.strptime(txt[:10], fmt).date()
        except ValueError:
            continue
    return None


def _is_active_until(value: Any, today: date) -> bool:
    dt = _parse_date(value)
    if dt is None:
        return True
    return dt >= today


def _write_json(path: Path, obj: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding="utf-8")


def _gzip_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    with src.open("rb") as fin, gzip.open(dst, "wb", compresslevel=9) as fout:
        while True:
            chunk = fin.read(1024 * 1024)
            if not chunk:
                break
            fout.write(chunk)


def _dedupe_rows(rows: list[dict[str, Any]], key_fields: tuple[str, ...]) -> list[dict[str, Any]]:
    dedup: dict[tuple[Any, ...], dict[str, Any]] = {}
    for row in rows:
        key = tuple(row[k] for k in key_fields)
        current = dedup.get(key)
        if current is None:
            dedup[key] = row
            continue
        current_score = (int(current.get("active", 1)), len(_to_text(current.get("full_desc"))))
        row_score = (int(row.get("active", 1)), len(_to_text(row.get("full_desc"))))
        if row_score > current_score:
            dedup[key] = row
    return list(dedup.values())


def build_service_codes(today: date) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []

    cpt = pd.read_excel(
        RAW_DIR / "CPT_2021_20230703.xlsx",
        sheet_name="CPT_2021",
        usecols=["CPT_CODE", "SHORT_DESCRIPTION", "LONG_DESCRIPTION", "FULL_DESCRIPTION"],
    )
    for rec in cpt.to_dict(orient="records"):
        code_norm = _normalize_cpt_code(rec.get("CPT_CODE"))
        if not code_norm:
            continue
        short_desc = _to_text(rec.get("SHORT_DESCRIPTION"))
        full_desc = _to_text(rec.get("FULL_DESCRIPTION")) or _to_text(rec.get("LONG_DESCRIPTION")) or short_desc
        rows.append(
            {
                "service_type": "CPT",
                "code": code_norm,
                "code_normalized": code_norm,
                "short_desc": short_desc or full_desc,
                "full_desc": full_desc or short_desc,
                "active": 1,
            }
        )

    cdt = pd.read_excel(
        RAW_DIR / "CDT_2018.xls",
        sheet_name="CDT Codes",
        usecols=["Code", "Nomenclature", "Description"],
    )
    for rec in cdt.to_dict(orient="records"):
        code = _to_text(rec.get("Code")).upper()
        if not code:
            continue
        short_desc = _to_text(rec.get("Nomenclature"))
        full_desc = _to_text(rec.get("Description")) or short_desc
        rows.append(
            {
                "service_type": "CDT",
                "code": code,
                "code_normalized": code,
                "short_desc": short_desc or full_desc,
                "full_desc": full_desc or short_desc,
                "active": 1,
            }
        )

    dsl = pd.read_excel(
        RAW_DIR / "Dubai Special Services 20250616.xlsx",
        sheet_name="Dubai Special Services",
        usecols=["Code", "Description", "Detailed Description", "activeTo"],
    )
    for rec in dsl.to_dict(orient="records"):
        code_raw = _to_text(rec.get("Code"))
        code_norm = _normalize_numeric_code(code_raw)
        if not code_norm:
            continue
        active = 1 if _is_active_until(rec.get("activeTo"), today) else 0
        if not active:
            continue
        short_desc = _to_text(rec.get("Description"))
        full_desc = _to_text(rec.get("Detailed Description")) or short_desc
        rows.append(
            {
                "service_type": "DSL",
                "code": code_raw,
                "code_normalized": code_norm,
                "short_desc": short_desc or full_desc,
                "full_desc": full_desc or short_desc,
                "active": 1,
            }
        )

    drugs = pd.read_excel(
        RAW_DIR / "Dubai_Drug_Code_DDC_List_20260303_075140.xlsx",
        sheet_name="Table Export",
        usecols=["STATUS", "DDC_CODE", "TRADE_NAME", "SCIENTIFIC_NAME"],
    )
    for rec in drugs.to_dict(orient="records"):
        status = _to_text(rec.get("STATUS")).lower()
        if not status.startswith("active"):
            continue
        code = _to_text(rec.get("DDC_CODE")).upper()
        if not code:
            continue
        short_desc = _to_text(rec.get("TRADE_NAME"))
        full_desc = _to_text(rec.get("SCIENTIFIC_NAME")) or short_desc
        rows.append(
            {
                "service_type": "DRUG",
                "code": code,
                "code_normalized": code,
                "short_desc": short_desc or full_desc,
                "full_desc": full_desc or short_desc,
                "active": 1,
            }
        )

    return _dedupe_rows(rows, ("service_type", "code_normalized"))


def build_icd10() -> list[dict[str, Any]]:
    df = pd.read_excel(
        RAW_DIR / "ICD10-CM_2021_20230703.xlsx",
        sheet_name="icd10cm_order_2021_only_Valid",
        usecols=["Code", "ShortDesc", "LongDesc"],
    )
    rows: list[dict[str, Any]] = []
    for rec in df.to_dict(orient="records"):
        code = _normalize_icd_code(rec.get("Code"))
        if not code:
            continue
        short_desc = _to_text(rec.get("ShortDesc"))
        full_desc = _to_text(rec.get("LongDesc")) or short_desc
        rows.append(
            {
                "code": code,
                "code_normalized": code.replace(".", ""),
                "short_desc": short_desc or full_desc,
                "full_desc": full_desc or short_desc,
                "active": 1,
            }
        )
    return rows


def build_payers() -> list[dict[str, Any]]:
    df = pd.read_excel(
        RAW_DIR / "eClaimLinkPayers20260115.xlsx",
        sheet_name="Payers",
        usecols=["eClaimLink ID", "Name", "Classification"],
    )
    rows: list[dict[str, Any]] = []
    for rec in df.to_dict(orient="records"):
        payer_id = _to_text(rec.get("eClaimLink ID")).upper()
        if not payer_id:
            continue
        rows.append(
            {
                "payer_id": payer_id,
                "name": _to_text(rec.get("Name")),
                "classification": _to_text(rec.get("Classification")),
            }
        )
    dedup = {row["payer_id"]: row for row in rows}
    return list(dedup.values())


def build_specialties() -> list[dict[str, Any]]:
    df = pd.read_excel(
        RAW_DIR / "eClaimLink Speciality Codes 20211004.xlsx",
        sheet_name="MAIN",
        usecols=["eClaimLink Code", "Speciality/Subspecialty/Appellation"],
    )
    rows: list[dict[str, Any]] = []
    for rec in df.to_dict(orient="records"):
        sid = _to_text(rec.get("eClaimLink Code")).upper()
        if not sid:
            continue
        rows.append(
            {
                "specialty_id": sid,
                "description": _to_text(rec.get("Speciality/Subspecialty/Appellation")),
            }
        )
    dedup = {row["specialty_id"]: row for row in rows}
    return list(dedup.values())


def build_clinicians() -> list[dict[str, Any]]:
    path = RAW_DIR / "eClaimlinkClinicians_20260305_080024.xlsx"
    xls = pd.ExcelFile(path)
    frames: list[pd.DataFrame] = []
    usecols = [
        "eClaimLink ID",
        "Professional Name",
        "Status",
        "eClaimLink Specialty ID",
        "eClaimLink Specialty Description",
    ]
    for sheet in xls.sheet_names:
        df = pd.read_excel(path, sheet_name=sheet, usecols=usecols)
        df["source_sheet"] = sheet
        frames.append(df)

    all_df = pd.concat(frames, ignore_index=True)
    all_df["clinician_id"] = all_df["eClaimLink ID"].map(_to_text).str.upper()
    all_df["professional_name"] = all_df["Professional Name"].map(_to_text)
    all_df["status_num"] = all_df["Status"].map(_bool_to_int)
    all_df["specialty_id"] = all_df["eClaimLink Specialty ID"].map(_to_text).str.upper()
    all_df["specialty_description"] = all_df["eClaimLink Specialty Description"].map(_to_text)
    all_df["source_sheet"] = all_df["source_sheet"].map(_to_text)

    all_df = all_df[(all_df["clinician_id"] != "") & (all_df["status_num"] == 1)].copy()
    all_df["specialty_score"] = all_df["specialty_id"].str.len().fillna(0)
    all_df["name_score"] = all_df["professional_name"].str.len().fillna(0)
    all_df = all_df.sort_values(
        by=["specialty_score", "name_score"],
        ascending=[False, False],
    )
    best = all_df.drop_duplicates(subset=["clinician_id"], keep="first")

    return [
        {
            "clinician_id": row.clinician_id,
            "professional_name": row.professional_name,
            "status": 1,
            "specialty_id": row.specialty_id,
            "specialty_description": row.specialty_description,
            "source_sheet": row.source_sheet,
        }
        for row in best.itertuples(index=False)
    ]


def build_xml_crossmatch(
    service_codes: list[dict[str, Any]],
    icd10_codes: list[dict[str, Any]],
    payers: list[dict[str, Any]],
    clinicians: list[dict[str, Any]],
) -> dict[str, Any]:
    service_index = {
        (row["service_type"], row["code_normalized"]): row for row in service_codes
    }
    icd_index = {row["code"] for row in icd10_codes}
    payer_index = {row["payer_id"] for row in payers}
    clinician_index = {row["clinician_id"] for row in clinicians}

    type_map = {"3": "CPT", "6": "CDT", "8": "DSL", "5": "DRUG"}
    xml_activity_codes: defaultdict[str, set[str]] = defaultdict(set)
    xml_diag_codes: set[str] = set()
    xml_payer_ids: set[str] = set()
    xml_receiver_ids: set[str] = set()
    xml_clinician_ids: set[str] = set()
    file_claim_counts: dict[str, int] = {}

    for xf in sorted(XML_EXAMPLES_DIR.glob("*.xml")):
        root = ET.parse(xf).getroot()
        claims = root.findall("Claim")
        file_claim_counts[xf.name] = len(claims)
        receiver = _to_text(root.findtext("./Header/ReceiverID")).upper()
        if receiver:
            xml_receiver_ids.add(receiver)

        for claim in claims:
            payer_id = _to_text(claim.findtext("PayerID")).upper()
            if payer_id:
                xml_payer_ids.add(payer_id)

            for diag in claim.findall("Diagnosis"):
                code = _normalize_icd_code(diag.findtext("Code"))
                if code:
                    xml_diag_codes.add(code)

            for act in claim.findall("Activity"):
                act_type = _to_text(act.findtext("Type"))
                act_code = _to_text(act.findtext("Code"))
                clinician_id = _to_text(act.findtext("Clinician")).upper()
                if clinician_id:
                    xml_clinician_ids.add(clinician_id)
                if act_type and act_code and act_type in type_map:
                    service_type = type_map[act_type]
                    xml_activity_codes[service_type].add(act_code)

    service_missing: dict[str, list[str]] = {}
    for service_type, codes in xml_activity_codes.items():
        missing: list[str] = []
        for code in sorted(codes):
            norm = _normalize_service_code(service_type, code)
            if (service_type, norm) not in service_index:
                missing.append(code)
        service_missing[service_type] = missing

    icd_missing = sorted([code for code in xml_diag_codes if code not in icd_index])
    payer_missing = sorted(
        [pid for pid in (xml_payer_ids | xml_receiver_ids) if pid not in payer_index]
    )
    clinician_missing = sorted([cid for cid in xml_clinician_ids if cid not in clinician_index])

    return {
        "xml_files": file_claim_counts,
        "summary": {
            "unique_activity_codes_by_type": {k: len(v) for k, v in sorted(xml_activity_codes.items())},
            "unique_diagnosis_codes": len(xml_diag_codes),
            "unique_payer_ids": len(xml_payer_ids),
            "unique_receiver_ids": len(xml_receiver_ids),
            "unique_clinician_ids": len(xml_clinician_ids),
        },
        "coverage": {
            "service_missing": service_missing,
            "icd_missing": icd_missing,
            "payer_missing": payer_missing,
            "clinician_missing": clinician_missing,
        },
    }


def build_reference_sqlite(
    sqlite_path: Path,
    service_codes: list[dict[str, Any]],
    icd10_codes: list[dict[str, Any]],
    payers: list[dict[str, Any]],
    specialties: list[dict[str, Any]],
    clinicians: list[dict[str, Any]],
) -> None:
    if sqlite_path.exists():
        sqlite_path.unlink()
    conn = sqlite3.connect(sqlite_path)
    cur = conn.cursor()

    cur.executescript(
        """
        PRAGMA journal_mode = OFF;
        PRAGMA synchronous = OFF;
        PRAGMA temp_store = MEMORY;

        CREATE TABLE service_codes(
          service_type TEXT NOT NULL,
          code TEXT NOT NULL,
          code_normalized TEXT NOT NULL,
          short_desc TEXT NOT NULL,
          full_desc TEXT NOT NULL,
          active INTEGER NOT NULL DEFAULT 1,
          PRIMARY KEY(service_type, code_normalized)
        );
        CREATE INDEX idx_service_type_code ON service_codes(service_type, code);
        CREATE INDEX idx_service_type_code_norm ON service_codes(service_type, code_normalized);

        CREATE TABLE icd10_codes(
          code TEXT PRIMARY KEY,
          code_normalized TEXT NOT NULL,
          short_desc TEXT NOT NULL,
          full_desc TEXT NOT NULL,
          active INTEGER NOT NULL DEFAULT 1
        );
        CREATE INDEX idx_icd10_code_norm ON icd10_codes(code_normalized);

        CREATE TABLE payers(
          payer_id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          classification TEXT
        );

        CREATE TABLE specialties(
          specialty_id TEXT PRIMARY KEY,
          description TEXT NOT NULL
        );

        CREATE TABLE clinicians(
          clinician_id TEXT PRIMARY KEY,
          professional_name TEXT NOT NULL,
          status INTEGER NOT NULL DEFAULT 1,
          specialty_id TEXT,
          specialty_description TEXT,
          source_sheet TEXT
        );
        CREATE INDEX idx_clinician_name ON clinicians(professional_name);
        """
    )

    cur.executemany(
        """
        INSERT OR REPLACE INTO service_codes(
          service_type, code, code_normalized, short_desc, full_desc, active
        ) VALUES(?,?,?,?,?,?)
        """,
        [
            (
                row["service_type"],
                row["code"],
                row["code_normalized"],
                row["short_desc"],
                row["full_desc"],
                row["active"],
            )
            for row in service_codes
        ],
    )

    cur.executemany(
        """
        INSERT OR REPLACE INTO icd10_codes(
          code, code_normalized, short_desc, full_desc, active
        ) VALUES(?,?,?,?,?)
        """,
        [
            (
                row["code"],
                row["code_normalized"],
                row["short_desc"],
                row["full_desc"],
                row["active"],
            )
            for row in icd10_codes
        ],
    )

    cur.executemany(
        "INSERT OR REPLACE INTO payers(payer_id, name, classification) VALUES(?,?,?)",
        [(row["payer_id"], row["name"], row["classification"]) for row in payers],
    )
    cur.executemany(
        "INSERT OR REPLACE INTO specialties(specialty_id, description) VALUES(?,?)",
        [(row["specialty_id"], row["description"]) for row in specialties],
    )
    cur.executemany(
        """
        INSERT OR REPLACE INTO clinicians(
          clinician_id, professional_name, status, specialty_id, specialty_description, source_sheet
        ) VALUES(?,?,?,?,?,?)
        """,
        [
            (
                row["clinician_id"],
                row["professional_name"],
                row["status"],
                row["specialty_id"],
                row["specialty_description"],
                row["source_sheet"],
            )
            for row in clinicians
        ],
    )

    # DB user_version should match app schema version.
    cur.execute("PRAGMA user_version = 4")
    conn.commit()
    conn.close()


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    today = date.today()

    service_codes = build_service_codes(today=today)
    icd10_codes = build_icd10()
    payers = build_payers()
    specialties = build_specialties()
    clinicians = build_clinicians()
    crossmatch = build_xml_crossmatch(service_codes, icd10_codes, payers, clinicians)

    _write_json(OUT_DIR / "xml_crossmatch_report.json", crossmatch)

    sqlite_path = OUT_DIR / "reference_seed.sqlite"
    build_reference_sqlite(
        sqlite_path=sqlite_path,
        service_codes=service_codes,
        icd10_codes=icd10_codes,
        payers=payers,
        specialties=specialties,
        clinicians=clinicians,
    )
    sqlite_gz_path = OUT_DIR / "reference_seed.sqlite.gz"
    _gzip_file(sqlite_path, sqlite_gz_path)
    sqlite_path.unlink(missing_ok=True)

    manifest = {
        "generated_from": {
            "raw_dir": str(RAW_DIR.relative_to(ROOT)),
            "xml_examples_dir": str(XML_EXAMPLES_DIR.relative_to(ROOT)),
        },
        "cleanup_rules": {
            "dsl": "Removed inactive rows using activeTo < today",
            "drug": "Kept only STATUS starting with Active",
            "clinicians": "Kept only active status and deduplicated by clinician_id",
            "columns": "Dropped date/version/price/source and other non-lookup columns",
        },
        "counts": {
            "service_codes": len(service_codes),
            "service_codes_by_type": dict(Counter(row["service_type"] for row in service_codes)),
            "icd10_codes": len(icd10_codes),
            "payers": len(payers),
            "specialties": len(specialties),
            "clinicians": len(clinicians),
        },
        "artifacts": {
            "sqlite_seed_gz": str(sqlite_gz_path.relative_to(ROOT)),
        },
        "crossmatch": {
            "service_missing_total": sum(len(v) for v in crossmatch["coverage"]["service_missing"].values()),
            "icd_missing_total": len(crossmatch["coverage"]["icd_missing"]),
            "payer_missing_total": len(crossmatch["coverage"]["payer_missing"]),
            "clinician_missing_total": len(crossmatch["coverage"]["clinician_missing"]),
        },
    }

    _write_json(OUT_DIR / "seed_manifest.json", manifest)
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
