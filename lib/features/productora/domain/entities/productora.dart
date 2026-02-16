import 'package:equatable/equatable.dart';

class Productora extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String? location;
  final String? rnt;
  final String? contactPhone;
  final String? contactEmail;
  final bool isActive;
  final String ownerUid;
  final int
  semanasParaCosecha; // Semanas después de encintado para proyectar cosecha
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Productora({
    required this.id,
    required this.name,
    this.code,
    this.location,
    this.rnt,
    this.contactPhone,
    this.contactEmail,
    this.isActive = true,
    required this.ownerUid,
    this.semanasParaCosecha = 30,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    location,
    rnt,
    contactPhone,
    contactEmail,
    isActive,
    ownerUid,
    semanasParaCosecha,
    createdAt,
    updatedAt,
  ];

  Productora copyWith({
    String? id,
    String? name,
    String? code,
    String? location,
    String? rnt,
    String? contactPhone,
    String? contactEmail,
    bool? isActive,
    String? ownerUid,
    int? semanasParaCosecha,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Productora(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      location: location ?? this.location,
      rnt: rnt ?? this.rnt,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      isActive: isActive ?? this.isActive,
      ownerUid: ownerUid ?? this.ownerUid,
      semanasParaCosecha: semanasParaCosecha ?? this.semanasParaCosecha,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
