from pathlib import Path

def replace_all(path, replacements):
    p = Path(path)
    text = p.read_text(encoding='utf-8')
    for old, new in replacements.items():
        if old not in text:
            print(f'MISSING in {p.name}: {old[:90]!r}')
        else:
            text = text.replace(old, new)
            print(f'OK {p.name}: {new[:90]}')
    p.write_text(text, encoding='utf-8')

# --- EN ---
replace_all(r'c:\seve\flutter\HupWorks\lib\l10n\app_en.arb', {
  '"myApplications": "My Applications"': '"myApplications": "My shifts"',
  '"jobTypeGig": "Individual services"': '"jobTypeGig": "Shift"',
  '"instructionsReadyTap": "Instructions ready — tap to read"':
      '"instructionsReadyTap": "Instructions ready, read here"',
})

# Insert budget suffixes after statusPending if not present
en = Path(r'c:\seve\flutter\HupWorks\lib\l10n\app_en.arb')
en_text = en.read_text(encoding='utf-8')
if '"budgetSuffixHour"' not in en_text:
    en_text = en_text.replace(
        '"statusPending": "Pending",',
        '"statusPending": "Pending",\n'
        '  "budgetSuffixHour": "/hr",\n'
        '  "budgetSuffixDay": "/day",\n'
        '  "budgetSuffixMonth": "/mo",\n'
        '  "budgetSuffixTotal": "total",',
    )
    en.write_text(en_text, encoding='utf-8')
    print('OK en: budget suffixes added')

# --- NL ---
replace_all(r'c:\seve\flutter\HupWorks\lib\l10n\app_nl.arb', {
  '"myApplications": "Mijn aanmeldingen"': '"myApplications": "Mijn shifts"',
  '"jobTypeGig": "Losse diensten"': '"jobTypeGig": "Shift"',
  '"instructionsReadyTap": "Instructies klaar — tik om te lezen"':
      '"instructionsReadyTap": "Instructies ready, lees hier"',
  '"browseCategories": "Blader door categorieÃ«n"': '"browseCategories": "Blader door categorieën"',
  '"categories": "CategorieÃ«n"': '"categories": "Categorieën"',
  '"noCategoriesYet": "Nog geen categorieÃ«n"': '"noCategoriesYet": "Nog geen categorieën"',
  '"allCategories": "Alle categorieÃ«n"': '"allCategories": "Alle categorieën"',
  '"searchCategories": "Zoek categorieÃ«n"': '"searchCategories": "Zoek categorieën"',
  '"noCategoriesMatch": "Geen overeenkomende categorieÃ«n"':
      '"noCategoriesMatch": "Geen overeenkomende categorieën"',
})

nl = Path(r'c:\seve\flutter\HupWorks\lib\l10n\app_nl.arb')
nl_text = nl.read_text(encoding='utf-8')
if '"budgetSuffixHour"' not in nl_text:
    nl_text = nl_text.replace(
        '"statusPending": "In afwachting",',
        '"statusPending": "In afwachting",\n'
        '  "budgetSuffixHour": "/uur",\n'
        '  "budgetSuffixDay": "/dag",\n'
        '  "budgetSuffixMonth": "/mnd",\n'
        '  "budgetSuffixTotal": "totaal",',
    )
    # try alternate if statusPending wording differs
    if '"budgetSuffixHour"' not in nl_text:
        # find statusPending line
        import re
        m = re.search(r'"statusPending": "[^"]+",', nl_text)
        if m:
            nl_text = nl_text.replace(
                m.group(0),
                m.group(0) + '\n'
                '  "budgetSuffixHour": "/uur",\n'
                '  "budgetSuffixDay": "/dag",\n'
                '  "budgetSuffixMonth": "/mnd",\n'
                '  "budgetSuffixTotal": "totaal",',
            )
    nl.write_text(nl_text, encoding='utf-8')
    print('OK nl: budget suffixes added')

# BN needs keys too for gen-l10n
bn = Path(r'c:\seve\flutter\HupWorks\lib\l10n\app_bn.arb')
bn_text = bn.read_text(encoding='utf-8')
if '"budgetSuffixHour"' not in bn_text:
    import re
    m = re.search(r'"statusPending": "[^"]+",', bn_text)
    if m:
        bn_text = bn_text.replace(
            m.group(0),
            m.group(0) + '\n'
            '  "budgetSuffixHour": "/hr",\n'
            '  "budgetSuffixDay": "/day",\n'
            '  "budgetSuffixMonth": "/mo",\n'
            '  "budgetSuffixTotal": "total",',
        )
        bn.write_text(bn_text, encoding='utf-8')
        print('OK bn: budget suffixes added')

print('done')
