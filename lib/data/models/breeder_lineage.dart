import 'breeder.dart';

class BreederLineage {
  final Breeder breeder;
  final Breeder? parentJantan;
  final Breeder? parentBetina;

  BreederLineage({
    required this.breeder,
    this.parentJantan,
    this.parentBetina,
  });

  factory BreederLineage.fromJson(Map<String, dynamic> json) => BreederLineage(
    breeder: Breeder.fromJson(json['breeder'] as Map<String, dynamic>),
    parentJantan: json['parent_jantan'] != null
        ? Breeder.fromJson(json['parent_jantan'] as Map<String, dynamic>)
        : null,
    parentBetina: json['parent_betina'] != null
        ? Breeder.fromJson(json['parent_betina'] as Map<String, dynamic>)
        : null,
  );
}
