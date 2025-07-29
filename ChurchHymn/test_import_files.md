# Testing the Unified Import Functionality

## Overview
The app now has a single "Import" button that intelligently detects file types and automatically chooses the appropriate import method.

## Test Files

### 1. Plain Text Test File (test_hymn.txt)
```
Amazing Grace
# Key: C
# Author: John Newton
# Copyright: Public Domain

Amazing grace! How sweet the sound
That saved a wretch like me!
I once was lost, but now am found;
Was blind, but now I see.

'Twas grace that taught my heart to fear,
And grace my fears relieved;
How precious did that grace appear
The hour I first believed.
```

### 2. JSON Test File (test_hymn.json)
```json
{
  "title": "Amazing Grace",
  "lyrics": "Amazing grace! How sweet the sound\nThat saved a wretch like me!\nI once was lost, but now am found;\nWas blind, but now I see.\n\n'Twas grace that taught my heart to fear,\nAnd grace my fears relieved;\nHow precious did that grace appear\nThe hour I first believed.",
  "musicalKey": "C",
  "author": "John Newton",
  "copyright": "Public Domain",
  "tags": ["grace", "salvation"],
  "notes": "One of the most beloved hymns of all time"
}
```

### 3. Large JSON Test File (large_hymns.json)
Create a JSON array with many hymns to test the streaming functionality for files >10MB.

## Testing Steps

1. **Launch the app** and click the single "Import" button
2. **Select a .txt file** - should automatically detect as plain text and use plain text import
3. **Select a .json file** - should automatically detect as JSON and use regular JSON import
4. **Select a large .json file** (>10MB) - should automatically detect as JSON and use streaming import
5. **Select a file without extension** - should analyze content and choose appropriate method

## Expected Behavior

- **Single Import Button**: Only one "Import" button in the toolbar
- **File Type Detection**: Automatically detects .txt, .json, and content-based detection
- **Size-Based Optimization**: Automatically uses streaming for large JSON files
- **User Experience**: Simplified interface with intelligent backend processing

## Verification

- Check that only one "Import" button appears in the toolbar
- Verify that different file types are handled correctly
- Confirm that large files use streaming import
- Ensure the import preview and confirmation flow works as before 