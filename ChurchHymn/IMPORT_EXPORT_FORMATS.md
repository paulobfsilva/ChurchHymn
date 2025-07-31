# Church Hymn App Import/Export File Formats

## Plain Text Format (Single Hymn)

- The first non-empty, non-`#` line is the hymn title.
- Metadata lines start with `#` and a keyword:
  - `#Number:` - Song number (integer)
  - `#Key:` - Musical key
  - `#Author:` - Author name
  - `#Copyright:` - Copyright information
  - `#Tags:` - Comma-separated list of tags
  - `#Notes:` - Additional notes or comments
- Lyrics follow, with verses and choruses separated by empty lines.
- Chorus blocks start with the word `CHORUS` (case-insensitive) on their own line.

**Example:**
```
Amazing Grace
#Number: 123
#Key: G Major
#Author: John Newton
#Copyright: Public Domain
#Tags: classic, grace, hymn
#Notes: Written in 1772

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
- All metadata lines starting with `#` must appear before the lyrics.
- Empty metadata values are ignored (e.g., `#Key: ` will not set a key).
- Tags are split by commas and whitespace is trimmed from each tag.
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
  "tags": ["classic", "grace", "hymn"],
  "notes": "Written in 1772"
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
    "notes": "Written in 1772"
  },
  {
    "title": "How Great Thou Art",
    "songNumber": 124,
    "author": "Carl Boberg",
    "copyright": "Public Domain",
    "musicalKey": "E Major",
    "lyrics": "...",
    "tags": ["classic", "worship"],
    "notes": "Swedish origin"
  }
]
```

**JSON Format Rules:**
- All fields except `title` are optional
- `songNumber` must be a positive integer if provided
- `tags` must be an array of strings if provided
- `lyrics` uses `\n` for line breaks
- Empty strings and null values are treated the same
- Whitespace is trimmed from all string fields 