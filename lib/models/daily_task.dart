import 'localized_name.dart';

/// A small painting prompt shown once per day on the home screen.
///
/// Translated in the model, not in the ARB files (same trade-off as
/// pages.json): 45 prompts × 9 languages would be 405 keys for something that
/// is really data, and a new prompt would touch nine files instead of one.
class DailyTask {
  final String id;
  final String emoji;
  final String title;
  final String titleEn;

  /// The other seven languages, keyed by language code — see [localizedName].
  /// `test/page_names_test.dart` insists every task has all of them.
  final Map<String, String>? titles;

  const DailyTask({
    required this.id,
    required this.emoji,
    required this.title,
    required this.titleEn,
    this.titles,
  });

  String titleFor(String languageCode) =>
      localizedName(languageCode, de: title, en: titleEn, more: titles);
}

const List<DailyTask> kDailyTasks = [
  DailyTask(
    id: 'red',
    emoji: '🍎',
    title: 'Male etwas Rotes!',
    titleEn: 'Paint something red!',
    titles: {
      'es': '¡Pinta algo rojo!',
      'fr': 'Dessine quelque chose de rouge !',
      'it': 'Disegna qualcosa di rosso!',
      'nl': 'Maak iets roods!',
      'pl': 'Namaluj coś czerwonego!',
      'pt': 'Pinta algo vermelho!',
      'tr': 'Kırmızı bir şey boya!',
    },
  ),
  DailyTask(
    id: 'animals',
    emoji: '🐶',
    title: 'Stemple 5 Tiere!',
    titleEn: 'Stamp 5 animals!',
    titles: {
      'es': '¡Estampa 5 animales!',
      'fr': 'Tamponne 5 animaux !',
      'it': 'Timbra 5 animali!',
      'nl': 'Stempel 5 dieren!',
      'pl': 'Odbij 5 zwierzątek!',
      'pt': 'Estampa 5 animais!',
      'tr': '5 hayvan damgala!',
    },
  ),
  DailyTask(
    id: 'rainbowpen',
    emoji: '🌈',
    title: 'Male mit dem Regenbogen-Stift!',
    titleEn: 'Draw with the rainbow pen!',
    titles: {
      'es': '¡Dibuja con el lápiz arcoíris!',
      'fr': 'Dessine avec le crayon arc-en-ciel !',
      'it': 'Disegna con la matita arcobaleno!',
      'nl': 'Teken met de regenboogpen!',
      'pl': 'Rysuj tęczową kredką!',
      'pt': 'Desenha com o lápis arco-íris!',
      'tr': 'Gökkuşağı kalemiyle çiz!',
    },
  ),
  DailyTask(
    id: 'sun',
    emoji: '☀️',
    title: 'Male eine Sonne!',
    titleEn: 'Paint a sun!',
    titles: {
      'es': '¡Pinta un sol!',
      'fr': 'Dessine un soleil !',
      'it': 'Disegna un sole!',
      'nl': 'Maak een zon!',
      'pl': 'Namaluj słońce!',
      'pt': 'Pinta um sol!',
      'tr': 'Bir güneş boya!',
    },
  ),
  DailyTask(
    id: 'butterfly',
    emoji: '🦋',
    title: 'Probiere den Zauber-Spiegel aus!',
    titleEn: 'Try the magic mirror!',
    titles: {
      'es': '¡Prueba el espejo mágico!',
      'fr': 'Essaie le miroir magique !',
      'it': 'Prova lo specchio magico!',
      'nl': 'Probeer de toverspiegel!',
      'pl': 'Wypróbuj magiczne lustro!',
      'pt': 'Experimenta o espelho mágico!',
      'tr': 'Sihirli aynayı dene!',
    },
  ),
  DailyTask(
    id: 'house',
    emoji: '🏠',
    title: 'Male dein Zuhause!',
    titleEn: 'Paint your home!',
    titles: {
      'es': '¡Pinta tu casa!',
      'fr': 'Dessine ta maison !',
      'it': 'Disegna la tua casa!',
      'nl': 'Maak jouw huis!',
      'pl': 'Namaluj swój dom!',
      'pt': 'Pinta a tua casa!',
      'tr': 'Evini boya!',
    },
  ),
  DailyTask(
    id: 'glitter',
    emoji: '✨',
    title: 'Male etwas mit Glitzer!',
    titleEn: 'Paint something with glitter!',
    titles: {
      'es': '¡Pinta algo con purpurina!',
      'fr': 'Dessine quelque chose avec des paillettes !',
      'it': 'Disegna qualcosa con i brillantini!',
      'nl': 'Maak iets met glitter!',
      'pl': 'Namaluj coś brokatem!',
      'pt': 'Pinta algo com purpurinas!',
      'tr': 'Simli bir şey boya!',
    },
  ),
  DailyTask(
    id: 'blue',
    emoji: '💙',
    title: 'Male etwas Blaues!',
    titleEn: 'Paint something blue!',
    titles: {
      'es': '¡Pinta algo azul!',
      'fr': 'Dessine quelque chose de bleu !',
      'it': 'Disegna qualcosa di blu!',
      'nl': 'Maak iets blauws!',
      'pl': 'Namaluj coś niebieskiego!',
      'pt': 'Pinta algo azul!',
      'tr': 'Mavi bir şey boya!',
    },
  ),
  DailyTask(
    id: 'face',
    emoji: '😊',
    title: 'Male ein fröhliches Gesicht!',
    titleEn: 'Paint a happy face!',
    titles: {
      'es': '¡Pinta una cara feliz!',
      'fr': 'Dessine un visage joyeux !',
      'it': 'Disegna una faccia allegra!',
      'nl': 'Maak een blij gezicht!',
      'pl': 'Namaluj wesołą minę!',
      'pt': 'Pinta uma cara alegre!',
      'tr': 'Mutlu bir yüz boya!',
    },
  ),
  DailyTask(
    id: 'stars',
    emoji: '⭐',
    title: 'Stemple 10 Sterne!',
    titleEn: 'Stamp 10 stars!',
    titles: {
      'es': '¡Estampa 10 estrellas!',
      'fr': 'Tamponne 10 étoiles !',
      'it': 'Timbra 10 stelle!',
      'nl': 'Stempel 10 sterren!',
      'pl': 'Odbij 10 gwiazdek!',
      'pt': 'Estampa 10 estrelas!',
      'tr': '10 yıldız damgala!',
    },
  ),
  DailyTask(
    id: 'tree',
    emoji: '🌳',
    title: 'Male einen großen Baum!',
    titleEn: 'Paint a big tree!',
    titles: {
      'es': '¡Pinta un árbol grande!',
      'fr': 'Dessine un grand arbre !',
      'it': 'Disegna un albero grande!',
      'nl': 'Maak een grote boom!',
      'pl': 'Namaluj duże drzewo!',
      'pt': 'Pinta uma árvore grande!',
      'tr': 'Büyük bir ağaç boya!',
    },
  ),
  DailyTask(
    id: 'fill',
    emoji: '🪣',
    title: 'Fülle eine Fläche mit Punkten!',
    titleEn: 'Fill an area with dots!',
    titles: {
      'es': '¡Rellena un hueco con puntos!',
      'fr': 'Remplis une zone avec des pois !',
      'it': 'Riempi un\'area con i pallini!',
      'nl': 'Vul een vlak met stippen!',
      'pl': 'Wypełnij pole kropkami!',
      'pt': 'Enche uma área com pintas!',
      'tr': 'Bir alanı puantiyeyle doldur!',
    },
  ),
  DailyTask(
    id: 'car',
    emoji: '🚗',
    title: 'Male ein Fahrzeug!',
    titleEn: 'Paint a vehicle!',
    titles: {
      'es': '¡Pinta un vehículo!',
      'fr': 'Dessine un véhicule !',
      'it': 'Disegna un veicolo!',
      'nl': 'Maak een voertuig!',
      'pl': 'Namaluj pojazd!',
      'pt': 'Pinta um veículo!',
      'tr': 'Bir taşıt boya!',
    },
  ),
  DailyTask(
    id: 'yellow',
    emoji: '💛',
    title: 'Male etwas Gelbes!',
    titleEn: 'Paint something yellow!',
    titles: {
      'es': '¡Pinta algo amarillo!',
      'fr': 'Dessine quelque chose de jaune !',
      'it': 'Disegna qualcosa di giallo!',
      'nl': 'Maak iets geels!',
      'pl': 'Namaluj coś żółtego!',
      'pt': 'Pinta algo amarelo!',
      'tr': 'Sarı bir şey boya!',
    },
  ),
  DailyTask(
    id: 'letter',
    emoji: '✍️',
    title: 'Spure einen Buchstaben nach!',
    titleEn: 'Trace a letter!',
    titles: {
      'es': '¡Repasa una letra!',
      'fr': 'Repasse une lettre !',
      'it': 'Ripassa una lettera!',
      'nl': 'Trek een letter over!',
      'pl': 'Obrysuj literę!',
      'pt': 'Traça uma letra!',
      'tr': 'Bir harf üzerinden geç!',
    },
  ),
  DailyTask(
    id: 'flower',
    emoji: '🌸',
    title: 'Male eine Blume!',
    titleEn: 'Paint a flower!',
    titles: {
      'es': '¡Pinta una flor!',
      'fr': 'Dessine une fleur !',
      'it': 'Disegna un fiore!',
      'nl': 'Maak een bloem!',
      'pl': 'Namaluj kwiatek!',
      'pt': 'Pinta uma flor!',
      'tr': 'Bir çiçek boya!',
    },
  ),
  DailyTask(
    id: 'heart',
    emoji: '❤️',
    title: 'Male drei Herzen!',
    titleEn: 'Paint three hearts!',
    titles: {
      'es': '¡Pinta tres corazones!',
      'fr': 'Dessine trois cœurs !',
      'it': 'Disegna tre cuori!',
      'nl': 'Maak drie hartjes!',
      'pl': 'Namaluj trzy serca!',
      'pt': 'Pinta três corações!',
      'tr': 'Üç kalp boya!',
    },
  ),
  DailyTask(
    id: 'sea',
    emoji: '🌊',
    title: 'Male etwas unter Wasser!',
    titleEn: 'Paint something underwater!',
    titles: {
      'es': '¡Pinta algo bajo el agua!',
      'fr': 'Dessine quelque chose sous l\'eau !',
      'it': 'Disegna qualcosa sott\'acqua!',
      'nl': 'Maak iets onder water!',
      'pl': 'Namaluj coś pod wodą!',
      'pt': 'Pinta algo debaixo da água!',
      'tr': 'Su altında bir şey boya!',
    },
  ),
  DailyTask(
    id: 'neon',
    emoji: '⚡',
    title: 'Male mit dem Neon-Stift!',
    titleEn: 'Draw with the neon pen!',
    titles: {
      'es': '¡Dibuja con el lápiz de neón!',
      'fr': 'Dessine avec le crayon néon !',
      'it': 'Disegna con la matita neon!',
      'nl': 'Teken met de neonpen!',
      'pl': 'Rysuj neonową kredką!',
      'pt': 'Desenha com o lápis de néon!',
      'tr': 'Neon kalemle çiz!',
    },
  ),
  DailyTask(
    id: 'cat',
    emoji: '🐱',
    title: 'Male eine Katze!',
    titleEn: 'Paint a cat!',
    titles: {
      'es': '¡Pinta un gato!',
      'fr': 'Dessine un chat !',
      'it': 'Disegna un gatto!',
      'nl': 'Maak een kat!',
      'pl': 'Namaluj kota!',
      'pt': 'Pinta um gato!',
      'tr': 'Bir kedi boya!',
    },
  ),
  DailyTask(
    id: 'green',
    emoji: '💚',
    title: 'Male etwas Grünes!',
    titleEn: 'Paint something green!',
    titles: {
      'es': '¡Pinta algo verde!',
      'fr': 'Dessine quelque chose de vert !',
      'it': 'Disegna qualcosa di verde!',
      'nl': 'Maak iets groens!',
      'pl': 'Namaluj coś zielonego!',
      'pt': 'Pinta algo verde!',
      'tr': 'Yeşil bir şey boya!',
    },
  ),
  DailyTask(
    id: 'shapes',
    emoji: '⭕',
    title: 'Male drei verschiedene Formen!',
    titleEn: 'Draw three different shapes!',
    titles: {
      'es': '¡Dibuja tres formas distintas!',
      'fr': 'Dessine trois formes différentes !',
      'it': 'Disegna tre forme diverse!',
      'nl': 'Maak drie verschillende vormen!',
      'pl': 'Narysuj trzy różne kształty!',
      'pt': 'Desenha três formas diferentes!',
      'tr': 'Üç ayrı şekil çiz!',
    },
  ),
  DailyTask(
    id: 'space',
    emoji: '🚀',
    title: 'Male etwas im Weltraum!',
    titleEn: 'Paint something in space!',
    titles: {
      'es': '¡Pinta algo del espacio!',
      'fr': 'Dessine quelque chose dans l\'espace !',
      'it': 'Disegna qualcosa nello spazio!',
      'nl': 'Maak iets in de ruimte!',
      'pl': 'Namaluj coś w kosmosie!',
      'pt': 'Pinta algo no espaço!',
      'tr': 'Uzayda bir şey boya!',
    },
  ),
  DailyTask(
    id: 'number',
    emoji: '🔢',
    title: 'Spure eine Zahl nach!',
    titleEn: 'Trace a number!',
    titles: {
      'es': '¡Repasa un número!',
      'fr': 'Repasse un chiffre !',
      'it': 'Ripassa un numero!',
      'nl': 'Trek een cijfer over!',
      'pl': 'Obrysuj cyfrę!',
      'pt': 'Traça um número!',
      'tr': 'Bir sayı üzerinden geç!',
    },
  ),
  DailyTask(
    id: 'cake',
    emoji: '🎂',
    title: 'Male einen Geburtstagskuchen!',
    titleEn: 'Paint a birthday cake!',
    titles: {
      'es': '¡Pinta una tarta de cumpleaños!',
      'fr': 'Dessine un gâteau d\'anniversaire !',
      'it': 'Disegna una torta di compleanno!',
      'nl': 'Maak een verjaardagstaart!',
      'pl': 'Namaluj tort urodzinowy!',
      'pt': 'Pinta um bolo de aniversário!',
      'tr': 'Doğum günü pastası boya!',
    },
  ),
  DailyTask(
    id: 'family',
    emoji: '👨‍👩‍👧',
    title: 'Male deine Familie!',
    titleEn: 'Paint your family!',
    titles: {
      'es': '¡Pinta a tu familia!',
      'fr': 'Dessine ta famille !',
      'it': 'Disegna la tua famiglia!',
      'nl': 'Maak jouw familie!',
      'pl': 'Namaluj swoją rodzinę!',
      'pt': 'Pinta a tua família!',
      'tr': 'Ailene boya!',
    },
  ),
  DailyTask(
    id: 'dots',
    emoji: '🔵',
    title: 'Male mit dem Punkte-Stift!',
    titleEn: 'Draw with the dotty pen!',
    titles: {
      'es': '¡Dibuja con el lápiz de puntos!',
      'fr': 'Dessine avec le crayon à pois !',
      'it': 'Disegna con la matita a pallini!',
      'nl': 'Teken met de stippenpen!',
      'pl': 'Rysuj kredką w kropki!',
      'pt': 'Desenha com o lápis de pintas!',
      'tr': 'Puantiyeli kalemle çiz!',
    },
  ),
  DailyTask(
    id: 'weather',
    emoji: '⛅',
    title: 'Male das Wetter von heute!',
    titleEn: 'Paint today\'s weather!',
    titles: {
      'es': '¡Pinta el tiempo de hoy!',
      'fr': 'Dessine la météo d\'aujourd\'hui !',
      'it': 'Disegna il tempo di oggi!',
      'nl': 'Maak het weer van vandaag!',
      'pl': 'Namaluj dzisiejszą pogodę!',
      'pt': 'Pinta o tempo de hoje!',
      'tr': 'Bugünün havasını boya!',
    },
  ),
  DailyTask(
    id: 'dream',
    emoji: '💭',
    title: 'Male, wovon du geträumt hast!',
    titleEn: 'Paint what you dreamed about!',
    titles: {
      'es': '¡Pinta lo que has soñado!',
      'fr': 'Dessine ce dont tu as rêvé !',
      'it': 'Disegna ciò che hai sognato!',
      'nl': 'Maak waarover je gedroomd hebt!',
      'pl': 'Namaluj to, co ci się śniło!',
      'pt': 'Pinta o que sonhaste!',
      'tr': 'Rüyanda gördüğünü boya!',
    },
  ),
  DailyTask(
    id: 'monster',
    emoji: '👾',
    title: 'Male ein lustiges Monster!',
    titleEn: 'Paint a funny monster!',
    titles: {
      'es': '¡Pinta un monstruo divertido!',
      'fr': 'Dessine un monstre rigolo !',
      'it': 'Disegna un mostro buffo!',
      'nl': 'Maak een grappig monster!',
      'pl': 'Namaluj zabawnego potworka!',
      'pt': 'Pinta um monstro divertido!',
      'tr': 'Komik bir yaratık boya!',
    },
  ),
  // --- v7.6: appended, never inserted. The list is addressed
  // cyclically by date, so an insert would shift the prompt of
  // every following day.
  DailyTask(
    id: 'cow',
    emoji: '🐄',
    title: 'Male eine Kuh vom Bauernhof!',
    titleEn: 'Paint a cow from the farm!',
    titles: {
      'es': '¡Pinta una vaca de la granja!',
      'fr': 'Dessine une vache de la ferme !',
      'it': 'Disegna una mucca della fattoria!',
      'nl': 'Maak een koe van de boerderij!',
      'pl': 'Namaluj krowę z gospodarstwa!',
      'pt': 'Pinta uma vaca da fazenda!',
      'tr': 'Çiftlikten bir inek boya!',
    },
  ),
  DailyTask(
    id: 'purple',
    emoji: '💜',
    title: 'Male etwas Lila!',
    titleEn: 'Paint something purple!',
    titles: {
      'es': '¡Pinta algo morado!',
      'fr': 'Dessine quelque chose de violet !',
      'it': 'Disegna qualcosa di viola!',
      'nl': 'Maak iets paars!',
      'pl': 'Namaluj coś fioletowego!',
      'pt': 'Pinta algo lilás!',
      'tr': 'Mor bir şey boya!',
    },
  ),
  DailyTask(
    id: 'bynumbers',
    emoji: '🔢',
    title: 'Löse ein Zahlenbild!',
    titleEn: 'Finish a color-by-number picture!',
    titles: {
      'es': '¡Termina un dibujo de números!',
      'fr': 'Termine un coloriage par numéros !',
      'it': 'Completa un disegno con i numeri!',
      'nl': 'Maak een cijfertekening af!',
      'pl': 'Skończ obrazek z liczbami!',
      'pt': 'Termina um desenho por números!',
      'tr': 'Sayılarla bir resmi bitir!',
    },
  ),
  DailyTask(
    id: 'scene',
    emoji: '🏕️',
    title: 'Beklebe eine Sticker-Welt!',
    titleEn: 'Decorate a sticker world!',
    titles: {
      'es': '¡Decora un mundo de pegatinas!',
      'fr': 'Décore un monde d\'autocollants !',
      'it': 'Decora un mondo di adesivi!',
      'nl': 'Versier een stickerwereld!',
      'pl': 'Ozdób świat naklejek!',
      'pt': 'Decora um mundo de autocolantes!',
      'tr': 'Bir çıkartma dünyasını süsle!',
    },
  ),
  DailyTask(
    id: 'shape_heart',
    emoji: '💗',
    title: 'Zieh ein großes Herz auf!',
    titleEn: 'Drag out a big heart!',
    titles: {
      'es': '¡Estira un corazón grande!',
      'fr': 'Étire un grand cœur !',
      'it': 'Trascina un cuore grande!',
      'nl': 'Trek een groot hart!',
      'pl': 'Rozciągnij duże serce!',
      'pt': 'Estica um coração grande!',
      'tr': 'Kocaman bir kalp çek!',
    },
  ),
  DailyTask(
    id: 'penguin',
    emoji: '🐧',
    title: 'Male einen Pinguin!',
    titleEn: 'Paint a penguin!',
    titles: {
      'es': '¡Pinta un pingüino!',
      'fr': 'Dessine un pingouin !',
      'it': 'Disegna un pinguino!',
      'nl': 'Maak een pinguïn!',
      'pl': 'Namaluj pingwina!',
      'pt': 'Pinta um pinguim!',
      'tr': 'Bir penguen boya!',
    },
  ),
  DailyTask(
    id: 'orange',
    emoji: '🧡',
    title: 'Male etwas Orangenes!',
    titleEn: 'Paint something orange!',
    titles: {
      'es': '¡Pinta algo naranja!',
      'fr': 'Dessine quelque chose d\'orange !',
      'it': 'Disegna qualcosa di arancione!',
      'nl': 'Maak iets oranjes!',
      'pl': 'Namaluj coś pomarańczowego!',
      'pt': 'Pinta algo laranja!',
      'tr': 'Turuncu bir şey boya!',
    },
  ),
  DailyTask(
    id: 'eyedropper',
    emoji: '🎨',
    title: 'Nimm eine Farbe mit der Pipette auf!',
    titleEn: 'Pick up a color with the eyedropper!',
    titles: {
      'es': '¡Coge un color con el cuentagotas!',
      'fr': 'Prends une couleur avec la pipette !',
      'it': 'Prendi un colore con il contagocce!',
      'nl': 'Pak een kleur met de pipet!',
      'pl': 'Pobierz kolor zakraplaczem!',
      'pt': 'Apanha uma cor com o conta-gotas!',
      'tr': 'Damlalıkla bir renk al!',
    },
  ),
  DailyTask(
    id: 'hearts_pen',
    emoji: '💞',
    title: 'Male mit der Herzchen-Spur!',
    titleEn: 'Draw with the hearts trail!',
    titles: {
      'es': '¡Dibuja con el rastro de corazones!',
      'fr': 'Dessine avec la traînée de cœurs !',
      'it': 'Disegna con la scia di cuori!',
      'nl': 'Teken met het hartjesspoor!',
      'pl': 'Rysuj śladem serduszek!',
      'pt': 'Desenha com o rasto de corações!',
      'tr': 'Kalpli izle çiz!',
    },
  ),
  DailyTask(
    id: 'umbrella',
    emoji: '☂️',
    title: 'Male einen Regenschirm!',
    titleEn: 'Paint an umbrella!',
    titles: {
      'es': '¡Pinta un paraguas!',
      'fr': 'Dessine un parapluie !',
      'it': 'Disegna un ombrello!',
      'nl': 'Maak een paraplu!',
      'pl': 'Namaluj parasol!',
      'pt': 'Pinta um guarda-chuva!',
      'tr': 'Bir şemsiye boya!',
    },
  ),
  DailyTask(
    id: 'night',
    emoji: '🌙',
    title: 'Male den Nachthimmel!',
    titleEn: 'Paint the night sky!',
    titles: {
      'es': '¡Pinta el cielo de noche!',
      'fr': 'Dessine le ciel de nuit !',
      'it': 'Disegna il cielo di notte!',
      'nl': 'Maak de nachtlucht!',
      'pl': 'Namaluj nocne niebo!',
      'pt': 'Pinta o céu da noite!',
      'tr': 'Gece gökyüzünü boya!',
    },
  ),
  DailyTask(
    id: 'friend',
    emoji: '🧒',
    title: 'Male dein Lieblingstier!',
    titleEn: 'Paint your favourite animal!',
    titles: {
      'es': '¡Pinta tu animal favorito!',
      'fr': 'Dessine ton animal préféré !',
      'it': 'Disegna il tuo animale preferito!',
      'nl': 'Maak je lievelingsdier!',
      'pl': 'Namaluj swoje ulubione zwierzę!',
      'pt': 'Pinta o teu animal preferido!',
      'tr': 'En sevdiğin hayvanı boya!',
    },
  ),
  DailyTask(
    id: 'shape_star',
    emoji: '🌟',
    title: 'Zieh drei Sterne auf!',
    titleEn: 'Drag out three stars!',
    titles: {
      'es': '¡Estira tres estrellas!',
      'fr': 'Étire trois étoiles !',
      'it': 'Trascina tre stelle!',
      'nl': 'Trek drie sterren!',
      'pl': 'Rozciągnij trzy gwiazdy!',
      'pt': 'Estica três estrelas!',
      'tr': 'Üç yıldız çek!',
    },
  ),
  DailyTask(
    id: 'rainbowfill',
    emoji: '🪣',
    title: 'Fülle eine Fläche mit dem Regenbogen-Muster!',
    titleEn: 'Fill an area with the rainbow pattern!',
    titles: {
      'es': '¡Rellena un hueco con el patrón arcoíris!',
      'fr': 'Remplis une zone avec le motif arc-en-ciel !',
      'it': 'Riempi un\'area con il motivo arcobaleno!',
      'nl': 'Vul een vlak met het regenboogpatroon!',
      'pl': 'Wypełnij pole tęczowym wzorem!',
      'pt': 'Enche uma área com o padrão arco-íris!',
      'tr': 'Bir alanı gökkuşağı deseniyle doldur!',
    },
  ),
  DailyTask(
    id: 'erase',
    emoji: '🧽',
    title: 'Male etwas und wisch es wieder weg!',
    titleEn: 'Paint something and wipe it away again!',
    titles: {
      'es': '¡Pinta algo y bórralo otra vez!',
      'fr': 'Dessine quelque chose puis efface-le !',
      'it': 'Disegna qualcosa e cancellalo!',
      'nl': 'Maak iets en veeg het weer weg!',
      'pl': 'Namaluj coś i zetrzyj to!',
      'pt': 'Pinta algo e apaga outra vez!',
      'tr': 'Bir şey boya, sonra sil!',
    },
  ),
];

/// Day number since a fixed epoch — the basis for picking the day's task.
///
/// The local calendar date decides (the task flips at local midnight), but
/// the arithmetic runs in UTC: local days are 23 or 25 hours long around
/// daylight-saving switches, which would make `inDays` truncate two
/// different dates to the same number.
int dayNumber(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(2026, 1, 1))
        .inDays;

/// Deterministic task of the day. The stride (7) is coprime with the
/// catalog length (30), so consecutive days never repeat and the full
/// catalog cycles before anything comes back.
DailyTask taskForDate(DateTime date) {
  final n = dayNumber(date) * 7;
  return kDailyTasks[n % kDailyTasks.length];
}

/// Whether [today] is the calendar day right after [previous], with both
/// given as [dayKey] strings. Drives the daily-task streak.
///
/// Same UTC arithmetic as [dayNumber], and for the same reason: comparing
/// local dates around a daylight-saving switch would count a 23-hour day as
/// no day at all and silently break a child's streak. An empty or malformed
/// [previous] is simply "not yesterday" — the streak restarts at 1.
bool isDayAfter(String previous, String today) {
  final a = _parseDayKey(previous);
  final b = _parseDayKey(today);
  if (a == null || b == null) return false;
  return b.difference(a).inDays == 1;
}

DateTime? _parseDayKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime.utc(year, month, day);
}

/// `yyyy-MM-dd` key used to remember whether today's task is done.
String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
