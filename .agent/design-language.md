# mklat.news Design Language — Civic Calm

## Visual philosophy

**Civic Calm** treats emergency information as a public instrument: quiet, exact, and trustworthy before it is dramatic. The interface should feel like a carefully maintained civic dashboard rather than a consumer news app or a siren. Space is generous, hierarchy is firm, and every surface has an obvious role. The final product should look meticulously crafted, as if each radius, line weight, and color step was tested many times under stress, daylight, night mode, and motion.

The core composition is a stack of calm panels. A single primary status panel owns the screen; supporting material sits below it in disciplined bands. Rounded rectangles are used as instruments, not decoration. Dividers are rare and soft. The grid is simple: wide side margins, consistent vertical rhythm, and touch targets that feel deliberately placed for one-handed use. Visual weight must communicate importance before the user reads a word.

Color is semantic and restrained. **Red is reserved for active danger.** **Amber is reserved for warning or degraded alert data.** **Green means clear.** **Connectivity is neutral slate**, never orange, because network state is infrastructure health, not an emergency alert. Blue is the brand/control color: location selection, navigation, links, and primary actions. Backgrounds are pale blue-gray, allowing emergency colors to remain meaningful when they appear.

Typography is Hebrew-first and functional. Titles are large, heavy, and short; support text is smaller and calm. Text should never crowd icons or fight for attention. The craft standard is high: Hebrew alignment, ellipsis behavior, line breaks, and RTL icon placement must look intentional and polished. Every component should appear as the product of deep expertise, not default Material widgets dropped onto a page.

Graphics use one icon language: simple filled/outlined Material symbols with consistent stroke/weight. Avoid emoji-like mixed styles, glossy assets, and cartoon metaphors. Status icons are abstract civic signals: circle-check/verified for clear, report/warning for uncertain, shield or crisis-alert for active danger, cloud-off for connectivity. The result should feel painstakingly coherent: quiet when safe, unmistakable when unsafe, neutral when the network is the problem.

## Color system

| Role | Token | Hex | Use |
|---|---:|---:|---|
| Brand/control blue | `brandBlue` | `#2F5F8F` | Navigation, selected tab, links, location controls |
| App background | `appBackground` | `#F5F7FB` | Scaffold background |
| Card surface | `cardSurface` | `#FFFFFF` | Cards, sheets, fields |
| All clear | `statusGreen` | `#2E7D57` | Safe status, check marks |
| All clear tint | `statusGreenTint` | `#EAF6EF` | Primary clear card background |
| Warning/degraded | `statusAmber` | `#C47A00` | Alert-data errors, expected/unknown alert states |
| Warning tint | `statusAmberTint` | `#FFF5DF` | Warning state surfaces |
| Active danger | `statusRed` | `#C62828` | Active red alert only |
| Danger tint | `statusRedTint` | `#FFE9E9` | Active alert surfaces |
| Connectivity neutral | `connectivitySlate` | `#60717D` | Offline text/icon/status |
| Connectivity tint | `connectivityTint` | `#E8EEF2` | Offline banner/card background |
| Muted text | `mutedText` | `#6B7780` | Empty states, section labels |
| Hairline | `hairline` | `#D7DEE5` | Dividers and subtle borders |

## Component rules

### Primary status card
- Full-width card with 16px outer margin, 24px internal padding, 24px radius.
- Surface has a semantic tint plus a stronger 4px vertical/start accent bar.
- Location selector is a real control chip, not a gray disabled-looking field.
- Icon is a Material icon inside a soft circular badge; no emoji/status art.
- Title is the largest element; instruction and timer are secondary.

### Connectivity banner
- Neutral slate background/tint.
- Compact height, polite motion, no alarm orange.
- Copy: “אין חיבור לאינטרנט”. Visual priority below red/amber alert states.

### Navigation
- Replace unlabeled dots with labeled bottom navigation: `מצב` and `חדשות`.
- Keep swipe if desired, but discovery should not rely on dots.
- Selected state uses brand blue; unselected uses muted slate.

### Empty states
- Use compact cards, not floating gray text in vast blank space.
- Include one icon, one short message, optional action button.
- Position in the upper-middle of available content, not near the bottom.

### Add location
- Use a sheet-like white card for form fields.
- Search results are rounded list rows with subtle separators or selected tint.
- Selected row uses a green check badge close to the row text.
- Save button becomes visually primary only after a location is selected.

## Implementation order

1. Add `AppTheme` tokens for Civic Calm.
2. Replace page dots with labeled bottom navigation.
3. Redesign `PrimaryStatusCard` around semantic surfaces and Material status icons.
4. Restyle `OfflineBanner` with neutral slate.
5. Restyle `AddLocationScreen` fields, rows, selected state, and save button.
6. Re-capture screenshots and compare against this design board before committing.
