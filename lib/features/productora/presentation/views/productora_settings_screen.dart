import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../data/models/productora_model.dart';

/// Pantalla de ajustes de la empresa productora.
/// Permite editar la información general y configuración de la empresa.
class ProductoraSettingsScreen extends ConsumerStatefulWidget {
  final String productoraId;
  const ProductoraSettingsScreen({super.key, required this.productoraId});

  @override
  ConsumerState<ProductoraSettingsScreen> createState() =>
      _ProductoraSettingsScreenState();
}

class _ProductoraSettingsScreenState
    extends ConsumerState<ProductoraSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nombreController = TextEditingController();
  final _rtnController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();
  final _semanasController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  ProductoraModel? _productora;

  @override
  void initState() {
    super.initState();
    _loadProductora();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rtnController.dispose();
    _ubicacionController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    _semanasController.dispose();
    super.dispose();
  }

  Future<void> _loadProductora() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestorePaths.productoras)
          .doc(widget.productoraId)
          .get();

      if (doc.exists && mounted) {
        final prod = ProductoraModel.fromFirestore(doc);
        setState(() {
          _productora = prod;

          // Cargar datos en controllers
          _nombreController.text = prod.name;
          _rtnController.text =
              prod.rnt ?? ''; // rnt property in model maps to rtn in db
          _ubicacionController.text = prod.location ?? '';
          _telefonoController.text = prod.contactPhone ?? '';
          _correoController.text = prod.contactEmail ?? '';
          _semanasController.text = prod.semanasParaCosecha.toString();

          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    final semanas = int.tryParse(_semanasController.text.trim());
    if (semanas == null || semanas < 1 || semanas > 104) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un valor de semanas válido (1-104)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Preparar datos para update
      final Map<String, dynamic> updates = {
        'nombre': _nombreController.text.trim(),
        'rtn': _rtnController.text.trim().isEmpty
            ? null
            : _rtnController.text.trim(),
        'ubicacion': _ubicacionController.text.trim().isEmpty
            ? null
            : _ubicacionController.text.trim(),
        'telefono_contacto': _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        'correo_contacto': _correoController.text.trim().isEmpty
            ? null
            : _correoController.text.trim(),
        'semanas_para_cosecha': semanas,
        'fecha_actualizacion': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection(FirestorePaths.productoras)
          .doc(widget.productoraId)
          .update(updates);

      // Actualizar modelo local para reflejar cambios
      if (_productora != null) {
        _productora = _productora!.copyWith(
          name: updates['nombre'],
          rnt: updates['rtn'],
          location: updates['ubicacion'],
          contactPhone: updates['telefono_contacto'],
          contactEmail: updates['correo_contacto'],
          semanasParaCosecha: semanas,
        );
      }

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Información actualizada correctamente'),
              ],
            ),
            backgroundColor: AppColors.estadoCosechado,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        title: const Text('Ajustes de Empresa'),
        centerTitle: true,
        backgroundColor: AppColors.surfaceVariant,
        elevation: 0,
        actions: [
          if (!_loading && _productora != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                onPressed: _saving ? null : _guardarCambios,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.save_rounded, color: AppColors.primary),
                tooltip: 'Guardar Cambios',
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _productora == null
          ? const Center(child: Text('No se encontró la empresa'))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Información General'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nombreController,
                            label: 'Nombre de la Empresa *',
                            icon: Icons.business_rounded,
                            validator: (v) =>
                                v?.trim().isEmpty == true ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _rtnController,
                            label: 'RTN',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _ubicacionController,
                            label: 'Ubicación',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _telefonoController,
                            label: 'Teléfono',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _correoController,
                            label: 'Correo Electrónico',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    _buildSectionTitle('Configuración de Cosecha'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Semanas para Proyección',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tiempo estimado desde encintado hasta cosecha.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _semanasController,
                            label: 'Semanas',
                            icon: Icons.calendar_month_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            suffixText: 'semanas',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _guardarCambios,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _saving ? 'Guardando...' : 'Guardar Cambios',
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
        suffixText: suffixText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
