import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://ubwwgncpgrkmqsjevteq.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVid3dnbmNwZ3JrbXFzamV2dGVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4MzkyODIsImV4cCI6MjA5ODQxNTI4Mn0.2u9JM1Qai6SWNQOM9ziqbHDuIRkxpFpYSrx0iA2SwVQ',
  );

  try {
    final tracks = await supabase.from('saved_tracks').select().limit(1);
    print('saved_tracks columns: ${tracks.isNotEmpty ? tracks.first.keys : "empty"}');
  } catch(e) { print(e); }

  try {
    final albums = await supabase.from('albums').select().limit(1);
    print('albums columns: ${albums.isNotEmpty ? albums.first.keys : "empty"}');
  } catch(e) { print(e); }

  try {
    final albumTracks = await supabase.from('album_tracks').select().limit(1);
    print('album_tracks columns: ${albumTracks.isNotEmpty ? albumTracks.first.keys : "empty"}');
  } catch(e) { print(e); }
}
