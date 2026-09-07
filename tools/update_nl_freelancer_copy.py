from pathlib import Path

p = Path(r'c:\seve\flutter\HupWorks\lib\l10n\app_nl.arb')
text = p.read_text(encoding='utf-8')
replacements = {
  '"findJobs": "Vacatures"': '"findJobs": "Jobs"',
  '"findYourNextJob": "Vind je volgende job"': '"findYourNextJob": "Vind je volgende shift"',
  '"findYourNextJobSubtitle": "Bekijk openstaande rollen en solliciteer in minuten."':
      '"findYourNextJobSubtitle": "Bekijk openstaande shifts en meld je aan in minuten."',
  '"myApplications": "Mijn sollicitaties"': '"myApplications": "Mijn aanmeldingen"',
  '"applications": "Sollicitaties"': '"applications": "Aanmeldingen"',
  '"shortcutFindJobs": "Vacatures"': '"shortcutFindJobs": "Jobs"',
  '"shortcutApplications": "Sollicitaties"': '"shortcutApplications": "Aanmeldingen"',
  '"pendingApplications": "Openstaande sollicitaties"': '"pendingApplications": "Openstaande aanmeldingen"',
  '"findJobsTitle": "Vacatures zoeken"': '"findJobsTitle": "Jobs zoeken"',
  '"attentionOnsiteOne": "1 contract op locatie â€” inchecken via Aanwezigheid"':
      '"attentionOnsiteOne": "1 overeenkomst op locatie - inchecken via Aanwezigheid"',
  '"attentionOnsiteMany": "{count} contracten op locatie â€” gebruik Aanwezigheid"':
      '"attentionOnsiteMany": "{count} overeenkomsten op locatie - gebruik Aanwezigheid"',
  '"noApplicationsYet": "Nog geen sollicitaties"': '"noApplicationsYet": "Nog geen aanmeldingen"',
  '"noApplicationsYetHint": "Blader door open vacatures en stuur een duidelijk voorstel."':
      '"noApplicationsYetHint": "Blader door open jobs en stuur een duidelijk voorstel."',
  '"chatFilterApplications": "Sollicitaties"': '"chatFilterApplications": "Aanmeldingen"',
  '"chatTagApplication": "Sollicitatie"': '"chatTagApplication": "Aanmelding"',
  '"applicationsSection": "Sollicitaties"': '"applicationsSection": "Aanmeldingen"',
  '"applicationsReceived": "Sollicitaties"': '"applicationsReceived": "Aanmeldingen"',
  '"errorLoadingApplications": "Fout bij laden sollicitaties: {message}"':
      '"errorLoadingApplications": "Fout bij laden aanmeldingen: {message}"',
  '"applicationRejected": "Sollicitatie afgewezen"': '"applicationRejected": "Aanmelding afgewezen"',
}
for old, new in replacements.items():
    if old not in text:
        print('MISSING:', repr(old[:100]))
    else:
        text = text.replace(old, new)
        print('OK:', new[:90])
p.write_text(text, encoding='utf-8')
print('written')
