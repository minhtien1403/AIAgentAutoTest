# SmartTask — QA guide (reader-friendly)

This document explains how the app behaves in **plain language**, so testers, PMs, and new developers can understand flows without reading code.

For **dense tables**, **exact acceptance criteria**, and a **full automation ID list**, use [`QA_TEST_BASIS.md`](./QA_TEST_BASIS.md) alongside this file.

---

## What you're testing

**SmartTask** is a local task manager on iOS. Tasks are saved on the device (Core Data). There is no sign-in or cloud sync in this scope.

You always start on the **task list**. From there you open tasks, create new ones, organize **categories**, filter and search, and set **due dates** using a **month calendar**. Tasks also have a **workflow status** (like TODO or DONE) that appears on the list and detail screens.

---

## How navigation works (big picture)

Think of the app as a stack of screens:

1. **Bottom of the stack:** Task list (home).
2. **On top of that:** You might open **task detail**, **new task**, **edit task**, **categories**, or **pick a category**—each pushes on top of the list.
3. **Back** (chevron or cancel) pops the top screen and returns you to what was underneath.

**Sheets and alerts** (filters, delete confirm, new category, new subtask) appear on top of the current screen and dismiss when you cancel or confirm—they do not replace the whole stack.

**Simple picture:**

```
                    ┌─────────────────┐
                    │ Category select │  ← opened from New/Edit task
                    └────────┬────────┘
                             │ back
┌──────────────┐    ┌────────▼────────┐
│ Task list    │───►│ New / Edit task │
│  (home)      │    └────────┬────────┘
└──────┬───────┘             │ save or cancel
       │                     │
       ├────────────────────►│ Task detail
       │                     │  (edit, status, subtasks…)
       └────────────────────►│ Categories
```

---

## Task list (home)

**What you see**

- Title **SmartTask** in a custom header (not the system navigation bar).
- A **search** field: "Search tasks."
- A table of tasks with title, priority, a **status badge** (TODO, DOING, DONE, LATE), due date when set, category when set, and a way to mark complete.
- When there are no tasks (or nothing matches filters/search), a friendly **empty state** message.
- Header actions: **folder** (categories), **tag** (filter by category), **lines** (filter by active/completed), **plus** (add task).
- A **floating +** button that does the same as the header plus.

**What to try**

- Tap a task → opens **detail**.
- Use search → list narrows by words in the **title or description** (not case sensitive).
- Open **Filter** → pick All, Active, or Completed.
- Open **filter by category** → pick a category or "all categories."
- Mark a task complete from the row → it should update; under **Active** filter it may disappear.
- Swipe a row: one side **delete**, other side **complete / mark active**.

**Heads-up**

- If a task has **subtasks**, marking the parent complete/undo behaves differently than a task with no subtasks (the app may sync all subtasks and map status to DONE/TODO in specific cases). Worth regression-testing both kinds of tasks.

---

## New task and Edit task (same form, two modes)

**What you see**

- **New Task** or **Edit Task** in the header.
- **Cancel** (X) on the left, **Save** (checkmark) on the right.
- **Title** (required), **Description** (optional), **Priority** (Low / Medium / High).
- **Category** section: tap the row to choose a category (or none).
- **Due date** switch: when on, you see a **calendar card** and **Clear due date**.

**Due date calendar — how it should feel**

- Arrows move **month** or **year**; the grid shows about six weeks of day cells.
- Tap a day to select it immediately (only valid dates in the allowed range). The selected date is used when you save the task.
- Turning the **Due date** switch **off** means the task has **no** due date when you save.
- **Clear due date** turns the switch off and hides the calendar.

**What you cannot do on this screen (important)**

- There is **no control here** to pick workflow status (TODO / DOING / etc.).  
  **New tasks** start as **TODO**.  
  **Edited tasks** keep whatever status they already had unless you changed it on **task detail** earlier.

**Validation**

- Saving with an empty title (or only spaces) shows **Cannot save** and **Title cannot be empty.**

---

## Picking a category (from the form)

**What you see**

- First row: **None** (no category).
- Then one row per category you created.
- A checkmark on the current choice.

**What to try**

- Pick a row → screen closes and the form shows the new choice.
- Back without picking a row → you leave without changing the selection.

---

## Categories (management)

Open from the task list header (**folder** icon).

**What you see**

- A list of categories.
- **+** to add; **back** returns to the task list (list refreshes).

**What to try**

- Add a category: empty name → **Cannot create** / **Name cannot be empty.**
- Swipe to **delete** a category.

---

## Task detail

**What you see**

- Task title, **priority** badge, optional **Category:** line, description (or **No description**), due line (or **No due date**).
- **Workflow status** as a badge: TODO, DOING, DONE, or LATE.
- **Change status** → opens a sheet to pick one of those four.
- **Subtasks** section, **Add subtask**, then **Edit**, **Delete**, and **Mark complete** / **Mark as active**.

**Status vs "complete"**

- Picking **DONE** in the status sheet should treat the task as **completed**.
- **Mark complete** / **Mark as active** toggles completion and keeps status aligned (for example complete → DONE, undo from done → TODO).
- Other statuses (TODO, DOING, LATE) are **not** the same as "completed" unless the task was already completed from elsewhere—use the detail screen to confirm what the app shows after each action.

**Delete**

- **Delete** asks for confirmation; confirming removes the task and returns you to the list.

**Subtasks**

- **Add subtask** with an empty title → error **Subtask title cannot be empty.**
- You can toggle completion and swipe to delete subtasks. When subtasks exist, parent completion can follow "all subtasks done" rules—good area for edge-case tests.

---

## Quick reference: what must not be empty

| Action | If the user leaves it blank |
|--------|-----------------------------|
| Save task | Title → error alert (cannot save). |
| Create category | Name → error alert (cannot create). |
| Add subtask | Title → error alert (cannot add). |

Everything else on the task form is optional (description, category, due date).

---

## Workflow statuses (words users see)

These are the labels on badges and in the **Change status** sheet:

| Meaning in the app | Label on screen |
|--------------------|-----------------|
| To do | **TODO** |
| In progress | **DOING** |
| Finished | **DONE** |
| Late | **LATE** |

---

## If you write automated UI tests

The app uses fixed **accessibility identifiers** starting with `smartTask_`. You do not need to memorize them for manual testing.

**Practical tips**

- The **task list** screen id is `smartTask_taskList_screen`.
- Each **task row** includes a unique id with the task's UUID—automation usually finds rows by title or by prefix `smartTask_taskCell_`.
- The **calendar** exposes a container `smartTask_taskForm_dueDatePicker` and **42 day slots** named `smartTask_taskForm_calendarDay_0` through `smartTask_taskForm_calendarDay_41` (reading order left-to-right, top-to-bottom).
- **Task detail** exposes `smartTask_taskDetail_taskStatusChangeButton` and the status sheet `smartTask_taskDetail_statusPickerAlert`.

The complete list lives in **`AccessibilityIDs.swift`** and in **`QA_TEST_BASIS.md`**.

**Known gap:** the **New subtask** alert does not set a custom accessibility id on the alert itself—tests may rely on button titles like **Add** and **Cancel**.

---

## Document pair

| File | Best for |
|------|----------|
| **This file** (`QA_GUIDE_READABLE.md`) | Reading, onboarding, explaining the app to humans |
| **`QA_TEST_BASIS.md`** | Writing test cases, checklists, and automation scripts line-by-line |

Both describe the same product behavior; keep them in sync when features change.
