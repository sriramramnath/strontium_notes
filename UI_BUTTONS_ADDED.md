# All Buttons and UI Elements Added to Strontium Notes

## Activity Bar (Left Sidebar - 48px wide)
**Background**: #2d2d2d (dark gray)
**Icon Size**: 18px
**Button Size**: 48x44px
**Rounding**: 0px (square)

### Top Icons:
1. **Files Explorer** - `doc.text.fill` - Opens file tree
2. **Search** - `magnifyingglass` - Opens search panel
3. **Bookmarks** - `bookmark.fill` - Bookmarks/starred items
4. **Recent Files** - `doc.on.doc.fill` - Recent files list
5. **Graph View** - `star.fill` - Graph visualization
6. **Daily Notes** - `calendar` - Daily notes view
7. **Canvas** - `square.grid.2x2.fill` - Canvas view
8. **Settings/Plugins** - `slider.horizontal.3` - Settings panel
9. **Tools** - `wrench.and.screwdriver.fill` - Tools menu

### Bottom Icons:
1. **Open Folder** - `folder` - Opens vault folder picker
2. **Settings** - `gearshape.fill` - Opens settings

## Sidebar Header Toolbar
**Background**: #252525 (sidebar background)
**Button Size**: 28x28px
**Spacing**: 4px between buttons

### Buttons (when Files view is active):
1. **Folder** - `folder` - Folder operations
2. **Search** - `magnifyingglass` - Quick search
3. **Bookmark** - `bookmark` - Add bookmark
4. **Plus Menu** - `plus` - Create new note/folder dropdown

## Editor Top Toolbar
**Background**: #2d2d2d (secondary background)
**Button Size**: 32x32px
**Spacing**: 2px between buttons

### Left Side:
1. **Folder** - `folder` - File operations
2. **Search** - `magnifyingglass` - Search in file
3. **Bookmark** - `bookmark` - Bookmark file

### Right Side:
1. **Split View** - `square.split.2x1` - Split editor
2. **Right Sidebar** - `sidebar.right` - Toggle right sidebar
3. **More Options** - `ellipsis` - Context menu with:
   - Rename
   - Delete
   - Copy Path
   - Reveal in Finder

## Tab Bar
**Background**: #2d2d2d (secondary background)
**Height**: 36px
**Rounding**: 0px (square tabs)

### Elements:
1. **Back Button** - `chevron.left` - Navigate back (28x36px)
2. **Forward Button** - `chevron.right` - Navigate forward (28x36px)
3. **Active Tab** - Shows file name with close button
4. **Close Tab** - `xmark` - Close current tab (20x20px)
5. **New Tab** - `plus` - Create new tab (32x36px)

## Breadcrumb Bar
**Background**: #1e1e1e (darker background)
**Height**: ~28px
**Font Size**: 12px

### Elements:
1. **Folder Path** - "Markdown" (tertiary text)
2. **Separator** - `chevron.right` (10px)
3. **File Name** - Current file name (secondary text)
4. **Split View Button** - `square.split.2x1` (24x24px)
5. **More Options** - `ellipsis` (24x24px)

## Status Bar (Bottom)
**Background**: #2d2d2d (secondary background)
**Height**: 24px
**Font Size**: 11-12px

### Left Side:
1. **Backlinks Count** - "0 backlinks"
2. **Edit Icon** - `pencil` - Edit indicator
3. **Word Count** - "X words"
4. **Character Count** - "X characters"

## Color Scheme (Exact Obsidian Colors)
- **Darkest Background**: #1e1e1e (editor)
- **Dark Background**: #252525 (sidebar)
- **Medium Dark**: #2d2d2d (activity bar, tabs)
- **Lighter Gray**: #3a3a3a (borders, toolbar)
- **Text Primary**: #ffffff (headings - white)
- **Text Secondary**: #d4d4d4 (body text)
- **Text Tertiary**: #8a8a8a (metadata)
- **Accent**: #b4b4b4 (neutral gray - NO PURPLE, NO BLUE)
- **Borders**: #3a3a3a

## Design Principles Applied
1. **No Rounding**: All buttons and panels are square (0px border-radius)
2. **Neutral Colors**: Only gray tones, no purple or blue accents
3. **Consistent Spacing**: 2-4px between toolbar buttons, 8px for larger gaps
4. **Icon Sizes**: 14-18px for most icons, 10-12px for small icons
5. **Button Sizes**: 24-32px for most buttons, 48x44px for activity bar
6. **Minimal Padding**: Tight spacing matching Obsidian's compact design

## All Buttons Are Functional
- Activity bar icons switch sidebar views
- Toolbar buttons trigger appropriate actions
- Tab navigation works with back/forward/close
- Context menus provide file operations
- Status bar shows live document stats
