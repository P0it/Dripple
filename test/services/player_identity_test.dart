import 'package:dripple/services/player_identity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('an id', () {
    test('is minted once and kept', () async {
      final identity = await PlayerIdentity.load();
      final first = await identity.uid();
      expect(first, isNotEmpty);
      expect(await identity.uid(), equals(first));

      // A fresh object on the same device is the same player.
      expect(await (await PlayerIdentity.load()).uid(), equals(first));
    });

    test('differs between devices', () async {
      final a = await (await PlayerIdentity.load()).uid();
      SharedPreferences.setMockInitialValues({});
      final b = await (await PlayerIdentity.load()).uid();
      expect(b, isNot(equals(a)));
    });
  });

  group('a name', () {
    test('is absent until somebody is asked for one', () async {
      final identity = await PlayerIdentity.load();
      expect(identity.hasName, isFalse);
      expect(identity.name, isNull);
    });

    test('is kept once given', () async {
      final identity = await PlayerIdentity.load();
      await identity.setName('Mina');
      expect((await PlayerIdentity.load()).name, equals('Mina'));
    });

    test('loses the whitespace that would read as an empty chair', () {
      expect(PlayerIdentity.sanitize('  Mina  '), equals('Mina'));
      expect(PlayerIdentity.sanitize('Mi   na'), equals('Mi na'));
      expect(PlayerIdentity.sanitize('a\nb'), equals('a b'));
      expect(PlayerIdentity.isValidName('   '), isFalse);
      expect(PlayerIdentity.isValidName('Mina'), isTrue);
    });

    test('is cut to what a seat label can hold', () {
      final long = PlayerIdentity.sanitize('Bartholomew Fitzgerald');
      expect(long.length, equals(PlayerIdentity.maxNameLength));
    });

    test('stored blank counts as never asked', () async {
      SharedPreferences.setMockInitialValues({'player_name': '   '});
      expect((await PlayerIdentity.load()).hasName, isFalse);
    });
  });
}
