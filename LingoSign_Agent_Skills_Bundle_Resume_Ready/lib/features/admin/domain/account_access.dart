enum AccountRole {
  learner('Người học'),
  manager('Quản lý nội dung'),
  admin('Quản trị viên');

  const AccountRole(this.label);
  final String label;

  static AccountRole parse(Object? value) =>
      values.where((role) => role.name == value).firstOrNull ?? learner;
}

class AccountAccess {
  const AccountAccess({this.role = AccountRole.learner, this.locked = false});
  final AccountRole role;
  final bool locked;
  bool get isStaff => !locked && role != AccountRole.learner;
}
