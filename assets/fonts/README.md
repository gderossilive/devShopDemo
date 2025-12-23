# Fonts Directory

Questa cartella contiene i font personalizzati che verranno installati durante il setup dell'applicazione.

## Utilizzo

I file `.ttf` (TrueType Font) presenti in questa directory verranno automaticamente copiati in `C:\Windows\Fonts\` durante l'esecuzione di:

```powershell
.\deployment\Setup-WindowsVM.ps1
# oppure
.\scripts\installcomponents.ps1
```

## Aggiungere Fonts Personalizzati

1. Copia i file `.ttf` in questa directory
2. Esegui lo script di setup o installcomponents
3. I font saranno disponibili per l'applicazione

## Nota

Nel lab LAB501 originale, i font vengono installati tramite il file `installcomponents.zip` caricato su Azure Storage.

In questa versione on-premise, posiziona semplicemente i file font qui e verranno installati automaticamente durante il setup.

## Esempio

```
assets/fonts/
├── CustomFont-Regular.ttf
├── CustomFont-Bold.ttf
└── README.md
```
