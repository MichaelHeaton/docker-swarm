# SABnzbd Post-Setup Configuration

## Glitter Tips and Tricks

Based on [SABnzbd Glitter Tips and Tricks](https://sabnzbd.org/wiki/extra/glitter-tips-and-tricks), here are useful configurations to consider:

### UI Enhancements

1. **Extra Queue and History Columns**

   - Location: Status and Interface settings → Web Interface
   - Enable: Category, Script, and other useful columns
   - Benefit: See more information at a glance

2. **Tabbed Layout**

   - Location: Status and Interface settings → Web Interface
   - Enable: Separate Queue and History into tabs (like Classic interface)
   - Benefit: Better organization if preferred

3. **Keyboard Shortcuts**

   - Default shortcuts: `P`ause, `A`dd, `S`tatus, `C`onfig
   - New in 3.7.0: `Shift + Arrow-key` to navigate Queue/History
   - Location: Status and Interface settings → Web Interface
   - Can be disabled if not needed

4. **Date/Time Format**

   - Location: Status and Interface settings → Web Interface
   - Option: Twitter/Facebook-style time display
   - Benefit: More readable relative time format

5. **Disable Delete Confirmations**
   - Location: Status and Interface settings → Web Interface
   - Option: Disable confirmation dialogs when deleting jobs/history
   - **Warning**: No way to restore after deletion

### Workflow Improvements

6. **Edit Multiple Jobs**

   - Click the edit icon to select multiple jobs
   - Apply changes to all selected jobs at once
   - Useful for bulk operations

7. **Search Queue and History**

   - Advanced filtering available
   - Search box appears when queue exceeds item limit
   - Delete all items matching search term

8. **Drag-and-Drop NZBs**

   - Drag multiple NZB files directly onto the interface
   - Supports archives containing multiple NZBs
   - Faster than manual upload

9. **Quick Password for Job**

   - Add password to job name: `JOBNAME / PASSWORD123`
   - SABnzbd will parse and set the password
   - Format: `/` followed by password

10. **Custom Pause Duration**

    - Use Custom pause option
    - Examples: `90 minutes`, `2 days`, `Friday 2am`, `tomorrow 17:00`
    - More flexible than preset options

11. **Quick Speedlimit Clear**
    - Click the speedlimit icon to quickly remove speed limit
    - No need to go into settings

## Recommended Post-Setup Configurations

### High Priority

- **Extra Columns**: Enable Category and Script columns for better visibility
- **Drag-and-Drop**: Already works, but good to know about

### Medium Priority

- **Tabbed Layout**: If preferred over single-page view
- **Date/Time Format**: If Twitter-style is preferred
- **Keyboard Shortcuts**: If using keyboard navigation

### Low Priority

- **Disable Delete Confirmations**: Only if confident in actions
- **Custom Pause**: Useful for scheduling downloads

## Reference

- [SABnzbd Glitter Tips and Tricks](https://sabnzbd.org/wiki/extra/glitter-tips-and-tricks)
