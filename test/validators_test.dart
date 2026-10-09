import 'package:flutter_test/flutter_test.dart';
import 'package:songify_flutter/utils/validators.dart';

void main() {
  // =========================================================================
  // Issue #2: Validators
  // =========================================================================
  group('validateEmail', () {
    test('accepts a valid email', () {
      expect(validateEmail('user@example.com'), isNull);
    });

    test('accepts email with subdomains', () {
      expect(validateEmail('user@mail.example.co.uk'), isNull);
    });

    test('rejects empty string', () {
      expect(validateEmail(''), isNotNull);
    });

    test('rejects whitespace-only string', () {
      expect(validateEmail('   '), isNotNull);
    });

    test('rejects missing @ symbol', () {
      expect(validateEmail('userexample.com'), isNotNull);
    });

    test('rejects missing domain', () {
      expect(validateEmail('user@'), isNotNull);
    });

    test('rejects missing TLD', () {
      expect(validateEmail('user@example'), isNotNull);
    });

    test('trims whitespace before checking', () {
      // Leading/trailing whitespace should be stripped before validation.
      expect(validateEmail('  user@example.com  '), isNull);
    });
  });

  group('validatePassword', () {
    test('accepts a password of exactly 6 characters', () {
      expect(validatePassword('abc123'), isNull);
    });

    test('accepts a long password within limit', () {
      expect(validatePassword('a' * 72), isNull);
    });

    test('rejects empty string', () {
      expect(validatePassword(''), isNotNull);
    });

    test('rejects passwords shorter than 6 characters', () {
      expect(validatePassword('abc'), isNotNull);
      expect(validatePassword('12345'), isNotNull);
    });

    test('rejects passwords longer than 72 characters', () {
      expect(validatePassword('a' * 73), isNotNull);
    });
  });

  group('validateName', () {
    test('accepts a normal name', () {
      expect(validateName('Alice'), isNull);
    });

    test('accepts name with spaces', () {
      expect(validateName('Alice Wonder'), isNull);
    });

    test('rejects empty string', () {
      expect(validateName(''), isNotNull);
    });

    test('rejects whitespace-only string', () {
      expect(validateName('   '), isNotNull);
    });

    test('rejects name longer than 50 characters', () {
      expect(validateName('a' * 51), isNotNull);
    });

    test('accepts name of exactly 50 characters', () {
      expect(validateName('a' * 50), isNull);
    });
  });

  group('validateHandle', () {
    test('accepts a valid bare handle', () {
      expect(validateHandle('alice'), isNull);
    });

    test('accepts a handle with leading @', () {
      expect(validateHandle('@alice'), isNull);
    });

    test('accepts underscores and hyphens', () {
      expect(validateHandle('alice_wonder-land'), isNull);
    });

    test('rejects empty string', () {
      expect(validateHandle(''), isNotNull);
    });

    test('rejects whitespace-only string', () {
      expect(validateHandle('   '), isNotNull);
    });

    test('rejects handle shorter than 3 characters', () {
      expect(validateHandle('ab'), isNotNull);
      expect(validateHandle('@x'), isNotNull);
    });

    test('rejects handle longer than 30 characters', () {
      expect(validateHandle('a' * 31), isNotNull);
    });

    test('accepts handle of exactly 30 characters', () {
      expect(validateHandle('a' * 30), isNull);
    });

    test('rejects handle with spaces', () {
      expect(validateHandle('alice wonder'), isNotNull);
    });

    test('rejects handle with special characters', () {
      expect(validateHandle('alice!'), isNotNull);
      expect(validateHandle('alice@wonder'), isNotNull);
    });
  });

  group('normaliseHandle', () {
    test('prepends @ to a bare handle', () {
      expect(normaliseHandle('alice'), equals('@alice'));
    });

    test('does not double-prepend @ when already present', () {
      expect(normaliseHandle('@alice'), equals('@alice'));
    });

    test('strips whitespace', () {
      expect(normaliseHandle('  alice  '), equals('@alice'));
    });

    test('strips whitespace with @', () {
      expect(normaliseHandle('  @alice  '), equals('@alice'));
    });
  });
}
