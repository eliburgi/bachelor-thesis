import 'package:flutter_test/flutter_test.dart';
import 'package:interpreter/src/util.dart';

void main() {
  test('test isDigit with all possible digits', () {
    var list = List.generate(10, (digit) => '$digit')
        .map((char) => Util.isDigit(char))
        .toList();
    expect(list, List.generate(10, (index) => true));
  });

  test('test isDigit with numbers', () {
    var num1 = '15';
    var num2 = '-5';
    var num3 = '3.5';

    expect(Util.isDigit(num1), false);
    expect(Util.isDigit(num2), false);
    expect(Util.isDigit(num3), false);
  });

  test('test isDigit with non-numbers', () {
    var val1 = 'abc';
    var val2 = 'Z3';
    var val3 = '_1';

    expect(Util.isDigit(val1), false);
    expect(Util.isDigit(val2), false);
    expect(Util.isDigit(val3), false);
  });

  test('test isLetter with all possible letters', () {
    var letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    var lettersLowercase = letters.toLowerCase();

    for (var i = 0; i < letters.length; i++) {
      expect(Util.isLetter(letters[i]), true);
      expect(Util.isLetter(lettersLowercase[i]), true);
    }
  });

  test('test isLetter with non letters', () {
    expect(Util.isLetter('AB'), false);
    expect(Util.isLetter('1'), false);
    expect(Util.isLetter('_'), false);
  });
}
