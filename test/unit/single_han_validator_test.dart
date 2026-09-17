import 'package:flutter_test/flutter_test.dart';
import 'package:wuwei_dictionary/features/dictionary/single_han_validator.dart';

void main() {
  const validator = SingleHanValidator();

  test('接受基本区、扩展区汉字及首尾空格', () {
    expect(validator.validate('澄'), isA<ValidHan>());
    expect(validator.validate('𠮷'), isA<ValidHan>());
    final result = validator.validate(' 龘 ') as ValidHan;
    expect(result.value, '龘');
  });

  test('拒绝空、多字及非汉字输入', () {
    expect((validator.validate('') as InvalidHan).error, HanInputError.empty);
    expect((validator.validate('苹果') as InvalidHan).error,
        HanInputError.multipleCharacters);
    expect((validator.validate('中A') as InvalidHan).error,
        HanInputError.multipleCharacters);
    for (final value in ['cheng', '1', '。', '😀']) {
      expect((validator.validate(value) as InvalidHan).error,
          HanInputError.nonHanCharacter);
    }
  });
}
