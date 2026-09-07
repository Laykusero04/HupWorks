from pathlib import Path
t = Path(r'lib/l10n/app_nl.arb').read_text(encoding='utf-8')
for k in ['categories', 'browseCategories', 'myApplications', 'jobTypeGig', 'budgetSuffixHour', 'instructionsReadyTap', 'statusPending']:
    i = t.find(f'"{k}"')
    print(k, repr(t[i:i + 70]))
