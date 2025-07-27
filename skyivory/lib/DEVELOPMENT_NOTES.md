# SkyIvory Development Notes

## Current Status

L'app SkyIvory è stata configurata con la struttura base e le seguenti funzionalità sono state implementate:

### ✅ Completato
1. **Struttura progetto Flutter per iOS** - Creato con organizzazione modulare
2. **Dipendenze configurate** - bluesky, bluesky_text, flutter_riverpod, e altre
3. **Autenticazione con App Password** - Mock implementation (vedi note sotto)
4. **UI principale con Tab Bar** - Stile Ivory con 4 tab: Timeline, Mentions, Search, Profile
5. **State management con Riverpod** - Provider configurati per auth e theme
6. **Temi chiaro/scuro** - Implementati con switch automatico basato su sistema

### 🚧 In Progress / Mock
1. **Timeline principale** - Struttura implementata ma usa dati mock
2. **API Bluesky** - Attualmente usa implementazione mock per evitare errori di compilazione

### 📝 TODO
1. **Implementare visualizzazione profili utente**
2. **Implementare interazioni post** (like, repost, reply)
3. **Implementare autenticazione reale con Bluesky API**
4. **Aggiungere supporto per embed** (immagini, quote posts)
5. **Implementare Mentions e Search screens**

## Note Importanti

### Autenticazione Mock
L'autenticazione è stata temporaneamente implementata come mock perché il pacchetto Bluesky Dart sembra avere problemi con le API. Quando l'API sarà stabile:

1. Sostituire il mock in `auth_provider.dart` (linee 63-79)
2. Implementare correttamente `bsky.createSession()`
3. Aggiornare `blueskyClientProvider` per usare sessioni reali

### Struttura del Progetto
```
lib/
├── main.dart
├── models/
│   └── post_record.dart
├── providers/
│   ├── auth_provider.dart
│   ├── theme_provider.dart
│   └── timeline_provider.dart
├── screens/
│   ├── auth/
│   │   └── login_screen.dart
│   ├── main_screen.dart
│   ├── timeline_screen.dart
│   ├── mentions_screen.dart
│   ├── search_screen.dart
│   └── profile_screen.dart
├── widgets/
│   └── post_card.dart
└── utils/
    └── text_formatter.dart
```

## Come Procedere

1. **Per testare l'app**: `flutter run`
2. **Per implementare l'autenticazione reale**: Verificare la documentazione aggiornata di bluesky dart package
3. **Per aggiungere nuove features**: Seguire la struttura esistente con Riverpod providers