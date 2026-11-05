# Design Brief: Project B

## Look and feel
**Personality:** calm, private, trustworthy. The app holds sensitive data, so the UI should feel quiet and in control, never flashy or "tracking-y".

**Principles**
1. Content first: the day's story (places, times) is the hero, chrome stays minimal.
2. Honest about data: gaps and unknowns are shown, not hidden.
3. Privacy is visible: tracking state is always one glance away.
4. One accent colour, lots of whitespace, soft neutral surfaces.

**References to look at (for mood only):** Google Timeline's day list, Apple Calendar's month/day views, Arc Timeline's trip rows. Take structure, not styling.

## Visual system

### Colour palette
Light and dark are first-class; "System" is the default. Values are starting points, check contrast in Phase 1.

| Role | Light | Dark |
|---|---|---|
| Primary (accent) | `#0F766E` | `#2DD4BF` |
| On primary | `#FFFFFF` | `#042F2E` |
| Background | `#FAFAF9` | `#0C0F10` |
| Surface (cards) | `#FFFFFF` | `#151A1C` |
| Surface variant (chips, inputs) | `#F0F2F1` | `#1E2528` |
| Outline / dividers (decorative only) | `#E2E6E4` | `#2A3236` |
| Outline strong (control borders, 3:1+) | `#7C8885` | `#6E7B80` |
| Text primary | `#12171A` | `#ECF0EF` |
| Text secondary | `#5B6663` | `#9AA5A2` |
| Visit marker | `#0F766E` | `#2DD4BF` |
| Trip line | `#3B82F6` | `#60A5FA` |
| Gap / no data | `#C9CFCD` | `#3A4347` |
| Success | `#15803D` | `#4ADE80` |
| Warning | `#B45309` | `#FBBF24` |
| Error | `#B91C1C` | `#F87171` |

Rules: never use colour alone to convey state (pair with icon or text); map tiles should have a dark variant in dark mode.

### Typography
- Font: system default (Roboto on Android, SF Pro on iOS) for v1. Optional later: Inter for consistency.
- Scale (sp): Display 28 / Title 22 / Heading 18 / Body 16 / Label 14 / Caption 12.
- Weights: Regular 400 for body, Medium 500 for labels, Semibold 600 for titles.
- Times use tabular figures so columns align.
- Respect the OS text-size setting up to 200%.

### Spacing, shape, depth, icons
- 4 dp base grid; common steps 4, 8, 12, 16, 24, 32.
- Corner radius: 12 on cards, 999 on chips and pills, 16 on bottom sheets.
- Elevation: flat with 1 px outlines; shadows only on bottom sheets and dialogs.
- Icons: outline style, 24 dp, one set (Material Symbols Rounded or Lucide). Same set everywhere.

## Layout principles
- Mobile-first, portrait first; tablets and landscape must not break (cap content width ~640 dp and centre).
- Single column; thumb-reachable actions at the bottom; bottom tab bar with 4 items.
- Timeline rows: left rail with a vertical line connecting visit dots and trip segments, times on the left, details on the right.
- Density: comfortable by default; no dense data tables.
- Safe areas respected on notched phones and gesture navigation.

## Components
| Component | Variants and states |
|---|---|
| Tracking status chip | On (green dot, mode name), Paused, Off: permission needed, Off: location services disabled. Tappable |
| Primary / secondary / text buttons | Default, pressed, disabled, loading |
| Timeline visit row | Labelled, unlabelled ("Unknown place"), selected, with duration badge |
| Timeline trip row | Distance + time, tiny route preview, selected |
| Gap row | Grey dashed rail, reason text if known |
| Day header | Date, total distance, places count, weather icon |
| Map card | Route line, visit markers, tap to expand full screen |
| Calendar month grid | Today, selected, has-events dot, has-visits dot |
| Agenda item | Event (time + title), timeline entry (muted), weather chip |
| Event editor sheet | Text fields, date/time pickers, reminder picker, location field |
| Weather card | Current, hourly strip, daily list, stale-data label |
| Setting row | Switch, radio group, navigation, destructive (red text) |
| Segmented control | Battery modes with one-line description |
| Dialogs | Confirm, destructive confirm (type DELETE), permission rationale |
| Banners and snackbars | Info, warning (permission/battery), error with retry |
| Skeleton loaders | Timeline rows, forecast cards |
| Empty states | Icon + one sentence + one action |

## Interaction and motion
- Transitions: 200 ms ease-out for page and sheet changes; no parallax or bounce.
- Feedback: haptic tick on mode change and on successful save; snackbar for undo on delete (10 s).
- Map: pinch to zoom, tap marker to open the visit sheet.
- Tracking toggle on S5 animates a subtle pulse while recording (respect "reduce motion", then no pulse).
- Pull to refresh on timeline (re-run segmentation + labelling) and on weather.

## Accessibility
- Contrast: text at least 4.5:1, large text and UI components at least 3:1, in both themes.
- Touch targets at least 48 × 48 dp.
- Screen reader labels on every icon button; timeline rows read as "Visit, Java House, 2:00 PM to 3:10 PM, 1 hour 10 minutes".
- Maps are never the only source of information; every route and visit also exists as text.
- Dynamic text up to 200% without clipping; layouts scroll rather than truncate critical info.
- Reduce-motion and bold-text preferences respected.
- Colour is never the only state indicator.

## Content and tone
- Voice: plain, calm, first person from the user's side where possible. No jargon like "geofence" or "telemetry" in the UI.
- Be specific about privacy: "Your location stays on this phone unless you turn on sync."
- Error messages say what happened and what to do: "Couldn't reach the weather service. Showing the last forecast from 3 hours ago."
- Permission copy example: "Project B records where you go, even when the app is closed, so your timeline fills in by itself. It's stored on this phone. You can pause or delete it any time."
- Empty states: short and encouraging, never guilt-trippy.
- Dates and times follow the device locale; distances follow a units setting (km default).
