# CLI lyrics for ncmpcpp/mpd

Vreau sa creez o aplicatie CLI care ruleaza in terminal si, atunci cand in mpd/ncmpcpp se reda o melodie, afiseaza versurile (lyrics) pentru melodia curenta.

## Scop
- Afisarea automata a versurilor in terminal pentru melodia redata in ncmpcpp/mpd.
- Integrare simpla cu mpd, fara interfata grafica.

## Idei initiale
- Citire metadate (artist, titlu) din mpd.
- Cautare versuri folosind o sursa online sau locala.
- Afisare live in terminal, cu refresh cand se schimba melodia.

## Exemplu de flux in terminal
1. Pornesc aplicatia: `lyrics-cli`
2. Aplicatia detecteaza melodia curenta din mpd.
3. Se afiseaza versurile in terminal.
4. Cand se schimba melodia, ecranul se actualizeaza automat.

## Instalare
1. Ai nevoie de Python 3.10+ si MPD pornit.
2. Creaza si activeaza un virtualenv local:
   `python3 -m venv .venv`
   `source .venv/bin/activate`
3. Instaleaza dependintele:
   `python -m pip install -r requirements.txt`

## Rulare
`python lyrics_cli.py`

## Optiuni utile
- `--host` si `--port` pentru conexiune MPD.
- `--interval` pentru cat de des se face refresh.
- `--timeout` pentru timeout la request-uri.
- `--source` pentru a forta `genius`, `lrclib` sau `auto`.
- `--no-filter-cjk` daca vrei sa pastrezi liniile cu caractere CJK.

## Note
- Scriptul afiseaza versurile rapid si simplu, fara UI full-screen, ca sa poti folosi scroll-ul normal din terminal.
- Surse folosite: Genius (cu token) si LRCLIB (fallback).

## Genius API (recomandat pentru melodii romanesti)
1. Creeaza un token pe https://genius.com/api-clients.
2. Creeaza un fisier `.env` in radacina proiectului (nu in `.venv`) cu continutul:
   `GENIUS_ACCESS_TOKEN="tokenul-tau"`
3. Ruleaza:
   `python lyrics_cli.py --source genius`

Nota: daca `lyricsgenius` nu functioneaza pe versiunea ta de Python, aplicatia face fallback pe request-uri directe catre Genius.
