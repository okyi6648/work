class Validators {
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return '请输入手机号';
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) return '手机号格式不正确';
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.isEmpty) return '此项不能为空';
    return null;
  }

  static String? smsCode(String? value) {
    if (value == null || value.isEmpty) return '请输入验证码';
    if (value.length != 6) return '验证码为6位数字';
    return null;
  }
}
