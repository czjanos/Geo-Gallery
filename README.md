# Geo-Gallery

Nyomkövetés alapú fotó böngésző: A cél egy olyan mobil alkalmazás megvalósítása, amely lehetőséget ad GPS koordinátákkal ellátott fényképek készítésére, címkézésére (vagy kategóriákba sorolására), és azok tárolására. Az alkalmazásból lehet a tárolt képeket böngészni, keresni címke (vagy kategória), illetve térbeli pozíció (kezdőpont és sugár, vagy terület kijelölés) alapján.


## Funkcionális Tervek:

1. **Fő funkciók:**
   - Fényképek készítése GPS koordinátákkal.
   - Fényképek címkézése vagy kategóriákba sorolása.
   - Fényképek tárolása és kezelése.

2. **Keresési funkciók:**
   - Képek böngészése címkék vagy kategóriák alapján.
   - Képek keresése térbeli pozíció alapján (kezdőpont és sugár, vagy terület kijelölés).

3. **Felhasználói fiókok:**
   - Felhasználói regisztráció és bejelentkezés.
   - Fényképek felhasználóihoz kötése.

4. **Egyéb funkciók:**
   - Fényképek megosztása más felhasználókkal.
   - Fényképekhez kapcsolódó metaadatok szerkesztése.

## Statikus Tervek:

1. **Osztálydiagram:**
   - `PhotoManager`: A fényképek kezelését végző osztály.
   - `UserManager`: Felhasználók kezeléséért felelős osztály.
   - `SearchManager`: Keresési funkciókat megvalósító osztály.
   - `Photo`: A fényképek reprezentációjáért felelős osztály.

2. **Adatbázis Sémája:**
   - Táblák: `Users`, `Photos`.
   - Kapcsolat: A felhasználókhoz tartozó fényképek külső kulcsokkal vannak kapcsolva.

## Felülettervezés:

1. **Főképernyő:**
   - Gombok a fénykép készítéséhez és böngészéshez.
   - Keresési opciók és szűrők.

2. **Fénykép Részletek Oldal:**
   - Kép nagy méretű megjelenítése.
   - Címkék és metaadatok szerkesztése.

3. **Felhasználói Fiók Kezelési Oldal:**
   - Profil szerkesztése és felhasználói adatok megtekintése.

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

