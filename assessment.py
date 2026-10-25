"""Backend-only assessment policy. These are configurable rules, not trained predictions."""
import json
from datetime import date, datetime, timezone, timedelta
from pathlib import Path

CONFIG = json.loads((Path(__file__).parent / "assessment_config.json").read_text(encoding="utf-8"))


def severity_for(area_ratio):
    thresholds = CONFIG["severity"]
    if area_ratio < thresholds["minor_below"]:
        return "minor"
    if area_ratio <= thresholds["moderate_through"]:
        return "moderate"
    return "severe"


def grade_for(score):
    return next(grade for threshold, grade in CONFIG["scoring"]["grades"] if score >= threshold)


def score_for(detections):
    policy = CONFIG["scoring"]
    deduction = sum(
        policy["deductions"].get(item["type"], policy["default_deduction"])
        * policy["multipliers"][item["severity"]]
        for item in detections
    )
    return max(policy["minimum"], min(policy["maximum"], round(policy["initial"] - deduction)))


def care_for(fabric_type, detections):
    policy = CONFIG["care"]
    care = dict(policy["fabrics"].get(fabric_type.lower(), policy["default"]))
    guidance = [policy["damages"][kind] for kind in sorted({d["type"] for d in detections})
                if kind in policy["damages"]]
    care["care_advice"] += " " + " ".join(guidance)
    return care


def assessment_today():
    return datetime.now(timezone(timedelta(hours=CONFIG["lifespan"]["timezone_offset_hours"]))).date()


def normalize_user_inputs(value=None, today=None):
    if value is None:
        value = {}
    if not isinstance(value, dict):
        raise ValueError("user_inputs must be a JSON object")
    policy = CONFIG["lifespan"]
    result = {
        "condition": value.get("condition", "unspecified"),
        "use_frequency": value.get("use_frequency", "unspecified"),
        "washing_frequency": value.get("washing_frequency", "unspecified"),
        "purchase_date_known": value.get("purchase_date_known", bool(value.get("purchase_date"))),
        "purchase_date": value.get("purchase_date") or None,
    }
    for key, config_key in [("condition", "condition_multipliers"),
                            ("use_frequency", "use_multipliers"),
                            ("washing_frequency", "wash_multipliers")]:
        if not isinstance(result[key], str) or result[key] not in policy[config_key]:
            raise ValueError(f"Invalid {key}")
    if not isinstance(result["purchase_date_known"], bool):
        raise ValueError("purchase_date_known must be true or false")
    if result["condition"] == "previously_used" and result["purchase_date_known"] and not result["purchase_date"]:
        raise ValueError("Enter the known purchase date or mark it unknown")
    if result["purchase_date"] is not None:
        try:
            purchased = date.fromisoformat(result["purchase_date"])
        except (ValueError, TypeError):
            raise ValueError("purchase_date must be an ISO date (YYYY-MM-DD)")
        if purchased > (today or assessment_today()):
            raise ValueError("Purchase date cannot be in the future")
        result["purchase_date"] = purchased.isoformat()
        result["purchase_date_known"] = True
    return result


def lifespan_for(fabric_type, score, detections, inputs, today=None):
    """Unvalidated heuristic: scale service-life budget by observed health,
    subtract half the calendar age, and divide by use/wash/condition/severity wear.
    Project future score using the same wear factors and base monthly wear rate.
    All calibration values live in CONFIG; none are model-trained.
    """
    policy = CONFIG["lifespan"]
    baseline = policy["fabric_months"].get(fabric_type.lower(), policy["default_months"])
    age = 0
    if inputs["purchase_date"]:
        age = ((today or assessment_today()) - date.fromisoformat(inputs["purchase_date"])).days / policy["days_per_month"]
    severity_factor = max((policy["severity_multipliers"][d["severity"]] for d in detections),
                          default=policy["severity_multipliers"]["none"])
    wear = (policy["use_multipliers"][inputs["use_frequency"]]
            * policy["wash_multipliers"][inputs["washing_frequency"]]
            * policy["condition_multipliers"][inputs["condition"]]
            * severity_factor)
    budget = max(0, baseline * score / policy["score_scale"] - age * policy["age_wear_fraction"])
    remaining = round(min(baseline * policy["maximum_remaining_factor"], budget / wear), 1)
    projected = max(CONFIG["scoring"]["minimum"], round(
        score - policy["score_scale"] / baseline * wear * policy["projection_months"]))
    return {
        "estimated_remaining_months": remaining,
        "estimated_lifespan": f"About {remaining:g} months (rule-based estimate)",
        "projected_condition_after_6_months": {"health_score": projected, "condition_rating": grade_for(projected)},
        "estimate_method": "rule_based_not_validated",
        "estimate_details": {"base_months": baseline, "age_months": round(age, 1), "wear_multiplier": round(wear, 3)},
    }


def assess(fabric_type, detections, user_inputs=None, today=None):
    inputs = normalize_user_inputs(user_inputs, today=today)
    score = score_for(detections)
    if inputs["condition"] == "unspecified":
        usage = "Usage history not supplied; standard wear assumptions used."
    else:
        usage = (f"{inputs['condition'].replace('_', ' ')}; "
                 f"use: {inputs['use_frequency'].replace('_', ' ')}; "
                 f"wash: {inputs['washing_frequency'].replace('_', ' ')}. "
                 + (f"Purchased {inputs['purchase_date']}." if inputs['purchase_date'] else "Purchase date unknown."))
    return {
        "health_score": score,
        "condition_rating": grade_for(score),
        **lifespan_for(fabric_type, score, detections, inputs, today=today),
        "user_inputs": inputs, "usage_status": usage,
        "care_recommendation": care_for(fabric_type, detections),
    }
