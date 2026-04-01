#!/usr/bin/env python3
"""
iOS Screen Mapper - Current Screen Analyzer

Maps the current screen's UI elements for navigation decisions.
Uses IDB `describe-all` and summarizes buttons, fields, switches, pickers, segments, and AX IDs.
"""

import argparse
import json
import re
import sys
from collections import defaultdict

from common import get_accessibility_tree, resolve_udid

# Must match `AccessibilityIDs.CreateTask.calendarDayCell` in TaskManager (SmartTask).
CALENDAR_DAY_ID_PREFIX = "smartTask_taskForm_calendarDay_"
# Localized AXLabel from CalendarDayCell, e.g. "Day 15" (en) or equivalent.
_DAY_LABEL_RE = re.compile(r"^Day\s+(\d+)\s*$", re.IGNORECASE)


def _calendar_day_number_preview(ax_label: str) -> str | None:
    """Return the numeric day for summaries; supports '15' or 'Day 15'."""
    s = (ax_label or "").strip()
    if s.isdigit():
        return s
    m = _DAY_LABEL_RE.match(s)
    return m.group(1) if m else None


class ScreenMapper:
    INTERACTIVE_TYPES = {
        "Button",
        "Link",
        "TextField",
        "SecureTextField",
        "TextView",
        "Cell",
        "Switch",
        "CheckBox",
        "Slider",
        "Stepper",
        "SegmentedControl",
        "TabBar",
        "NavigationBar",
        "Toolbar",
        "Control",
        "Tab",
        "Adjustable",
        "Picker",
        "Wheel",
    }

    def __init__(self, udid: str | None = None):
        self.udid = udid

    def get_accessibility_tree(self) -> dict:
        return get_accessibility_tree(self.udid, nested=True)

    def analyze_tree(self, node: dict, depth: int = 0) -> dict:
        analysis = {
            "elements_by_type": defaultdict(list),
            "total_elements": 0,
            "interactive_elements": 0,
            "text_fields": [],
            "buttons": [],
            "switches": [],
            "segmented_controls": [],
            "pickers": [],
            "navigation": {},
            "screen_name": None,
            "focusable": 0,
        }

        self._analyze_recursive(node, analysis, depth)

        analysis["elements_by_type"] = dict(analysis["elements_by_type"])
        analysis["elements_with_identifier"] = self._collect_identifier_elements(node)
        analysis["segmented_controls_detail"] = self._collect_segmented_controls_detail(node)
        analysis["calendar_day_cells"] = self._collect_calendar_day_cells(node)

        return analysis

    def _collect_identifier_elements(self, node: dict) -> list[dict]:
        """All elements with AXUniqueId or `identifier` (IDB may use either)."""

        def walk(n: dict, out: list) -> None:
            uid = n.get("AXUniqueId") or n.get("identifier")
            if uid:
                fr = n.get("frame") or {}
                w = fr.get("width", 0) or 0
                h = fr.get("height", 0) or 0
                out.append(
                    {
                        "type": n.get("type"),
                        "AXUniqueId": uid,
                        "AXLabel": n.get("AXLabel", ""),
                        "AXValue": (n.get("AXValue", "") or "")[:200],
                        "enabled": n.get("enabled", True),
                        "frame_wh": f"{int(w)}x{int(h)}",
                    }
                )
            for c in n.get("children", []):
                walk(c, out)

        acc: list[dict] = []
        walk(node, acc)
        return acc

    def _collect_calendar_day_cells(self, node: dict) -> list[dict]:
        """Day controls in the month grid: `UIButton` leaves with smartTask_taskForm_calendarDay_<index>."""

        seen: set[str] = set()

        def walk(n: dict, out: list) -> None:
            uid = n.get("AXUniqueId") or n.get("identifier") or ""
            uid_s = str(uid) if uid else ""
            if uid_s.startswith(CALENDAR_DAY_ID_PREFIX) and uid_s not in seen:
                seen.add(uid_s)
                fr = n.get("frame") or {}
                out.append(
                    {
                        "type": n.get("type"),
                        "AXUniqueId": uid_s,
                        "AXLabel": (n.get("AXLabel") or "").strip(),
                        "enabled": n.get("enabled", True),
                        "frame_x": float(fr.get("x", 0) or 0),
                        "frame_y": float(fr.get("y", 0) or 0),
                    }
                )
            for c in n.get("children", []) or []:
                walk(c, out)

        acc: list[dict] = []
        # Root may be a wrapper; some IDB builds use a list as root
        if isinstance(node, list):
            for item in node:
                if isinstance(item, dict):
                    walk(item, acc)
        elif isinstance(node, dict):
            walk(node, acc)
        acc.sort(key=lambda e: (e["frame_y"], e["frame_x"]))
        return acc

    def _collect_segmented_controls_detail(self, node: dict) -> list[dict]:
        def walk(n: dict, out: list) -> None:
            if n.get("type") == "SegmentedControl":
                segments: list[dict] = []
                for ch in n.get("children", []):
                    segments.append(
                        {
                            "type": ch.get("type"),
                            "AXLabel": ch.get("AXLabel", ""),
                            "AXUniqueId": ch.get("AXUniqueId", "") or ch.get("identifier", ""),
                        }
                    )
                out.append(
                    {
                        "AXUniqueId": n.get("AXUniqueId", "") or n.get("identifier", ""),
                        "AXLabel": n.get("AXLabel", ""),
                        "AXValue": n.get("AXValue", ""),
                        "segments": segments,
                    }
                )
            for ch in n.get("children", []):
                walk(ch, out)

        acc: list[dict] = []
        walk(node, acc)
        return acc

    def _analyze_recursive(self, node: dict, analysis: dict, depth: int):
        elem_type = node.get("type")
        label = node.get("AXLabel", "")
        value = node.get("AXValue", "")
        identifier = node.get("AXUniqueId") or node.get("identifier") or ""

        if elem_type:
            analysis["total_elements"] += 1

            elem_info = label or value or identifier or "Unnamed"

            # SF Symbol bar items often report as Image with an accessibility id
            if elem_type == "Image" and (identifier or label):
                analysis["interactive_elements"] += 1
                analysis["elements_by_type"]["Image"].append(elem_info)
                analysis["buttons"].append(elem_info)
                if node.get("enabled", False):
                    analysis["focusable"] += 1

            elif elem_type in self.INTERACTIVE_TYPES:
                analysis["interactive_elements"] += 1
                analysis["elements_by_type"][elem_type].append(elem_info)

                if elem_type == "Button":
                    analysis["buttons"].append(elem_info)
                elif elem_type in ("TextField", "SecureTextField", "TextView"):
                    analysis["text_fields"].append(
                        {"type": elem_type, "label": elem_info, "has_value": bool(value)}
                    )
                elif elem_type == "NavigationBar":
                    analysis["navigation"]["nav_title"] = label or "Navigation"
                elif elem_type in ("Switch", "CheckBox"):
                    analysis.setdefault("switches", []).append(
                        identifier or label or value or "Unnamed"
                    )
                elif elem_type == "SegmentedControl":
                    analysis.setdefault("segmented_controls", []).append(
                        label or value or identifier or "Unnamed"
                    )
                elif elem_type in ("Picker", "Wheel"):
                    analysis.setdefault("pickers", []).append(
                        identifier or label or value or "Unnamed"
                    )
                elif elem_type == "TabBar":
                    analysis["navigation"]["tab_count"] = len(node.get("children", []))

            if node.get("enabled", False) and elem_type in self.INTERACTIVE_TYPES:
                analysis["focusable"] += 1

        if not analysis["screen_name"] and identifier:
            if "ViewController" in identifier or "Screen" in identifier:
                analysis["screen_name"] = identifier

        for child in node.get("children", []):
            self._analyze_recursive(child, analysis, depth + 1)

    def format_summary(self, analysis: dict, verbose: bool = False) -> str:
        lines = []

        screen = analysis["screen_name"] or "Unknown Screen"
        total = analysis["total_elements"]
        interactive = analysis["interactive_elements"]
        lines.append(f"Screen: {screen} ({total} elements, {interactive} interactive)")

        if analysis["buttons"]:
            button_list = ", ".join(f'"{b}"' for b in analysis["buttons"][:5])
            if len(analysis["buttons"]) > 5:
                button_list += f" +{len(analysis['buttons']) - 5} more"
            lines.append(f"Buttons: {button_list}")

        if analysis["text_fields"]:
            field_count = len(analysis["text_fields"])
            filled = sum(1 for f in analysis["text_fields"] if f["has_value"])
            lines.append(
                f"Text inputs (TextField/TextView): {field_count} ({filled} filled)"
            )

        switches = analysis.get("switches") or []
        if switches:
            sw_list = ", ".join(f'"{s}"' for s in switches[:6])
            if len(switches) > 6:
                sw_list += f" +{len(switches) - 6} more"
            lines.append(f"Switches: {sw_list}")

        segs = analysis.get("segmented_controls") or []
        if segs:
            sg = ", ".join(f'"{s}"' for s in segs[:4])
            if len(segs) > 4:
                sg += f" +{len(segs) - 4} more"
            lines.append(f"Segmented controls: {sg}")

        pks = analysis.get("pickers") or []
        if pks:
            pk_line = ", ".join(f'"{p}"' for p in pks[:4])
            if len(pks) > 4:
                pk_line += f" +{len(pks) - 4} more"
            lines.append(f"Pickers / wheels: {pk_line}")

        nav_parts = []
        if "nav_title" in analysis["navigation"]:
            nav_parts.append(f'NavBar: "{analysis["navigation"]["nav_title"]}"')
        if "tab_count" in analysis["navigation"]:
            nav_parts.append(f"TabBar: {analysis['navigation']['tab_count']} tabs")
        if nav_parts:
            lines.append(f"Navigation: {', '.join(nav_parts)}")

        lines.append(f"Focusable: {analysis['focusable']} elements")

        ewi = analysis.get("elements_with_identifier") or []
        if ewi:
            ids = [e["AXUniqueId"] for e in ewi if e.get("AXUniqueId")]
            if ids:
                cap = 12
                shown = ", ".join(ids[:cap])
                if len(ids) > cap:
                    shown += f" +{len(ids) - cap} more"
                lines.append(f"Accessibility IDs: {shown}")

            # UICollectionView / composite custom controls often surface as Group in IDB, not Picker.
            named_groups = [
                e
                for e in ewi
                if e.get("type") == "Group"
                and (e.get("AXLabel") or "").strip()
                and e.get("AXUniqueId")
            ]
            if named_groups:
                cap_g = 4
                parts = [
                    f'"{g["AXLabel"]}" [{g["AXUniqueId"]}]'
                    for g in named_groups[:cap_g]
                ]
                if len(named_groups) > cap_g:
                    parts.append(f"+{len(named_groups) - cap_g} more")
                lines.append(f"Group regions (custom UI): {', '.join(parts)}")

        cdc = analysis.get("calendar_day_cells") or []
        if cdc:
            labels = []
            for c in cdc:
                prev = _calendar_day_number_preview(c.get("AXLabel") or "")
                if prev is not None:
                    labels.append(prev)
                elif (c.get("AXLabel") or "").strip():
                    labels.append((c.get("AXLabel") or "").strip())
            cap = 28
            lbl_preview = ", ".join(labels[:cap])
            if len(labels) > cap:
                lbl_preview += f", +{len(labels) - cap} more"
            lines.append(
                f"Calendar grid days: {len(cdc)} cells — day numbers (reading order): {lbl_preview}"
            )
            lines.append(
                f"  Tap by ID: {CALENDAR_DAY_ID_PREFIX}<0-{max(0, len(cdc) - 1)}> (navigator --find-id)"
            )

        if verbose:
            lines.append("\nElements by type:")
            for elem_type, items in analysis["elements_by_type"].items():
                if items:
                    lines.append(f"  {elem_type}: {len(items)}")
                    for item in items[:3]:
                        lines.append(f"    - {item}")
                    if len(items) > 3:
                        lines.append(f"    ... +{len(items) - 3} more")

        return "\n".join(lines)

    def get_navigation_hints(self, analysis: dict) -> list[str]:
        hints = []
        if "Login" in str(analysis.get("buttons", [])):
            hints.append("Login screen detected - find TextFields for credentials")

        if analysis["text_fields"]:
            unfilled = [f for f in analysis["text_fields"] if not f["has_value"]]
            if unfilled:
                hints.append(f"{len(unfilled)} empty text field(s) - may need input")

        if not analysis["buttons"] and not analysis["text_fields"]:
            hints.append("No interactive elements - try swiping or going back")

        if "tab_count" in analysis.get("navigation", {}):
            hints.append(f"Tab bar available with {analysis['navigation']['tab_count']} tabs")

        if analysis.get("pickers"):
            hints.append("Date/time wheels: use navigator --find-id or --find-text on AX value")

        if analysis.get("calendar_day_cells"):
            hints.append(
                f"Month calendar: tap a day with navigator --find-id {CALENDAR_DAY_ID_PREFIX}<slot> "
                f"(slot 0–{len(analysis['calendar_day_cells']) - 1}, row-major)"
            )

        return hints


def main():
    parser = argparse.ArgumentParser(description="Map current screen UI elements")
    parser.add_argument("--verbose", action="store_true", help="Show detailed element breakdown")
    parser.add_argument("--json", action="store_true", help="Output raw JSON analysis")
    parser.add_argument("--hints", action="store_true", help="Include navigation hints")
    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )

    args = parser.parse_args()

    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}")
        sys.exit(1)

    mapper = ScreenMapper(udid=udid)
    tree = mapper.get_accessibility_tree()
    analysis = mapper.analyze_tree(tree)

    if args.json:
        print(json.dumps(analysis, indent=2, default=str))
    else:
        summary = mapper.format_summary(analysis, verbose=args.verbose)
        print(summary)

        if args.hints:
            hints = mapper.get_navigation_hints(analysis)
            if hints:
                print("\nHints:")
                for hint in hints:
                    print(f"  - {hint}")


if __name__ == "__main__":
    main()
