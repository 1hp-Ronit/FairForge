```markdown
# Design System Documentation

## 1. Overview & Creative North Star

### The Monolithic Precision
This design system is built for the high-stakes environment of AI auditing. It rejects the playful, rounded "SaaS-standard" aesthetic in favor of **Monolithic Precision**. The Creative North Star is the "Digital Laboratory"—a space that feels heavy, authoritative, and surgically clean. 

We break the "template" look by utilizing intentional asymmetry in layout and a high-contrast typographic scale. By stripping away decorative shadows and glows, we force the user to focus on the data. Depth is not simulated; it is engineered through tonal hierarchy and rigid, linear structures. This is a tool for experts who value clarity over decoration.

---

### 2. Colors & Surface Logic

The palette is rooted in a "matte-black" philosophy, utilizing a tight range of grays to define function and hierarchy.

*   **Primary (Audit Pass):** `#4be277` (Token: `primary`) — Used for success states and primary actions.
*   **Secondary (Information):** `#c0c1ff` (Token: `secondary`) — Used for neutral data points and auxiliary accents.
*   **Surface Foundation:** The base layer starts at `#0F0F0F` (Token: `background`).

#### The "No-Line" Rule
To achieve a high-end editorial feel, **do not use 1px solid borders for sectioning large layout areas.** Boundaries must be defined solely through background shifts. For example, a sidebar should use `surface-container-low` against a `background` main stage. Lines are reserved exclusively for interactive components (inputs/cards) to maintain a "blueprint" aesthetic.

#### Surface Hierarchy & Nesting
Treat the UI as a series of nested physical layers. 
1.  **Level 0 (Base):** `surface` (#121414) – The infinite canvas.
2.  **Level 1 (Section):** `surface-container-low` (#1b1c1c) – For grouping large content blocks.
3.  **Level 2 (Object):** `surface-container` (#1f2020) – For cards and interactive modules.
4.  **Level 3 (Focus):** `surface-container-high` (#292a2a) – For active states or "pop-over" logic.

#### Micro-Texture & Tonal Depth
While the user requested "no gradients," we implement **Tonal Transitions**. Main CTAs may use a subtle shift from `primary` to `primary-container` (a difference of less than 3% luminance) to prevent the UI from looking "dead" on high-end OLED displays.

---

### 3. Typography

The typography strategy employs a "Dual-Engine" approach: **Space Grotesk** for editorial impact and **DM Sans/Inter** for functional UI.

*   **Display & Headlines:** Use `display-lg` through `headline-sm` in **Space Grotesk**. This typeface’s idiosyncratic terminals provide the "signature" look that separates this system from generic "Inter-only" dashboards.
*   **The Metric Engine:** All numerical data, ML bias scores, and audit percentages MUST use **DM Mono** or **Berkeley Mono**. This communicates mathematical precision and provides a visual "texture" change when the user moves from reading prose to auditing data.
*   **Hierarchy via Scale:** Use extreme contrast. A `display-lg` title (3.5rem) should often sit near a `label-sm` (0.6875rem) descriptor to create an editorial, high-fashion layout feel.

---

### 4. Elevation & Depth

In this design system, shadows are forbidden. We replace them with **Tonal Layering** and **The Ghost Border.**

*   **The Layering Principle:** Softness is achieved by stacking. Place a `surface-container-lowest` card on a `surface-container-low` section. The delta in hex value provides a natural, "matte" lift that is easier on the eyes than a drop shadow.
*   **The Ghost Border:** For accessibility in high-density data views, use the `outline-variant` token at **15% opacity**. This creates a "suggestion" of a border that guides the eye without cluttering the visual field.
*   **Glassmorphism (The Auditor's Lens):** For floating menus or tooltips, use `surface-container-highest` with a `backdrop-blur` of 12px and 80% opacity. This "frosted" effect allows the underlying bias charts to bleed through, maintaining context.

---

### 5. Components

#### Buttons
*   **Primary:** Height: 40px | Radius: 8px | Background: `primary` | Text: `on-primary`. 
*   **Secondary:** Height: 40px | Radius: 8px | Border: 1px solid `outline` | Background: Transparent.
*   **State:** On hover, the background shifts to `primary-container`. No glows.

#### Audit Cards
*   **Background:** `#161616` (Token: `surface-container`).
*   **Border:** 1px solid `#262626` (Token: `outline-variant`).
*   **Radius:** 10px.
*   **Layout:** Forbid divider lines. Use **Spacing Scale 8** (1.75rem) to create clear vertical separation between card headers and content.

#### Inputs & Selects
*   **Height:** 40px | Radius: 8px | Background: `#1C1C1C` | Border: 1px solid `#262626`.
*   **Focus State:** The border color must transition to `primary` (#22C55E). The cursor should be the only "active" element.

#### Bias Distribution Charts (Custom Component)
Audit data should be visualized using "Micro-Brutalism." Use sharp edges for bar graphs and thick, 2px strokes for line charts using the `primary`, `error`, and `warning` tokens.

---

### 6. Do's and Don'ts

#### Do
*   **Do** use `0.5 (0.1rem)` spacing for tight technical metadata.
*   **Do** use asymmetrical margins (e.g., a wide left margin for titles and a tight right margin for actions) to create an editorial look.
*   **Do** use `DM Mono` for any value that can be measured or counted.
*   **Do** lean on `surface-container-lowest` for the "sunken" feel of code editors or data input areas.

#### Don't
*   **Don't** use standard 45-degree drop shadows. If depth is needed, use a `surface` shift.
*   **Don't** use "Rounded-Full" pills for anything other than status chips. Buttons and inputs must remain strictly at 8px.
*   **Don't** use dividers or hair-lines to separate list items. Use the `surface-container` tiers or whitespace from the **Spacing Scale (10-16)**.
*   **Don't** use icons as purely decorative elements. Every icon must have a functional purpose or accompany a label.

---
**Director's Final Note:** 
Precision is the ultimate luxury. Every pixel in this system should feel like it was placed with a caliper. If a layout feels "crowded," do not add a line; remove a container. Use the matte black space as a functional element, not just a background.```