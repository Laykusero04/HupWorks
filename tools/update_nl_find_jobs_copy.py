from pathlib import Path

p = Path(r'c:\seve\flutter\HupWorks\lib\l10n\app_nl.arb')
text = p.read_text(encoding='utf-8')
replacements = {
  '"submitOfferTitle": "Sollicitatie indienen"': '"submitOfferTitle": "Aanmelding indienen"',
  '"applyAtClientRate": "Solliciteer tegen klanttarief"': '"applyAtClientRate": "Meld je aan tegen klanttarief"',
  '"offerSentAtPostedRate": "Sollicitatie verzonden tegen klanttarief"':
      '"offerSentAtPostedRate": "Aanmelding verzonden tegen klanttarief"',
  '"offerSentSuccess": "Je sollicitatie is verzonden"': '"offerSentSuccess": "Je aanmelding is verzonden"',
  '"applyWithoutCounterBody": "Je solliciteert tegen het tarief van de klant. Zij zien je sollicitatie tegen dat tarief."':
      '"applyWithoutCounterBody": "Je meldt je aan tegen het tarief van de klant. Zij zien je aanmelding tegen dat tarief."',
  '"yourApplicationAmount": "Je sollicitatie: {amount}"': '"yourApplicationAmount": "Je aanmelding: {amount}"',
  '"yourOfferAmount": "Jouw sollicitatiebedrag"': '"yourOfferAmount": "Jouw aanmeldingsbedrag"',
  '"buyerRequestDetailsTitle": "Vacaturedetails"': '"buyerRequestDetailsTitle": "Jobdetails"',
  '"submitOfferAction": "Sollicitatie indienen"': '"submitOfferAction": "Aanmelding indienen"',
  '"cannotSubmitApplication": "Kan niet solliciteren"': '"cannotSubmitApplication": "Kan niet aanmelden"',
  '"offersCount": "{count} sollicitaties"': '"offersCount": "{count} aanmeldingen"',
  '"openJobsToBrowse": "{count} open vacatures om te bekijken"':
      '"openJobsToBrowse": "{count} open jobs om te bekijken"',
  '"untitledJob": "Vacature zonder titel"': '"untitledJob": "Job zonder titel"',
}
for old, new in replacements.items():
    if old not in text:
        print('MISSING:', repr(old[:110]))
    else:
        text = text.replace(old, new)
        print('OK:', new[:90])
p.write_text(text, encoding='utf-8')
print('written')
