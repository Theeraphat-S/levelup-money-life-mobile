// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'general_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class GeneralLocalizationsTh extends GeneralLocalizations {
  GeneralLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get ok => 'ตกลง';

  @override
  String get yes => 'ใช่';

  @override
  String get no => 'ไม่ใช่';

  @override
  String get add => 'เพิ่ม';

  @override
  String get close => 'ปิด';

  @override
  String get save => 'บันทึก';

  @override
  String get edit => 'แก้ไข';

  @override
  String get delete => 'ลบ';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get status => 'สถานะ';

  @override
  String get language => 'ภาษา';

  @override
  String get thai => 'ไทย';

  @override
  String get english => 'English';

  @override
  String get theme_light => 'โหมดสว่าง (Light)';

  @override
  String get theme_dark => 'โหมดมืด (Dark)';

  @override
  String get theme_system => 'ตามระบบ (System)';

  @override
  String get data_manager => 'จัดการข้อมูล';

  @override
  String get backup_data => 'สำรองข้อมูล (JSON)';

  @override
  String get restore_data => 'กู้คืนข้อมูล (JSON)';

  @override
  String get reset_data => 'รีเซ็ตข้อมูลทั้งหมด';

  @override
  String get reset_confirm => 'คุณแน่ใจหรือไม่ว่าต้องการรีเซ็ตข้อมูลทั้งหมดกลับเป็นค่าเริ่มต้น?';

  @override
  String get data_restored_success => 'กู้คืนข้อมูลสำเร็จเรียบร้อยแล้ว!';

  @override
  String get data_restore_failed => 'กู้คืนข้อมูลไม่สำเร็จ รูปแบบ JSON ไม่ถูกต้อง';

  @override
  String get copied_to_clipboard => 'คัดลอกลงคลิปบอร์ดแล้ว';

  @override
  String get backup_error_unsupported_version => 'ไฟล์สำรองนี้มาจากแอปเวอร์ชันที่ใหม่กว่า จึงกู้คืนไม่ได้';

  @override
  String backup_error_invalid_transactions(String detail) {
    return 'ข้อมูลรายการในไฟล์สำรองไม่ถูกต้อง ($detail) ข้อมูลเดิมไม่ถูกเปลี่ยนแปลง';
  }

  @override
  String backup_error_invalid_allocations(String detail) {
    return 'ข้อมูลสัดส่วนงบประมาณในไฟล์สำรองไม่ถูกต้อง ($detail) ข้อมูลเดิมไม่ถูกเปลี่ยนแปลง';
  }

  @override
  String backup_error_invalid_quests(String detail) {
    return 'ข้อมูลเควสในไฟล์สำรองไม่ถูกต้อง ($detail) ข้อมูลเดิมไม่ถูกเปลี่ยนแปลง';
  }

  @override
  String backup_error_invalid_gamification(String detail) {
    return 'ข้อมูล XP / สตรีคในไฟล์สำรองไม่ถูกต้อง ($detail) ข้อมูลเดิมไม่ถูกเปลี่ยนแปลง';
  }

  @override
  String backup_error_invalid_settings(String detail) {
    return 'ค่าการตั้งค่าในไฟล์สำรองไม่ถูกต้อง ($detail) ข้อมูลเดิมไม่ถูกเปลี่ยนแปลง';
  }

  @override
  String get backup_error_database => 'บันทึกข้อมูลสำรองลงฐานข้อมูลไม่สำเร็จ ข้อมูลเดิมไม่ถูกเปลี่ยนแปลง';

  @override
  String get msg_load_failed => 'โหลดข้อมูลไม่สำเร็จ ลองใหม่อีกครั้ง';

  @override
  String get msg_save_failed => 'ไม่สามารถบันทึกรายการได้';

  @override
  String get msg_update_failed => 'ไม่สามารถแก้ไขรายการได้';

  @override
  String get msg_delete_failed => 'ไม่สามารถลบรายการได้';

  @override
  String get msg_generic_error => 'เกิดข้อผิดพลาด ลองใหม่อีกครั้ง';

  @override
  String get msg_budget_save_failed => 'บันทึกสัดส่วนงบประมาณไม่สำเร็จ';

  @override
  String get msg_income_save_failed => 'บันทึกรายได้ต่อเดือนไม่สำเร็จ';

  @override
  String get msg_checkin_failed => 'เช็คอินไม่สำเร็จ';

  @override
  String get msg_reward_claim_failed => 'รับรางวัลไม่สำเร็จ';

  @override
  String msg_checkin_success(int xp) {
    return 'เช็คอินสำเร็จ! +$xp XP';
  }

  @override
  String msg_quest_completed(int xp) {
    return 'ทำเควสสำเร็จ! +$xp XP';
  }

  @override
  String get msg_quest_reverted => 'ยกเลิกสถานะเควสเรียบร้อย';

  @override
  String msg_quest_reward_claimed(int xp) {
    return 'ปลดล็อกสำเร็จ! ได้รับ +$xp XP';
  }

  @override
  String get settings_title => 'การตั้งค่า & โปรไฟล์';

  @override
  String xp_and_streak(int xp, int days) {
    return '$xp XP · $days วันต่อเนื่อง';
  }

  @override
  String get general_preferences => 'การตั้งค่าทั่วไป';

  @override
  String get appearance => 'ธีมการแสดงผล';

  @override
  String get backup_and_data => 'สำรอง & กู้คืนข้อมูล';

  @override
  String get backup_and_data_subtitle => 'ส่งออก / นำเข้าไฟล์ JSON';

  @override
  String get manage => 'จัดการ';

  @override
  String get saved_success => 'บันทึกสำเร็จ!';

  @override
  String get tab_export => 'สำรอง (Export)';

  @override
  String get tab_import => 'กู้คืน (Import)';

  @override
  String get tab_reset => 'รีเซ็ต (Reset)';

  @override
  String get export_hint => 'สำรองข้อมูล JSON (แชร์ใช้งานกับเว็บได้):';

  @override
  String get copy_json_backup => 'คัดลอก JSON Backup';

  @override
  String get import_hint => 'วางข้อมูล JSON ที่ Export มาจาก Web หรือ Mobile:';

  @override
  String get import_and_restore => 'นำเข้าและกู้คืนข้อมูล';

  @override
  String get reset_description => 'ข้อมูลธุรกรรม สถิติ และเควสจะถูกคืนค่ากลับเป็นชุดตัวอย่างเริ่มต้น';

  @override
  String get reset_confirm_button => 'ยืนยันการล้างข้อมูล (Reset All)';
}
