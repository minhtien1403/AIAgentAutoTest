#!/usr/bin/env python3
"""
iOS Simulator Navigator - find elements by text, type, or accessibility id; tap; enter text.
Uses IDB `describe-all` and `idb ui tap` / `idb ui text`.
"""

import argparse
import subprocess
import sys
import time
from dataclasses import dataclass

from common import (
    get_accessibility_tree,
    get_device_screen_size,
    resolve_udid,
    transform_screenshot_coords,
)

# TaskManager month calendar day cells (see AccessibilityIDs.CreateTask.calendarDayCell).
CALENDAR_DAY_ID_PREFIX = "smartTask_taskForm_calendarDay_"


@dataclass
class Element:
    type: str
    label: str | None
    value: str | None
    identifier: str | None
    frame: dict[str, float]
    traits: list[str]
    enabled: bool = True

    @property
    def center(self) -> tuple[int, int]:
        fx = float(self.frame.get("x") or 0)
        fy = float(self.frame.get("y") or 0)
        fw = float(self.frame.get("width") or 0)
        fh = float(self.frame.get("height") or 0)
        if fw <= 0 or fh <= 0:
            return (int(fx), int(fy))
        return (int(fx + fw / 2), int(fy + fh / 2))

    @property
    def switch_like_tap_point(self) -> tuple[int, int]:
        fx = float(self.frame.get("x") or 0)
        fy = float(self.frame.get("y") or 0)
        fw = float(self.frame.get("width") or 0)
        fh = float(self.frame.get("height") or 0)
        if fw <= 0 or fh <= 0:
            return (int(fx), int(fy))
        tx = int(fx + fw * 0.78)
        ty = int(fy + fh * 0.5)
        return (tx, ty)

    @property
    def description(self) -> str:
        label = self.label or self.value or self.identifier or "Unnamed"
        return f'{self.type} "{label}"'


class Navigator:
    def __init__(self, udid: str | None = None):
        self.udid = udid
        self._tree_cache = None

    def get_accessibility_tree(self, force_refresh: bool = False) -> dict:
        if self._tree_cache and not force_refresh:
            return self._tree_cache
        self._tree_cache = get_accessibility_tree(self.udid, nested=True)
        return self._tree_cache

    @staticmethod
    def _element_type_matches(requested: str, actual: str | None) -> bool:
        if not actual:
            return False
        if requested == actual:
            return True
        if requested == "TextField" and actual == "TextView":
            return True
        if requested == "TextView" and actual == "TextField":
            return True
        if requested == "SegmentedControl" and actual in ("Tab", "Adjustable"):
            return True
        if requested == "Switch" and actual == "CheckBox":
            return True
        if requested == "CheckBox" and actual == "Switch":
            return True
        if requested == "Picker" and actual in ("Picker", "Wheel"):
            return True
        if requested == "Wheel" and actual in ("Picker", "Wheel"):
            return True
        return False

    def _flatten_tree(self, node: dict, elements: list[Element] | None = None) -> list[Element]:
        if elements is None:
            elements = []

        if node.get("type"):
            element = Element(
                type=node.get("type", "Unknown"),
                label=node.get("AXLabel"),
                value=node.get("AXValue"),
                identifier=node.get("AXUniqueId") or node.get("identifier"),
                frame=node.get("frame", {}),
                traits=node.get("traits", []),
                enabled=node.get("enabled", True),
            )
            elements.append(element)

        for child in node.get("children", []):
            self._flatten_tree(child, elements)

        return elements

    def list_elements(self, force_refresh: bool = False) -> list[Element]:
        tree = self.get_accessibility_tree(force_refresh)
        return self._flatten_tree(tree)

    def find_element(
        self,
        text: str | None = None,
        element_type: str | None = None,
        identifier: str | None = None,
        index: int = 0,
        fuzzy: bool = True,
    ) -> Element | None:
        tree = self.get_accessibility_tree()
        elements = self._flatten_tree(tree)

        matches = []

        for elem in elements:
            if not elem.enabled:
                id_match = bool(identifier and elem.identifier == identifier)
                is_switch_like = elem.type in ("Switch", "CheckBox")
                is_calendar_day = bool(
                    elem.identifier and str(elem.identifier).startswith(CALENDAR_DAY_ID_PREFIX)
                )
                if not id_match and not is_switch_like and not is_calendar_day:
                    continue

            if element_type and not self._element_type_matches(element_type, elem.type):
                continue

            if identifier and elem.identifier != identifier:
                continue

            if text:
                elem_text = (elem.label or "") + " " + (elem.value or "")
                if fuzzy:
                    if text.lower() not in elem_text.lower():
                        continue
                elif text not in (elem.label, elem.value):
                    continue

            matches.append(elem)

        if matches and index < len(matches):
            return matches[index]

        return None

    def tap(self, element: Element) -> bool:
        is_switch_like = element.type in ("Switch", "CheckBox")
        if is_switch_like:
            time.sleep(0.1)
        x, y = element.switch_like_tap_point if is_switch_like else element.center
        duration = 0.06 if is_switch_like else None
        ok = self.tap_at(x, y, duration=duration)
        if is_switch_like and not ok:
            time.sleep(0.08)
            x2, y2 = element.center
            ok = self.tap_at(x2, y2, duration=duration)
        return ok

    def tap_at(self, x: int, y: int, duration: float | None = None) -> bool:
        cmd = ["idb", "ui", "tap", str(x), str(y)]
        if duration is not None and duration > 0:
            cmd.extend(["--duration", str(duration)])
        if self.udid:
            cmd.extend(["--udid", self.udid])

        try:
            subprocess.run(cmd, capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError as e:
            err = (e.stderr or b"").decode("utf-8", errors="replace").strip()
            if err:
                print(f"idb ui tap failed: {err}", file=sys.stderr)
            return False

    def enter_text(self, text: str, element: Element | None = None) -> bool:
        if element:
            if not self.tap(element):
                return False
            time.sleep(0.5)

        cmd = ["idb", "ui", "text", text]
        if self.udid:
            cmd.extend(["--udid", self.udid])

        try:
            subprocess.run(cmd, capture_output=True, check=True)
            return True
        except subprocess.CalledProcessError:
            return False

    def find_and_tap(
        self,
        text: str | None = None,
        element_type: str | None = None,
        identifier: str | None = None,
        index: int = 0,
    ) -> tuple[bool, str]:
        element = self.find_element(text, element_type, identifier, index)

        if not element:
            criteria = []
            if text:
                criteria.append(f"text='{text}'")
            if element_type:
                criteria.append(f"type={element_type}")
            if identifier:
                criteria.append(f"id={identifier}")
            return (False, f"Not found: {', '.join(criteria)}")

        if element.type in ("Switch", "CheckBox"):
            self.get_accessibility_tree(force_refresh=True)
            time.sleep(0.08)
            refreshed = self.find_element(text, element_type, identifier, index)
            if refreshed:
                element = refreshed

        if self.tap(element):
            return (True, f"Tapped: {element.description} at {element.center}")
        return (False, f"Failed to tap: {element.description}")

    def find_and_enter_text(
        self,
        text_to_enter: str,
        find_text: str | None = None,
        element_type: str | None = "TextField",
        identifier: str | None = None,
        index: int = 0,
    ) -> tuple[bool, str]:
        element = self.find_element(find_text, element_type, identifier, index)

        if not element:
            return (False, "Text field not found")

        if self.enter_text(text_to_enter, element):
            return (True, f"Entered text in: {element.description}")
        return (False, "Failed to enter text")


def main():
    parser = argparse.ArgumentParser(description="Navigate iOS apps using accessibility data")

    parser.add_argument("--find-text", help="Find element by text (fuzzy match)")
    parser.add_argument("--find-exact", help="Find element by exact text")
    parser.add_argument("--find-type", help="Element type (Button, TextField, Picker, Switch, …)")
    parser.add_argument("--find-id", help="Accessibility identifier")
    parser.add_argument("--index", type=int, default=0, help="Which match to use (0-based)")

    parser.add_argument("--tap", action="store_true", help="Tap the found element")
    parser.add_argument("--tap-at", help="Tap at coordinates (x,y)")
    parser.add_argument("--enter-text", help="Enter text into element")

    parser.add_argument(
        "--screenshot-coords",
        action="store_true",
        help="Interpret tap coordinates as from a screenshot (requires --screenshot-width/height)",
    )
    parser.add_argument("--screenshot-width", type=int, help="Screenshot width")
    parser.add_argument("--screenshot-height", type=int, help="Screenshot height")

    parser.add_argument(
        "--udid",
        help="Device UDID (auto-detects booted simulator if not provided)",
    )
    parser.add_argument("--list", action="store_true", help="List tappable elements")

    args = parser.parse_args()

    try:
        udid = resolve_udid(args.udid)
    except RuntimeError as e:
        print(f"Error: {e}")
        sys.exit(1)

    navigator = Navigator(udid=udid)

    if args.list:
        elements = navigator.list_elements()

        tappable_types = (
            "Button",
            "Link",
            "Cell",
            "TextField",
            "SecureTextField",
            "TextView",
            "Switch",
            "CheckBox",
            "SegmentedControl",
            "Slider",
            "Stepper",
            "Tab",
            "Adjustable",
            "Picker",
            "Wheel",
        )

        tappable = [e for e in elements if e.enabled and e.type in tappable_types]

        print(f"Tappable elements ({len(tappable)}):")
        for elem in tappable[:25]:
            print(f"  {elem.type}: \"{elem.label or elem.value or 'Unnamed'}\" {elem.center}")

        if len(tappable) > 25:
            print(f"  ... and {len(tappable) - 25} more")
        sys.exit(0)

    if args.tap_at:
        coords = args.tap_at.split(",")
        if len(coords) != 2:
            print("Error: --tap-at requires x,y format")
            sys.exit(1)

        x, y = int(coords[0]), int(coords[1])

        if args.screenshot_coords:
            if not args.screenshot_width or not args.screenshot_height:
                print(
                    "Error: --screenshot-coords requires --screenshot-width and --screenshot-height"
                )
                sys.exit(1)

            device_w, device_h = get_device_screen_size(udid)
            x, y = transform_screenshot_coords(
                x,
                y,
                args.screenshot_width,
                args.screenshot_height,
                device_w,
                device_h,
            )
            print(
                f"Transformed screenshot coords ({coords[0]}, {coords[1]}) "
                f"to device coords ({x}, {y})"
            )

        if navigator.tap_at(x, y):
            print(f"Tapped at ({x}, {y})")
        else:
            print(f"Failed to tap at ({x}, {y})")
            sys.exit(1)

    elif args.tap:
        text = args.find_text or args.find_exact

        success, message = navigator.find_and_tap(
            text=text, element_type=args.find_type, identifier=args.find_id, index=args.index
        )

        print(message)
        if not success:
            sys.exit(1)

    elif args.enter_text:
        text = args.find_text or args.find_exact

        success, message = navigator.find_and_enter_text(
            text_to_enter=args.enter_text,
            find_text=text,
            element_type=args.find_type or "TextField",
            identifier=args.find_id,
            index=args.index,
        )

        print(message)
        if not success:
            sys.exit(1)

    else:
        text = args.find_text or args.find_exact
        fuzzy = args.find_text is not None

        element = navigator.find_element(
            text=text,
            element_type=args.find_type,
            identifier=args.find_id,
            index=args.index,
            fuzzy=fuzzy,
        )

        if element:
            print(f"Found: {element.description} at {element.center}")
        else:
            print("Element not found")
            sys.exit(1)


if __name__ == "__main__":
    main()
