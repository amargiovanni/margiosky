import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluesky/bluesky.dart' as bsky;
import 'package:bluesky/atproto.dart' as atproto;
import 'package:atproto_core/atproto_core.dart' show Session;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xrpc/xrpc.dart';
import 'dart:convert';

class AuthSession {
  final String did;
  final String handle;
  final String accessJwt;
  final String refreshJwt;
  final String? email;
  final bool emailConfirmed;
  final bool emailAuthFactor;
  final Map<String, dynamic>? didDoc;
  final bool active;
  final String? status;
  
  AuthSession({
    required this.did,
    required this.handle,
    required this.accessJwt,
    required this.refreshJwt,
    this.email,
    this.emailConfirmed = false,
    this.emailAuthFactor = false,
    this.didDoc,
    this.active = true,
    this.status,
  });
  
  Map<String, dynamic> toJson() => {
    'did': did,
    'handle': handle,
    'accessJwt': accessJwt,
    'refreshJwt': refreshJwt,
    if (email != null) 'email': email,
    'emailConfirmed': emailConfirmed,
    'emailAuthFactor': emailAuthFactor,
    if (didDoc != null) 'didDoc': didDoc,
    'active': active,
    if (status != null) 'status': status,
  };
  
  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    did: json['did'],
    handle: json['handle'],
    accessJwt: json['accessJwt'],
    refreshJwt: json['refreshJwt'],
    email: json['email'],
    emailConfirmed: json['emailConfirmed'] ?? false,
    emailAuthFactor: json['emailAuthFactor'] ?? false,
    didDoc: json['didDoc'],
    active: json['active'] ?? true,
    status: json['status'],
  );
}

final authServiceProvider = Provider<AuthService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthService(prefs);
});

final sessionProvider = StateNotifierProvider<SessionNotifier, AuthSession?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return SessionNotifier(authService);
});

final blueskyClientProvider = Provider<bsky.Bluesky?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  
  // Create authenticated client with real session data
  final bskySession = Session(
    did: session.did,
    handle: session.handle,
    accessJwt: session.accessJwt,
    refreshJwt: session.refreshJwt,
    email: session.email,
    emailConfirmed: session.emailConfirmed,
    emailAuthFactor: session.emailAuthFactor,
    didDoc: session.didDoc,
    active: session.active,
    status: session.status,
  );
  
  return bsky.Bluesky.fromSession(
    bskySession,
    service: 'bsky.social',
  );
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class AuthService {
  final SharedPreferences prefs;
  static const _sessionKey = 'bluesky_session';
  
  AuthService(this.prefs);
  
  Future<AuthSession?> login(String identifier, String appPassword) async {
    try {
      // Create real Bluesky session
      final response = await atproto.createSession(
        service: 'bsky.social',
        identifier: identifier,  // User's handle (e.g., "user.bsky.social") or email
        password: appPassword,   // App password generated from Bluesky settings
      );
      
      // Extract session data
      final session = response.data;
      final authSession = AuthSession(
        did: session.did,
        handle: session.handle,
        accessJwt: session.accessJwt,
        refreshJwt: session.refreshJwt,
        email: session.email,
        emailConfirmed: session.emailConfirmed,
        emailAuthFactor: session.emailAuthFactor,
        didDoc: session.didDoc,
        active: session.active,
        status: session.status,
      );
      
      await saveSession(authSession);
      return authSession;
    } on UnauthorizedException catch (e) {
      throw Exception('Invalid credentials: ${e.toString()}');
    } on XRPCException catch (e) {
      throw Exception('Network error: ${e.toString()}');
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  
  Future<AuthSession?> refreshSession(AuthSession currentSession) async {
    try {
      final response = await atproto.refreshSession(
        service: 'bsky.social',
        refreshJwt: currentSession.refreshJwt,
      );
      
      final session = response.data;
      final newSession = AuthSession(
        did: session.did,
        handle: session.handle,
        accessJwt: session.accessJwt,
        refreshJwt: session.refreshJwt,
        email: session.email,
        emailConfirmed: session.emailConfirmed,
        emailAuthFactor: session.emailAuthFactor,
        didDoc: session.didDoc,
        active: session.active,
        status: session.status,
      );
      
      await saveSession(newSession);
      return newSession;
    } catch (e) {
      // If refresh fails, user needs to re-authenticate
      await logout();
      throw Exception('Session refresh failed: $e');
    }
  }
  
  Future<void> saveSession(AuthSession session) async {
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }
  
  AuthSession? loadSession() {
    final sessionString = prefs.getString(_sessionKey);
    if (sessionString == null) return null;
    
    try {
      final json = jsonDecode(sessionString);
      return AuthSession.fromJson(json);
    } catch (e) {
      return null;
    }
  }
  
  Future<void> logout() async {
    await prefs.remove(_sessionKey);
  }
}

class SessionNotifier extends StateNotifier<AuthSession?> {
  final AuthService authService;
  
  SessionNotifier(this.authService) : super(null) {
    _loadSession();
  }
  
  void _loadSession() {
    try {
      state = authService.loadSession();
    } catch (e) {
      // If loading fails, user is not authenticated
      state = null;
    }
  }
  
  Future<void> login(String identifier, String appPassword) async {
    final session = await authService.login(identifier, appPassword);
    state = session;
  }
  
  Future<void> logout() async {
    await authService.logout();
    state = null;
  }
  
  Future<void> refreshSession() async {
    if (state == null) return;
    
    try {
      final newSession = await authService.refreshSession(state!);
      state = newSession;
    } catch (e) {
      // If refresh fails, user is logged out
      state = null;
    }
  }
}