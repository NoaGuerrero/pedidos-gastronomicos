import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';

class SupabaseService {
  static SupabaseClient? _client;

  // Singleton pattern
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase no ha sido inicializado. Llama a initialize() primero.');
    }
    return _client!;
  }

  // Inicializar Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      anonKey: SupabaseConstants.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  // Helpers rápidos
  static SupabaseClient get supabase => client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;
  static RealtimeClient get realtime => client.realtime;
}