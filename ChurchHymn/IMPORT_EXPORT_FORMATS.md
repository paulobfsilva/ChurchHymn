# Church Hymn App Import/Export File Formats

## Plain Text Format (Single Hymn)

- The first non-empty, non-`#` line is the hymn title.
- Metadata lines start with `#` and a keyword (e.g., `#Number:`, `#Key:`, `#Author:`, `#Copyright:`).
- Lyrics follow, with verses and choruses separated by empty lines.
- Chorus blocks start with the word `CHORUS` (case-insensitive) on their own line.

**Example:**
```
Amazing Grace
#Number: 123
#Key: G Major
#Author: John Newton
#Copyright: Public Domain

Amazing grace! how sweet the sound
That saved a wretch like me!
I once was lost, but now am found,
Was blind, but now I see.

CHORUS
Praise God, praise God,
Praise God, praise God.

'Twas grace that taught my heart to fear,
And grace my fears relieved;
How precious did that grace appear
The hour I first believed.

CHORUS
Praise God, praise God,
Praise God, praise God.
```

**Parsing Rules:**
- Lines starting with `#Number:`, `#Key:`, `#Author:`, `#Copyright:` are parsed as metadata.
- The first non-empty, non-`#` line is the title.
- Lyrics are everything after the metadata, with blocks separated by empty lines.
- Chorus blocks are recognized by a line with `CHORUS`.

---

## JSON Format (Single or Batch Hymn)

### Single Hymn Example
```json
{
  "title": "Amazing Grace",
  "songNumber": 123,
  "author": "John Newton",
  "copyright": "Public Domain",
  "musicalKey": "G Major",
  "lyrics": "Amazing grace! how sweet the sound\\nThat saved a wretch like me!\\nI once was lost, but now am found,\\nWas blind, but now I see.\\n\\nCHORUS\\nPraise God, praise God,\\nPraise God, praise God.\\n\\n'Twas grace that taught my heart to fear,\\nAnd grace my fears relieved;\\nHow precious did that grace appear\\nThe hour I first believed.\\n\\nCHORUS\\nPraise God, praise God,\\nPraise God, praise God.",
  "tags": ["classic", "grace"],
  "notes": ""
}
```

### Batch Hymn Example
```json
[
  {
    "title": "Amazing Grace",
    "songNumber": 123,
    "author": "John Newton",
    "copyright": "Public Domain",
    "musicalKey": "G Major",
    "lyrics": "...",
    "tags": ["classic", "grace"],
    "notes": ""
  },
  {
    "title": "How Great Thou Art",
    "songNumber": 124,
    "author": "Carl Boberg",
    "copyright": "Public Domain",
    "musicalKey": "A Major",
    "lyrics": "...",
    "tags": ["worship"],
    "notes": ""
  }
]
```

**Schema Notes:**
- All fields except `title` are optional.
- `songNumber` is an optional integer field.
- `lyrics` is a single string, with blocks separated by double newlines (`\n\n`).
- `tags` is an array of strings.
- Batch import/export is a JSON array of hymn objects.

---

## Summary

- **Plain text**: Human-friendly, easy for single hymns.
- **JSON**: Machine-friendly, supports single or batch import/export.
- All fields except `title` are optional in both formats.

---

**For developers:**  
- Update this file if the format changes.
- See code for parsing/serialization logic.
- Current model version: 2 (added songNumber field)

This file will serve as a reference for users and developers. 