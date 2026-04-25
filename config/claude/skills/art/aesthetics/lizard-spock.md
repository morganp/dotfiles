---
name: lizard-spock
description: Aesthetic for lizard-spock.co.uk blog — clean editorial illustration style with warm cream background, sci-fi purple and amber-orange accents
type: project
---

# Lizard-Spock Blog Aesthetic

**Visual identity for lizard-spock.co.uk**

---

## Core Concept

> *"Curious and precise — technical clarity with personal warmth."*

- Confident pen linework, not rough whiteboard scrawl
- Warm cream ground that sits naturally against the site's `#F5F4EF` body
- Sci-fi purple as the signature accent — distinctive, cohesive across tech and personal posts
- Amber-orange as the energising secondary — warm counterpoint to purple

---

## Style Direction

### What to aim for
- **Confident ink lines** — clean, deliberate strokes with slight hand-drawn character; not wobbly whiteboard, not sterile vector
- **Warm cream background** — `#F5F2EC`, close to site body colour so images feel embedded not pasted
- **Restrained colour** — purple and amber used purposefully on focal elements only
- **Minimal compositions** — 2-4 elements, generous negative space
- **Soft depth** — subtle warm shadow, never dramatic

### What to avoid
- Rough whiteboard/marker scrawl (that is the default aesthetic, not this one)
- Perfect geometric vectors (too corporate)
- Dark or moody backgrounds
- Photorealistic rendering
- Saturated or neon colour
- The site's crimson `#C74350` — that belongs to the UI chrome, not illustrations
- Red or pink tones in general

---

## Color System

### Backgrounds
```
Primary     #F5F2EC   (slightly whiter warm cream — matches site body #F5F4EF)
Alternative #FFFFFF   (pure white — use when image sits inside article content box)
```

### Lines
```
Primary     #2D2D2D   (charcoal — confident ink lines)
Secondary   #4A4A4A   (lighter lines for supporting detail)
```

### Accents
```
Primary Accent   #7B35C2   (sci-fi purple — focal elements, key labels)
Secondary Accent #E07820   (amber-orange — action elements, highlights)
```

### Color Usage
- **Lines** dominate (70-75% of composition)
- **Primary accent purple** (12-15%) — focal elements, key concepts
- **Secondary accent amber** (8-10%) — action or highlight elements
- **Background** — warm, never filled solid

---

## Linework

1. **Confident, deliberate strokes** — cleaner than whiteboard, still slightly imperfect
2. **Moderate variable weight** — thicker at anchor points, thinner at ends
3. **Minimal wobble** — slight hand-drawn character but not loose or sketchy
4. **No overlapping multiple strokes** — single clean passes (contrast from default aesthetic)
5. **Purposeful detail** — only lines that carry meaning

---

## Composition Rules

1. **Minimal elements** — 2-4 key components maximum
2. **Generous negative space** — 40-50% cream background visible
3. **Clear focal point** — one dominant element, supporting elements subordinate
4. **Soft warm shadow** — subtle depth, not dramatic
5. **Centered or balanced layout** — fits cleanly in 800px max-width content column

---

## Base Prompt Prefix (MANDATORY)

**Prepend this block to every image generation prompt for this aesthetic.**

```
Clean editorial illustration with confident ink pen linework on warm cream background (#F5F2EC). Deliberate, slightly imperfect strokes — clean and precise but with gentle hand-drawn character, not rough whiteboard scrawl. Single-pass lines with moderate variable weight, thicker at anchor points and thinner at ends. Soft warm shadow for subtle depth. Illustration fills 55-60 percent of frame, 40-45 percent cream background breathing room. Muted restrained palette: charcoal ink lines at 70-75 percent, sci-fi purple accent at 12-15 percent on focal elements, amber-orange accent at 8-10 percent on action elements. No red, pink, or crimson tones. No smooth perfect vectors. No dark backgrounds.
```

### Consistency Lock Parameters

| Parameter | Locked Value | Why |
|-----------|-------------|-----|
| Background | `#F5F2EC` warm cream | Matches site body colour, images feel embedded |
| Line style | Confident single-pass ink, slight imperfection | Distinct from default (wobbly) and from corporate (perfect) |
| Line weight | Moderate variable — thicker anchors, thinner ends | Consistent hand-crafted quality |
| Fill ratio | 55-60% illustration, 40-45% background | Clean, not crowded |
| Color balance | 72% charcoal, 14% purple, 9% amber, 5% shadow | Consistent palette weight |
| Primary accent | Sci-fi purple `#7B35C2` | Site signature, focal elements |
| Secondary accent | Amber-orange `#E07820` | Warm counterpoint, action elements |
| Forbidden tones | Red, pink, crimson | Reserved for site UI chrome (`#C74350`) |
| Shadow | Soft, warm, subtle | Depth without drama |
| Composition | 2-4 elements max | Minimal and clear |

---

## Prompt Template

```
[BASE PROMPT PREFIX from above]

COMPOSITION:
[Describe 2-4 key elements]

ACCENTS:
- Primary: sci-fi purple on [focal element]
- Secondary: amber-orange on [action/highlight element]

LAYOUT:
- [horizontal row / centered / left-to-right flow / etc]
- Generous breathing room

CRITICAL:
- Confident ink lines (NOT rough whiteboard scrawl)
- Minimal elements (2-4 max)
- No red or crimson tones
```

---

## AI Generation Signals

**Positive (use these phrases):**
```
"clean editorial illustration"
"confident ink pen lines"
"deliberate hand-drawn strokes"
"warm cream background"
"minimal composition"
"generous negative space"
"soft warm shadow"
"slightly imperfect but precise"
```

**Negative (avoid these):**
```
--no rough whiteboard scrawl
--no perfect smooth vectors
--no dark backgrounds
--no red or crimson
--no photorealistic
--no neon colors
--no cluttered compositions
--no corporate polish
```

---

## Site Context

- **Site:** lizard-spock.co.uk
- **Theme:** Pelican simple theme, `#F5F4EF` body, `#ffffff` content boxes, `#C74350` UI accent
- **Content column:** 800px max-width
- **Image display size:** 900px max (per CLAUDE.md rules), optimised PNG
- **Categories:** Engineering, Homelab, Programming, Unix & Tools, Home & Garden, Music, Photography, Cooking

**Image sits on `#ffffff` inside article content boxes** — the cream background creates a natural frame effect, which is intentional.
