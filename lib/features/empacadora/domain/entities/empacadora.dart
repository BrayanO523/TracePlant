import 'package:equatable/equatable.dart';

class Empacadora extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String? location;
  final String? rnt;
  final int? capacity;
  final bool isActive;
  final String ownerUid;
  final String? shift; // Turno
  final String? contactPhone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Empacadora({
    required this.id,
    required this.name,
    this.code,
    this.location,
    this.rnt,
    this.capacity,
    this.isActive = true,
    required this.ownerUid,
    this.shift,
    this.contactPhone,
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
    capacity,
    isActive,
    ownerUid,
    shift,
    contactPhone,
    createdAt,
    updatedAt,
  ];
}
