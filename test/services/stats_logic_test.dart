import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seriestime/services/stats_logic.dart';
import 'package:seriestime/data/app_data.dart';
import 'package:seriestime/models/user.dart';
import 'package:seriestime/models/series.dart';

void main() {
  group('StatsLogic - Full Coverage Suite', () {
    late FakeFirebaseFirestore fakeDb;
    const String testUid = 'user_999';

    setUp(() async {
      fakeDb = FakeFirebaseFirestore();
      StatsLogic.db = fakeDb;

      await fakeDb.collection('users').doc(testUid).set({
        'name': 'Test User',
        'maxConsecutiveHours': 0.0,
        'weekendHours': 0.0,
        'nightOwlHours': 0.0,
      });
    });

    group('Firebase Calculations', () {
      test(
        'calculateNightOwl deve filtrare correttamente le ore notturne',
        () async {
          final seriesRef = fakeDb
              .collection('users')
              .doc(testUid)
              .collection('series')
              .doc('Test');
          await seriesRef.set({'exists': true});
          final seasonRef = seriesRef.collection('seasons').doc('Season 1');
          await seasonRef.set({'exists': true});

          await seasonRef.collection('episodes').add({
            'watched': true,
            'runtime': 60,
            'timestamp': Timestamp.fromDate(DateTime(2024, 1, 1, 2, 0)),
          });

          await StatsLogic.calculateNightOwl(userUid: testUid);
          final userDoc = await fakeDb.collection('users').doc(testUid).get();
          expect(userDoc.data()?['nightOwlHours'], 1.0);
        },
      );

      test(
        'calculateWeekendWarrior deve raggruppare i minuti del weekend',
        () async {
          final seriesRef = fakeDb
              .collection('users')
              .doc(testUid)
              .collection('series')
              .doc('Test');
          await seriesRef.set({'exists': true});
          final seasonRef = seriesRef.collection('seasons').doc('Season 1');
          await seasonRef.set({'exists': true});

          await seasonRef.collection('episodes').add({
            'watched': true,
            'runtime': 120,
            'timestamp': Timestamp.fromDate(DateTime(2024, 5, 11, 15, 0)),
          });

          await StatsLogic.calculateWeekendWarrior(userUid: testUid);
          final userDoc = await fakeDb.collection('users').doc(testUid).get();
          expect(userDoc.data()?['weekendHours'], 2.0);
        },
      );

      test(
        'calculatePureObsession deve gestire sessioni consecutive e pause lunghe',
        () async {
          final seriesRef = fakeDb
              .collection('users')
              .doc(testUid)
              .collection('series')
              .doc('Breaking Bad');
          await seriesRef.set({'exists': true});
          final seasonRef = seriesRef.collection('seasons').doc('Season 1');
          await seasonRef.set({'exists': true});

          final baseTime = DateTime(2024, 1, 1, 10, 0);

          await seasonRef.collection('episodes').add({
            'watched': true,
            'runtime': 50,
            'timestamp': Timestamp.fromDate(baseTime),
          });

          await seasonRef.collection('episodes').add({
            'watched': true,
            'runtime': 50,
            'timestamp': Timestamp.fromDate(
              baseTime.add(const Duration(minutes: 55)),
            ),
          });

          await seasonRef.collection('episodes').add({
            'watched': true,
            'runtime': 45,
            'timestamp': Timestamp.fromDate(
              baseTime.add(const Duration(hours: 4)),
            ),
          });

          await StatsLogic.calculatePureObsession(
            'Breaking Bad',
            userUid: testUid,
          );
          final userDoc = await fakeDb.collection('users').doc(testUid).get();
          expect(userDoc.data()?['maxConsecutiveHours'], closeTo(1.66, 0.01));
        },
      );
    });

    group('Chart Data Logic', () {
      test('getChartData deve coprire i rami SETTIMANA, MESE e ANNO', () async {
        final seriesRef = fakeDb
            .collection('users')
            .doc(testUid)
            .collection('series')
            .doc('ChartTest');
        await seriesRef.set({'exists': true});
        final seasonRef = seriesRef.collection('seasons').doc('Season 1');
        await seasonRef.set({'exists': true});

        final now = DateTime.now();

        await seasonRef.collection('episodes').add({
          'watched': true,
          'runtime': 120,
          'timestamp': Timestamp.fromDate(now),
        });

        final dataWeek = await StatsLogic.getChartData(
          ChartPeriod.week,
          userUid: testUid,
        );
        expect(dataWeek.length, 7);
        expect(dataWeek[6], 2.0);

        final dataMonth = await StatsLogic.getChartData(
          ChartPeriod.month,
          userUid: testUid,
        );
        expect(dataMonth.length, now.day);
        expect(dataMonth[now.day - 1], 2.0);

        final dataYear = await StatsLogic.getChartData(
          ChartPeriod.year,
          userUid: testUid,
        );
        expect(dataYear.length, 12);
        expect(dataYear[now.month - 1], 2.0);
      });

      test('getChartData deve gestire UID null', () async {
        final data = await StatsLogic.getChartData(
          ChartPeriod.week,
          userUid: null,
        );
        expect(data, isEmpty);
      });
    });

    group('Badge & Milestone Logic', () {
      test('generateUserBadges e getAllUnclaimedBadges coverage', () {
        final user = User(
          name: "Gianluca",
          totalHoursWatched: 50.0,
          maxConsecutiveHours: 5.0,
          weekendHours: 10.0,
          nightOwlHours: 2.0,
          uniqueGenresCount: 5,
          seriesStreak: 4,
          claimedBadgeIds: ["m1"],
        );

        final series = [
          Series(
            name: "Test",
            id: 1,
            imageUrl: "",
            percentage: 1.0,
            totalHours: 10.0,
            episode: "S1E1",
          ),
        ];

        expect(StatsLogic.generateUserBadges(null, []), isEmpty);
        expect(StatsLogic.generateUserBadges(user, series), isNotEmpty);

        final unclaimed = StatsLogic.getAllUnclaimedBadges(user, series);
        expect(unclaimed.any((b) => b.id == "m1"), isFalse);
      });

      test('Verifica di tutti i Target Milestone metodi', () {
        expect(StatsLogic.getMarathonerTarget(0.0).targetHours, isNotNull);
        expect(StatsLogic.getObsessionTarget(3.0).title, "Pure Obsession");
        expect(StatsLogic.getGenreTarget(5).title, "Genre Explorer");
        expect(StatsLogic.getNightOwlTarget(1000.0).title, "The Night Owl");
        expect(StatsLogic.getStreakTarget(1.0), isNotNull);
        expect(
          StatsLogic.getWeekendTarget(15.0).targetHours,
          greaterThan(15.0),
        );
        expect(
          StatsLogic.getCompletionistTarget(6.0).targetHours,
          greaterThan(6.0),
        );
      });
    });
  });
}
