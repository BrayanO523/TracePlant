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
    isActive,
    ownerUid,
    semanasParaCosecha,
    createdAt,
    updatedAt,
  ];
}
