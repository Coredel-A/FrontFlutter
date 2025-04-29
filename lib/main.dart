import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/cart_provider.dart';
import './screens/cart_screen.dart';
import './screens/product_detail_screen.dart';
import './delegates/product_search_delegate.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'models/producto.dart'; // Importar el modelo de Producto

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Importante para usar async en main
  
  Stripe.publishableKey = 'pk_test_51RIcIrIg6oHd84jhXVr9iY61Hi6gQux37Gr5735Kzq2CcQiXaY5rinTFYqXrL1wlTkbaRmfMIgOwgE767dpzNdhq00Oadc8pSH'; // Reemplaza con tu clave publicable
  try {
    await Stripe.instance.applySettings();
    print('Stripe inicializado correctamente');
  } catch (e) {
    print('Error inicializando Stripe: $e');
  }
  final apiService = ApiService();
  final isLoggedIn = await apiService.isUserLoggedIn();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => apiService),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget { 
  final bool isLoggedIn;
  
  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-commerce App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',  // Mantén la ruta inicial en /login
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigationScreen(), // Cambiar a MainNavigationScreen
        '/cart': (context) => CartScreen(),
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  // Esta función inicializa el reconocimiento de voz
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  // Esta función comienza a escuchar
  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
    setState(() {});
  }

  // Esta función detiene la escucha
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  // Esta función se llama cuando el reconocimiento de voz tiene un resultado
  void _onSpeechResult(SpeechRecognitionResult result) {
    String recognizedText = result.recognizedWords.toLowerCase();
    
    setState(() {
      _lastWords = result.recognizedWords;
    });
    
    // Si tenemos un resultado final, procesamos el comando
    if (result.finalResult && recognizedText.isNotEmpty) {
      _processVoiceCommand(recognizedText);
    }
  }

  // Mejora del método que procesa comandos de voz
 void _processVoiceCommand(String command) {
    print('Procesando comando de voz: "$command"');
    String lowerCommand = command.toLowerCase();
    
    // Comando para agregar al carrito
    if (lowerCommand.contains('agregar') && 
      (lowerCommand.contains('carrito') || lowerCommand.contains('carro') || lowerCommand.contains('compras'))) {
      
      print('Detectado comando para agregar al carrito');
      
      // Estamos en la pantalla de detalles de producto?
      if (ModalRoute.of(context)?.settings.name == '/product_detail') {
        // Si estamos en la pantalla de detalle de producto, agregamos ese producto
        _addCurrentProductToCart();
      } else {
        // Extraer el nombre del producto del comando
        String productQuery = _extractProductName(command);
        if (productQuery.isNotEmpty) {
          _searchAndAddToCart(productQuery);
        } else {
          // Mostrar mensaje solicitando especificar un producto
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, especifica qué producto quieres agregar al carrito'))
          );
        }
      }
    } 
    // Comando para buscar producto (si no es agregar al carrito, asumimos que es búsqueda)
    else {
      print('Detectado comando para búsqueda general');
      // Filtrar palabras comunes
      String searchQuery = _filterSearchQuery(command);
      if (searchQuery.isNotEmpty) {
        _performVoiceSearch(searchQuery);
      }
    }
    setState(() {
      _lastWords = '';
    });
  }


  // Función para filtrar términos de búsqueda - VERSIÓN MEJORADA
  String _filterSearchQuery(String query) {
    // Convertir todo a minúsculas para procesar
    String lowercaseQuery = query.toLowerCase();
    
    List<String> filtersWords = [
      "busca", "búscame", "buscar", "muestra", "muéstrame", "encuentra", 
      "enséñame", "quiero", "quiero ver", "ver", "dame", "un", "una", "unos", "unas"
    ];
    
    String filteredQuery = lowercaseQuery;
    for (String word in filtersWords) {
      // Reemplazar palabras completas
      filteredQuery = filteredQuery.replaceAll(" $word ", " ");
      // Reemplazar al inicio
      if (filteredQuery.startsWith("$word ")) {
        filteredQuery = filteredQuery.substring(word.length + 1);
      }
      // Reemplazar al final
      if (filteredQuery.endsWith(" $word")) {
        filteredQuery = filteredQuery.substring(0, filteredQuery.length - word.length - 1);
      }
    }
    
    // Limpiar espacios múltiples y recortar
    filteredQuery = filteredQuery.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    print('Query original: "$query"');
    print('Query filtrada: "$filteredQuery"');
    
    return filteredQuery;
  }

  // Función para extraer nombre de producto del comando - VERSIÓN MEJORADA
  String _extractProductName(String command) {
    // Convertir todo a minúsculas para procesar
    String lowercaseCommand = command.toLowerCase();
    
    // Patrones comunes como "agregar [producto] al carrito"
    List<String> patterns = [
      "agregar", "añadir", "poner", "meter", "carrito", "carro", "compras", 
      "al", "a", "el", "la", "los", "las", "un", "una", "unos", "unas"
    ];
    
    String productName = lowercaseCommand;
    for (String pattern in patterns) {
      // Reemplazar palabras completas con espacios alrededor
      productName = productName.replaceAll(" $pattern ", " ");
      // Reemplazar al inicio
      if (productName.startsWith("$pattern ")) {
        productName = productName.substring(pattern.length + 1);
      }
      // Reemplazar al final
      if (productName.endsWith(" $pattern")) {
        productName = productName.substring(0, productName.length - pattern.length - 1);
      }
    }
    
    // Limpiar espacios múltiples y recortar
    productName = productName.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Imprimir para depuración
    print('Comando original: "$command"');
    print('Nombre de producto extraído: "$productName"');
    
    return productName;
  }

  // Función para agregar el producto actual al carrito
  void _addCurrentProductToCart() {
    // Modificamos para usar la versión StatefulWidget de ProductDetailScreen
    final ProductDetailScreenState? productState = 
        context.findAncestorStateOfType<ProductDetailScreenState>();
    
    if (productState != null && productState.producto != null) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.addItem(productState.producto!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${productState.producto!.nombre} agregado al carrito'),
          action: SnackBarAction(
            label: 'Ver carrito',
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        )
      );
    }
  } 

 // Función para buscar un producto y agregarlo al carrito - VERSIÓN MEJORADA
  void _searchAndAddToCart(String productQuery) async {
    if (productQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, especifica qué producto quieres agregar al carrito'))
      );
      return;
    }
    
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Buscando producto...'),
            ],
          ),
        );
      },
    );
    
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    try {
      // Registrar para depuración
      print('Iniciando búsqueda para: "$productQuery"');
      
      // Buscar el producto
      final productos = await apiService.searchProducts(productQuery);
      
      // Cerrar el diálogo de carga
      if (context.mounted) Navigator.of(context).pop();
      
      if (productos.isEmpty) {
        // Intentar búsqueda por partes del nombre
        List<String> keywords = productQuery.split(' ');
        if (keywords.length > 1) {
          print('Intentando búsqueda por palabras clave: $keywords');
          // Intentar con solo la primera palabra o las dos primeras
          String alternativeQuery = keywords.length > 2 ? 
              '${keywords[0]} ${keywords[1]}' : keywords[0];
          
          print('Búsqueda alternativa: "$alternativeQuery"');
          final productosAlternativos = await apiService.searchProducts(alternativeQuery);
          
          if (productosAlternativos.isNotEmpty) {
            if (context.mounted) {
              _showProductSelectionDialog(productosAlternativos);
              return;
            }
          }
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se encontró "$productQuery". Intenta buscar con otra frase.'),
              duration: const Duration(seconds: 4),
            )
          );
        }
        return;
      }
      
      print('Productos encontrados: ${productos.length}');
      
      // Si encontramos productos, mostramos opciones o agregamos el primero
      if (productos.length == 1) {
        // Solo hay un producto, lo agregamos directamente
        _addProductToCart(productos[0]);
      } else {
        // Hay múltiples productos, mostramos opciones
        if (context.mounted) {
          _showProductSelectionDialog(productos);
        }
      }
    } catch (e) {
      // Cerrar el diálogo de carga
      if (context.mounted) Navigator.of(context).pop();
      
      // Mostrar error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se pudo buscar el producto. $e'))
        );
      }
      print('Error en búsqueda: $e');
    }
  }

  // Función para agregar un producto específico al carrito
  void _addProductToCart(Producto producto) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(producto);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto.nombre} agregado al carrito'),
        action: SnackBarAction(
          label: 'Ver carrito',
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      )
    );
  }

  // Función para mostrar diálogo de selección de producto
  void _showProductSelectionDialog(List<Producto> productos) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona un producto'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final producto = productos[index];
                return ListTile(
                  leading: producto.imagen != null
                    ? Image.network(
                        producto.imagen!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported);
                        },
                      )
                    : const Icon(Icons.image_not_supported),
                  title: Text(producto.nombre),
                  subtitle: Text('${producto.marca} - \$${producto.precio}'),
                  onTap: () {
                    Navigator.pop(context); // Cerrar diálogo
                    _addProductToCart(producto);
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Esta función realiza la búsqueda basada en el texto reconocido - VERSIÓN MEJORADA
  void _performVoiceSearch(String query) async {
    // Detenemos la escucha si está activa
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, especifica qué producto quieres buscar'))
      );
      return;
    }

    print('Iniciando búsqueda por voz: "$query"');

    if (context.mounted) {
      // Llamamos a la búsqueda con el texto reconocido
      final searchDelegate = ProductSearchDelegate();
      
      // Establecemos manualmente la query antes de mostrar el delegate
      searchDelegate.query = query;
      
      final int? selectedProductId = await showSearch<int?>(
        context: context,
        delegate: searchDelegate,
        query: query, // Pasamos la query aquí también
      );
      
      if (selectedProductId != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: selectedProductId,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TechStore'),
        actions: [
          // Botón de búsqueda por voz con indicador visual
          IconButton(
            icon: Icon(
              _speechToText.isListening ? Icons.mic : Icons.mic_none,
              color: _speechToText.isListening ? Colors.red : null,
            ),
            onPressed: _speechEnabled 
              ? (_speechToText.isListening ? _stopListening : _startListening)
              : null,
            tooltip: 'Búsqueda por voz',
          ),
          // Botón de búsqueda normal
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final int? selectedProductId = await showSearch<int?>(
                context: context,
                delegate: ProductSearchDelegate(),
              );
              
              if (selectedProductId != null && context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      productId: selectedProductId,
                    ),
                  ),
                );
              }
            },
          ),   
          // Botón de carrito
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _screens[_currentIndex],
          // Mostrar indicador cuando estamos escuchando
          if (_speechToText.isListening)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _lastWords.isEmpty ? 'Escuchando...' : '"$_lastWords"',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == 2) {
            // Cuando el usuario toca el ítem de perfil
            final apiService = Provider.of<ApiService>(context, listen: false);
            final isLoggedIn = await apiService.isUserLoggedIn();

            if (!isLoggedIn) {
              // Si no ha iniciado sesión, mostrar pantalla de login
              Navigator.pushNamed(context, '/login');
              return;
            } else {
              // Si ha iniciado sesión, actualizar el índice para mostrar la pantalla de perfil
              setState(() {
                _currentIndex = index;
              });
            }
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorías',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}