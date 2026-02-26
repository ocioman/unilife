import 'package:json_annotation/json_annotation.dart';
import 'package:unilife/model/hours_mins.dart';


/*
  Dato che passo al db "from" e "now" con il padding (es al posto di avere 9:5:0 ho 09:05:00)
  la classe hours_mins.g.dart non sa come deserializzare la risposta del DB dato che nella tabella
  class from e now sono di tipo time, quindi devo usare un converter 
 */
class HoursMinsConverter implements JsonConverter<HoursMins, String>{
  const HoursMinsConverter();

  @override
  HoursMins fromJson(String json) {
    final parts = json.split(':');
    return HoursMins(
      hours: int.parse(parts[0]),
      mins: int.parse(parts[1]),
      secs: int.parse(parts[2]),
    );
  }

  @override
  String toJson(HoursMins object)=>object.toSqlTime();
}