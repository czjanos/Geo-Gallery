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

## Implementációs Tervek:

1. **Programozási Nyelv:**
   - Dart (Flutter nyelv).

2. **Fejlesztői Környezet:**
   - Flutter & Dart plugin a Visual Studio Code-ban vagy Android Studioban.

3. **Állapotkezelés:**
   - Provider vagy Riverpod a könnyű állapotkezeléshez.

4. **Adatbázis:**
   - sqflite a helyi adatok kezeléséhez, vagy Firebase Firestore használata a felhőalapú adattároláshoz.

5. **UI Építőkockák:**
   - Flutter widgetek, például ListTile, GridView, stb.

6. **Hálózati Kommunikáció:**
   - Dio vagy http csomagok a szükség esetén szerverrel történő kommunikációhoz.

7. **Tesztelés:**
   - Unit és widget tesztek a Dart-ban.
