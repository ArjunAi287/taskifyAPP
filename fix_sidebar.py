import re

# Read the file
with open(r'd:\localRepo_Arjun\reminderFlutter\taskify_app\lib\ui\layout\adaptive_scaffold.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to find and replace the sidebar logo
old_pattern = r'''child: Image\.asset\(
\s+'assets/taskify_logo\.png',
\s+height: 28,
\s+fit: BoxFit\.contain,
\s+alignment: Alignment\.centerLeft,
\s+\)\.animate\(\)\.fade\(\)\.slideX\(\),'''

new_code = '''child: Text(
                                'Taskify',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                                overflow: TextOverflow.fade,
                                softWrap: false,
                              ).animate().fade().slideX(),'''

# Replace
content = re.sub(old_pattern, new_code, content)

# Write back
with open(r'd:\localRepo_Arjun\reminderFlutter\taskify_app\lib\ui\layout\adaptive_scaffold.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Successfully replaced sidebar logo with text!")
