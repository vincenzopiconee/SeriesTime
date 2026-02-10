import 'package:flutter_test/flutter_test.dart';
import 'package:seriestime/models/tv_show.dart';

void main() {
  group('TvShow Model Tests', () {
    test(
      'TvShow.fromJson deve mappare correttamente i dati e risolvere i generi',
      () {
        final Map<String, dynamic> json = {
          'id': 1396,
          'name': 'Breaking Bad',
          'poster_path': '/path.jpg',
          'first_air_date': '2008-01-20',
          'genre_ids': [18, 80], 
          'origin_country': ['US'],
          'vote_average': 9.5,
          'overview':
              'Un professore di chimica diventa un produttore di metanfetamine.',
        };

        final show = TvShow.fromJson(json);

        expect(show.name, 'Breaking Bad');
        expect(show.year, '2008');
        expect(show.genres, containsAll(['Drama', 'Crime']));
        expect(show.genreIds, containsAll([18, 80]));
        expect(show.country, 'US');
        expect(show.posterUrl, 'https://image.tmdb.org/t/p/w500/path.jpg');
      },
    );

    test('TvShow.fromJson deve gestire date corte o nulle', () {
      final Map<String, dynamic> json = {
        'id': 1,
        'name': 'Short Date Show',
        'first_air_date': '202',
      };

      final show = TvShow.fromJson(json);
      expect(show.year, "");
    });

    test('TvShow.fromJson deve gestire generi sconosciuti', () {
      final Map<String, dynamic> json = {
        'id': 2,
        'genre_ids': [99999],
      };

      final show = TvShow.fromJson(json);
      expect(show.genreIds, contains(99999));
      expect(
        show.genres,
        isEmpty,
      );
    });

    test('Genre class - Verifica costruttore', () {
      final genre = Genre(id: 35, name: 'Comedy');
      expect(genre.id, 35);
      expect(genre.name, 'Comedy');
    });
  });
}
