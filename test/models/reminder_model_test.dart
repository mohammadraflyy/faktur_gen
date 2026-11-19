import 'package:flutter_test/flutter_test.dart';
import 'package:faktur_gen/models/reminder_model.dart';

void main() {
  group('RepeatInterval', () {
    test('labels are Indonesian', () {
      expect(RepeatInterval.none.label, 'Tidak Berulang');
      expect(RepeatInterval.monthly.label, 'Setiap 1 Bulan');
      expect(RepeatInterval.bimonthly.label, 'Setiap 2 Bulan');
      expect(RepeatInterval.quarterly.label, 'Setiap 3 Bulan');
      expect(RepeatInterval.semiannual.label, 'Setiap 6 Bulan');
      expect(RepeatInterval.annual.label, 'Setiap 1 Tahun');
    });

    test('months values', () {
      expect(RepeatInterval.none.months, 0);
      expect(RepeatInterval.monthly.months, 1);
      expect(RepeatInterval.bimonthly.months, 2);
      expect(RepeatInterval.quarterly.months, 3);
      expect(RepeatInterval.semiannual.months, 6);
      expect(RepeatInterval.annual.months, 12);
    });
  });

  group('ReminderItem', () {
    test('serialization roundtrip', () {
      final item = ReminderItem(
        nama: 'Service X',
        kuantitas: 2,
        satuan: 'jam',
        hargaSatuan: 100000,
      );
      final map = item.toMap();
      final item2 = ReminderItem.fromMap(map);
      expect(item2.nama, 'Service X');
      expect(item2.kuantitas, 2);
      expect(item2.satuan, 'jam');
      expect(item2.hargaSatuan, 100000);
    });
  });

  group('ReminderModel', () {
    ReminderModel _make({
      DateTime? date,
      ReminderStatus status = ReminderStatus.pending,
      RepeatInterval repeat = RepeatInterval.none,
    }) {
      return ReminderModel(
        id: 'test-1',
        contactName: 'Budi',
        serviceName: 'Service AC',
        reminderDate: date ?? DateTime.now(),
        status: status,
        repeatInterval: repeat,
      );
    }

    test('default values', () {
      final r = _make();
      expect(r.contactName, 'Budi');
      expect(r.serviceName, 'Service AC');
      expect(r.reminderHour, 8);
      expect(r.reminderMinute, 0);
      expect(r.status, ReminderStatus.pending);
      expect(r.repeatInterval, RepeatInterval.none);
      expect(r.isRepeating, isFalse);
      expect(r.hasLastItems, isFalse);
    });

    test('isDue for today', () {
      final r = _make(date: DateTime.now());
      expect(r.isDue, isTrue);
      expect(r.isOverdue, isFalse);
    });

    test('isOverdue for past date', () {
      final r = _make(
          date: DateTime.now().subtract(const Duration(days: 5)));
      expect(r.isDue, isFalse);
      expect(r.isOverdue, isTrue);
    });

    test('not due/overdue when status is done', () {
      final r = _make(
        date: DateTime.now().subtract(const Duration(days: 1)),
        status: ReminderStatus.done,
      );
      expect(r.isDue, isFalse);
      expect(r.isOverdue, isFalse);
    });

    test('not due for future date', () {
      final r = _make(
          date: DateTime.now().add(const Duration(days: 10)));
      expect(r.isDue, isFalse);
      expect(r.isOverdue, isFalse);
    });

    test('isRepeating', () {
      final r = _make(repeat: RepeatInterval.monthly);
      expect(r.isRepeating, isTrue);
    });

    test('advanceToNext for monthly', () {
      final r = _make(
        date: DateTime(2026, 3, 15),
        repeat: RepeatInterval.monthly,
      );
      r.status = ReminderStatus.done;
      r.advanceToNext();
      expect(r.reminderDate.month, 4);
      expect(r.reminderDate.day, 15);
      expect(r.status, ReminderStatus.pending);
    });

    test('advanceToNext for quarterly', () {
      final r = _make(
        date: DateTime(2026, 1, 10),
        repeat: RepeatInterval.quarterly,
      );
      r.advanceToNext();
      expect(r.reminderDate.month, 4);
      expect(r.reminderDate.day, 10);
    });

    test('advanceToNext for annual', () {
      final r = _make(
        date: DateTime(2026, 6, 1),
        repeat: RepeatInterval.annual,
      );
      r.advanceToNext();
      // month 6 + 12 = 18 -> Dart DateTime normalizes to next year June
      expect(r.reminderDate.year, 2027);
      expect(r.reminderDate.month, 6);
    });

    test('advanceToNext does nothing for non-repeating', () {
      final r = _make(
        date: DateTime(2026, 3, 15),
        repeat: RepeatInterval.none,
      );
      r.advanceToNext();
      expect(r.reminderDate.month, 3);
      expect(r.reminderDate.day, 15);
    });

    test('notificationId is deterministic', () {
      final r1 = _make();
      final r2 = _make();
      expect(r1.notificationId, r2.notificationId);
      expect(r1.notificationId, greaterThan(0));
    });

    test('serialization roundtrip', () {
      final r = ReminderModel(
        id: 'r-1',
        contactName: 'Siti',
        contactPhone: '08123456',
        contactAddress: 'Jl. Merdeka',
        serviceName: 'Cuci AC',
        notes: 'Unit kamar utama',
        reminderDate: DateTime(2026, 5, 1),
        reminderHour: 9,
        reminderMinute: 30,
        status: ReminderStatus.pending,
        repeatInterval: RepeatInterval.bimonthly,
        docType: ReminderDocType.invoice,
        lastItems: [
          ReminderItem(nama: 'Cuci AC', kuantitas: 1, hargaSatuan: 150000),
        ],
      );

      final map = r.toMap();
      final r2 = ReminderModel.fromMap(map);

      expect(r2.id, 'r-1');
      expect(r2.contactName, 'Siti');
      expect(r2.contactPhone, '08123456');
      expect(r2.serviceName, 'Cuci AC');
      expect(r2.notes, 'Unit kamar utama');
      expect(r2.reminderHour, 9);
      expect(r2.reminderMinute, 30);
      expect(r2.repeatInterval, RepeatInterval.bimonthly);
      expect(r2.docType, ReminderDocType.invoice);
      expect(r2.lastItems.length, 1);
      expect(r2.lastItems[0].nama, 'Cuci AC');
      expect(r2.lastItems[0].hargaSatuan, 150000);
    });

    test('fromMap with null docType', () {
      final map = ReminderModel(
        id: 'x',
        contactName: 'A',
        serviceName: 'B',
        reminderDate: DateTime.now(),
      ).toMap();
      map['docType'] = null;
      final r = ReminderModel.fromMap(map);
      expect(r.docType, isNull);
    });
  });

  group('defaultReminderDate', () {
    final now = DateTime(2026, 11, 19, 10, 30);

    test('due date in the future, at 09:00', () {
      expect(defaultReminderDate(DateTime(2026, 12, 3), now),
          DateTime(2026, 12, 3, 9));
    });

    test('no due date: 30 days from now, at 09:00', () {
      expect(defaultReminderDate(null, now), DateTime(2026, 12, 19, 9));
    });

    test('due date already passed: 30 days from now', () {
      expect(defaultReminderDate(DateTime(2026, 11, 1), now),
          DateTime(2026, 12, 19, 9));
    });

    test('due today after 09:00 has passed: 30 days from now', () {
      expect(defaultReminderDate(DateTime(2026, 11, 19), now),
          DateTime(2026, 12, 19, 9));
    });
  });
}
