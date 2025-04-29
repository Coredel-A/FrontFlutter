// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/usuario.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  Usuario? usuario;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profile = await apiService.getUserProfile();
      
      if (mounted) {
        setState(() {
          usuario = profile;
          isLoading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceAll("Exception: ", "");
          isLoading = false;
        });
        
        // Si es un error de sesión, redirigir al login
        if (e.toString().contains("sesión") || e.toString().contains("autenticado")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesión expirada. Por favor inicia sesión nuevamente.'))
          );
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushReplacementNamed(context, '/login');
          });
        }
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Mostrar indicador de carga
              setState(() {
                isLoading = true;
              });
              
              final apiService = Provider.of<ApiService>(context, listen: false);
              await apiService.logout();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Has cerrado sesión correctamente'))
                );
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadUserProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    )
                  else if (usuario != null)
                    Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          usuario!.nombre,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (usuario!.rol.isNotEmpty)
                          Chip(
                            label: Text(
                              _getRolLabel(usuario!.rol),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: _getRolColor(usuario!.rol),
                          ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Información personal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildProfileField('Email', usuario!.email),
                                _buildProfileField('Teléfono', usuario!.telefono ?? 'No especificado'),
                                _buildProfileField('Estado', _getEstadoLabel(usuario!.estado)),
                                if (usuario!.puesto != null && usuario!.puesto!.isNotEmpty)
                                  _buildProfileField('Puesto', usuario!.puesto!),
                                if (usuario!.sucursalId != null)
                                  _buildProfileField('Sucursal', 'Sucursal ID: ${usuario!.sucursalId}'),
                                _buildProfileField('Fecha de registro', _formatDate(usuario!.fechaRegistro)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Aquí podríamos navegar a una pantalla de edición de perfil
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Función de edición no implementada'))
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar Perfil'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
    );
  }

  String _getRolLabel(String rol) {
    switch (rol) {
      case 'cliente':
        return 'Cliente';
      case 'empleado':
        return 'Empleado';
      case 'admin':
        return 'Administrador';
      default:
        return rol.isNotEmpty ? rol.substring(0, 1).toUpperCase() + rol.substring(1) : 'Desconocido';
    }
  }

  Color _getRolColor(String rol) {
    switch (rol) {
      case 'cliente':
        return Colors.green;
      case 'empleado':
        return Colors.blue;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoLabel(String estado) {
    switch (estado) {
      case 'activo':
        return 'Activo';
      case 'inactivo':
        return 'Inactivo';
      case 'suspendido':
        return 'Suspendido';
      default:
        return estado.isNotEmpty ? estado.substring(0, 1).toUpperCase() + estado.substring(1) : 'Desconocido';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}