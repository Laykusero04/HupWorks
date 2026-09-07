from pathlib import Path

p = Path(r'lib/l10n/app_nl.arb')
t = p.read_text(encoding='utf-8')

# Fix corrupted "ë" (may appear as replacement char or leftover mojibake)
fixes = {
    '"categories": "Categorie\ufffdn"': '"categories": "Categorieën"',
    '"browseCategories": "Blader door categorie\ufffdn"': '"browseCategories": "Blader door categorieën"',
    '"noCategoriesYet": "Nog geen categorie\ufffdn"': '"noCategoriesYet": "Nog geen categorieën"',
    '"allCategories": "Alle categorie\ufffdn"': '"allCategories": "Alle categorieën"',
    '"searchCategories": "Zoek categorie\ufffdn"': '"searchCategories": "Zoek categorieën"',
    '"noCategoriesMatch": "Geen overeenkomende categorie\ufffdn"':
        '"noCategoriesMatch": "Geen overeenkomende categorieën"',
}

# Also force-set with unicode escapes regardless of current form
import re
t = re.sub(r'"categories":\s*"[^"]*"', '"categories": "Categorie\\u00ebn"', t)
t = re.sub(r'"browseCategories":\s*"[^"]*"', '"browseCategories": "Blader door categorie\\u00ebn"', t)
t = re.sub(r'"noCategoriesYet":\s*"[^"]*"', '"noCategoriesYet": "Nog geen categorie\\u00ebn"', t)
t = re.sub(r'"allCategories":\s*"[^"]*"', '"allCategories": "Alle categorie\\u00ebn"', t)
t = re.sub(r'"searchCategories":\s*"[^"]*"', '"searchCategories": "Zoek categorie\\u00ebn"', t)
t = re.sub(r'"noCategoriesMatch":\s*"[^"]*"', '"noCategoriesMatch": "Geen overeenkomende categorie\\u00ebn"', t)

# Decode unicode escapes in JSON-like strings by writing real chars
t = t.replace('\\u00eb', '\u00eb')

p.write_text(t, encoding='utf-8')
print(repr(re.search(r'"categories":\s*"[^"]*"', t).group(0)))
print('fixed')
