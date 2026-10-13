import 'package:flutter_test/flutter_test.dart';
import 'package:cars_night/backend/market.dart';
void main(){
 test('market money uses exact currency minor units',(){
  expect(parseMarketPrice('12.34','USD'),1234);
  expect(parseMarketPrice('12','JPY'),12);
  expect(parseMarketPrice('12.5','JPY'),isNull);
  expect(parseMarketPrice('12.345','KWD'),12345);
  expect(parseMarketPrice('0','USD'),isNull);
  expect(parseMarketPrice('-1','USD'),isNull);
  expect(parseMarketPrice('12.345','USD'),isNull);
  expect(parseMarketPrice('1e9','USD'),isNull);
  expect(marketPrice({'currency':'JPY','price_minor':1200,'kind':'sale'}),'JPY 1200');
  expect(marketPrice({'currency':'KWD','price_minor':12001,'kind':'rental'}),'KWD 12.001 / day');
 });
}
