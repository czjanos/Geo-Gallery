# Geo-Gallery

Nyomkövetés alapú fotó böngésző: A cél egy olyan mobil alkalmazás megvalósítása, amely lehetőséget ad GPS koordinátákkal ellátott fényképek készítésére, címkézésére (vagy kategóriákba sorolására), és azok tárolására. Az alkalmazásból lehet a tárolt képeket böngészni, keresni címke (vagy kategória), illetve térbeli pozíció (kezdőpont és sugár, vagy terület kijelölés) alapján.


## Funkcionális Tervek:

1. **Fényképek készítése GPS koordinátákkal**
   - Felhasználók képeket készítenek a mobiltelefonjuk segítségével.
   - Az így elkészült képeket, a telefon lokációja alapján, címkével látjuk el.
     
2. **Fényképek tárolása**
   - Az alkalmazás az eszközön tárolja a felhasználók által készített képeket, valamint a hozzájuk rendelt címkéket.
     
3. **Fényképek böngészése**
   - A felhasználók a tárolt képeket megtekinthetik és böngészhetik az alkalmazásban.
   - Kétféle megjelenítés: térkép és lista nézet.
   - A képeket lehet kategória szerint rendezni: készítés dátuma, lokáció alapján.
   - A képek a térkép felületén jelennek meg, nagyítási szintnek megfelelően, a közel egy pontban eső képeket csoportosítjuk.
   - A csoportosított képek nagyítás hatására egyedülálló vagy kisebb csoportokra bomlanak.
   - Egy kép megtekintésekor, teljes képernyőben látjuk a képet. A csoporton belül lapozhatóak a képek.

4. **Keresési funkciók:**
   - Képek böngészése szűrők nélkül. Rendezési szempontok szerint.
   - Képek böngészése szűrő beállításokkal. (Lokáció és/vagy dátum).
   - Képek keresése térbeli pozíció alapján (középpont és sugár, vagy terület kijelölés).
   - Képek keresése két megadott időpont között.


## Statikus Tervek:
![geogallery_UML](https://github.com/czjanos/Geo-Gallery/assets/116583568/dba90adc-ffef-4c5a-8d0e-460ab824f691)


## Felülettervezés:

1. **Főképernyő:**
   - Gombok a fénykép készítéséhez, terület vaggy pozició kijelőlésére és böngészési képernyőre navigálásra.
   - Térkép felület és a képek lokalizáció alapján ikonokon keresztül megjelenítve.

![figma-0](https://github.com/czjanos/Geo-Gallery/assets/116583568/15ce5534-7c5e-481d-a3d6-f136d7664cf5)
![figma-1](https://github.com/czjanos/Geo-Gallery/assets/116583568/637ab989-8369-490b-bc38-7bc671792956)

2. **Fénykép Részletek Oldal:**
   - Kép nagy méretű megjelenítése.
   - Miniatür megjelenitése a további csoportban lévő képeknek.

![figma-4](https://github.com/czjanos/Geo-Gallery/assets/116583568/4f7ea881-b3f8-4d91-bfc3-694ba4947a74)

3. **Böngészési képernyő:**
   - Galléria típusú, képek csempenézetben megjelenítve.
   - Kategórizálva dátum szerint.
   - Keresési és szűrési lehetőségek a metaadatokra.

![figma-2](https://github.com/czjanos/Geo-Gallery/assets/116583568/d410312c-6329-4942-8f56-dc394cd13b27)
![figma-3](https://github.com/czjanos/Geo-Gallery/assets/116583568/17cccf0e-cd4a-41a8-baee-7be3a6b9d71f)

4. **Alapvető beállítások:**
   - Engedélyek kezelése (kamera, helymeghatározás stb.)
  
https://www.figma.com/proto/EQPWj0O6j29hDY9y1228ES/Geo-Gallery?type=design&node-id=1-2&t=DzA4P5iRrXIjIn0Y-1&scaling=scale-down&page-id=0%3A1&mode=design

# Implementációs Tervek:
## Projekt Indítása:
  ### Github kezelés:
   - Fejlesztéshez Github-ot használunk.Minden commit tartalmazzon egy hibaszámot. A commit üzenet példája: #{hibaszám} {commit_üzenet}. Példák a Git előzményekben. A commit üzenet legyen rövid és leíró szöveg a javított hibáról vagy implementált funkcióról.
   - Parancsok:
      ```bash
      git pull
      git commit
      ```
   ### Flutter Telepítése:
   - A mobilalkalmazás fejlesztéséhez Flutter frameworket és Dart nyelvet használunk.
   
   - Látogass el a Flutter hivatalos weboldalára: [Flutter - Get Started](https://flutter.dev/docs/get-started/install).

   - Válaszd ki a saját operációs rendszeredet (Windows, macOS, vagy Linux).
   - Töltsd le a Flutter SDK-t.
   - Csomagold ki az letöltött zip fájlt egy megfelelő helyre.
   - A `.bashrc` vagy `.zshrc` fájlban add hozzá a Flutter `bin` könyvtár elérését a PATH környezeti változóhoz.

      ```bash
      export PATH="$PATH:`útvonal_az_unzipped_flutter_bin_mappához`"
      ```
   ## Fejlesztői környezet telepítése:
   - A VSCode vagy Android Studio fejlesztői környezetet alkalmazzuk a kódszerkesztéshez és teszteléshez.
   - A hatékony fejlesztéshez VSCode vagy Android Studio alkalmazás a Flutter & Dart pluginnel.
   - Látogass el a [VSCode letöltési oldalára](https://code.visualstudio.com/), és töltsd le a telepítőt.

   ## Állapotkezelés:
   - Az alkalmazás állapotának hatékony kezeléséhez válasszunk Provider-t vagy Riverpod-ot.

   ## Adatbázis:
   - Döntésünk alapján helyi vagy felhőalapú adatkezelést alkalmazunk.
   - A helyi adatok tárolásához sqflite adatbázist használunk.
   - Felhőalapú megoldásként fontoljuk meg a Firebase Firestore használatát.

   ## UI Építőkockák:
   - Az alkalmazás felhasználói felületének hatékony kialakításához alkalmazzuk a Flutter beépített widgeteit, például ListTile, GridView, stb.


   ## Tesztelés:
   - Implementáljunk unit teszteket a Dart nyelv segítségével az alkalmazás funkcióinak tesztelésére.
   - A felhasználói felület helyes működésének ellenőrzésére alkalmazzunk widget teszteket.
   - Parancsok:
     ```bash
     flutter test
     ```

   ## Befejezés és Közzététel:
   - Alaposan teszteljük az alkalmazást a VSCode vagy Android Studio környezetében.
   - Készítsük el az APK vagy IPA fájlt az alkalmazás publikálásához.
   - Közzétegyük az alkalmazást a Google Play-en és az App Store-ban, és tartsuk karban az esetleges frissítéseket.
   - Parancsok:
     ```bash
     flutter build apk
     flutter build ios
     flutter pub publish
     ```

