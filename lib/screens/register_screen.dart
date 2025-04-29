import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/usuario.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  String passwordConfirm = '';
  String phone = '';
  bool isLoading = false;
  String? errorMessage;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      Usuario user = await apiService.register(name, email, password, phone, context);
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Bienvenido, ${user.nombre}! Tu cuenta ha sido creada.'))
      );
      
      // Navegar a la pantalla principal
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crear Cuenta")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Regístrate",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 5),
              
              const Text(
                "Crea una cuenta para empezar a comprar",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 20),
              
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
                ),
                
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Nombre completo",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onSaved: (value) => name = value!.trim(),
                validator: (value) =>
                    value == null || value.isEmpty ? "El nombre es requerido" : null,
              ),
              
              const SizedBox(height: 15),
              
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) => email = value!.trim(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "El email es requerido";
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return "Ingresa un email válido";
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 15),
              
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Teléfono",
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onSaved: (value) => phone = value!.trim(),
                validator: (value) =>
                    value == null || value.isEmpty ? "El teléfono es requerido" : null,
              ),
              
              const SizedBox(height: 15),
              
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onSaved: (value) => password = value!,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "La contraseña es requerida";
                  }
                  if (value.length < 6) {
                    return "La contraseña debe tener al menos 6 caracteres";
                  }
                  return null;
                },
                onChanged: (value) {
                  // Para actualizaciones en validación de confirmación
                  password = value;
                },
              ),
              
              const SizedBox(height: 15),
              
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Confirmar contraseña",
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Confirma tu contraseña";
                  }
                  if (value != password) {
                    return "Las contraseñas no coinciden";
                  }
                  return null;
                },
                onSaved: (value) => passwordConfirm = value!,
              ),
              
              const SizedBox(height: 25),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "CREAR CUENTA",
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              ),
              
              const SizedBox(height: 15),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿Ya tienes cuenta?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text("Inicia sesión"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}