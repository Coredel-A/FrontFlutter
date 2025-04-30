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
import './screens/product_detail_screen.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'models/producto.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey =
      'pk_test_51RIcIrIg6oHd84jhXVr9iY61Hi6gQux37Gr5735Kzq2CcQiXaY5rinTFYqXrL1wlTkbaRmfMIgOwgE767dpzNdhq00Oadc8pSH'; // Reemplaza con tu clave publicable
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
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainNavigationScreen(),
        '/cart': (context) => CartScreen(),
        '/product-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int;
          return ProductDetailScreen(productId: args);
        },
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

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    String recognizedText = result.recognizedWords.toLowerCase();

    setState(() {
      _lastWords = result.recognizedWords;
    });

    if (result.finalResult && recognizedText.isNotEmpty) {
      _processVoiceCommand(recognizedText);
    }
  }

  void _processVoiceCommand(String command) {
    print('Procesando comando de voz: "$command"');
    String lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('agregar') &&
        (lowerCommand.contains('carrito') ||
            lowerCommand.contains('carro') ||
            lowerCommand.contains('compras'))) {
      print('Detectado comando para agregar al carrito');

      if (ModalRoute.of(context)?.settings.name == '/product_detail') {
        _addCurrentProductToCart();
      } else {
        String productQuery = _extractProductName(command);
        if (productQuery.isNotEmpty) {
          _searchAndAddToCart(productQuery);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Por favor, especifica qué producto quieres agregar al carrito',
              ),
            ),
          );
        }
      }
    } else {
      print('Detectado comando para búsqueda general');
      String searchQuery = _filterSearchQuery(command);
      if (searchQuery.isNotEmpty) {
        _performVoiceSearch(searchQuery);
      }
    }
    setState(() {
      _lastWords = '';
    });
  }

  String _filterSearchQuery(String query) {
    String lowercaseQuery = query.toLowerCase();

    List<String> filtersWords = [
      "busca",
      "búscame",
      "buscar",
      "muestra",
      "muéstrame",
      "encuentra",
      "enséñame",
      "quiero",
      "quiero ver",
      "ver",
      "dame",
      "un",
      "una",
      "unos",
      "unas",
    ];

    String filteredQuery = lowercaseQuery;
    for (String word in filtersWords) {
      filteredQuery = filteredQuery.replaceAll(" $word ", " ");
      if (filteredQuery.startsWith("$word ")) {
        filteredQuery = filteredQuery.substring(word.length + 1);
      }
      if (filteredQuery.endsWith(" $word")) {
        filteredQuery = filteredQuery.substring(
          0,
          filteredQuery.length - word.length - 1,
        );
      }
    }

    filteredQuery = filteredQuery.replaceAll(RegExp(r'\s+'), ' ').trim();

    print('Query original: "$query"');
    print('Query filtrada: "$filteredQuery"');

    return filteredQuery;
  }

  String _extractProductName(String command) {
    String lowercaseCommand = command.toLowerCase();

    List<String> patterns = [
      "agregar",
      "añadir",
      "poner",
      "meter",
      "carrito",
      "carro",
      "compras",
      "al",
      "a",
      "el",
      "la",
      "los",
      "las",
      "un",
      "una",
      "unos",
      "unas",
    ];

    String productName = lowercaseCommand;
    for (String pattern in patterns) {
      productName = productName.replaceAll(" $pattern ", " ");
      if (productName.startsWith("$pattern ")) {
        productName = productName.substring(pattern.length + 1);
      }
      if (productName.endsWith(" $pattern")) {
        productName = productName.substring(
          0,
          productName.length - pattern.length - 1,
        );
      }
    }

    productName = productName.replaceAll(RegExp(r'\s+'), ' ').trim();

    print('Comando original: "$command"');
    print('Nombre de producto extraído: "$productName"');

    return productName;
  }

  void _addCurrentProductToCart() {
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
        ),
      );
    }
  }

  void _searchAndAddToCart(String productQuery) async {
    if (productQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, especifica qué producto quieres agregar al carrito',
          ),
        ),
      );
      return;
    }

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
      print('Iniciando búsqueda para: "$productQuery"');

      final productos = await apiService.searchProducts(productQuery);

      if (context.mounted) Navigator.of(context).pop();

      if (productos.isEmpty) {
        List<String> keywords = productQuery.split(' ');
        if (keywords.length > 1) {
          print('Intentando búsqueda por palabras clave: $keywords');
          String alternativeQuery =
              keywords.length > 2
                  ? '${keywords[0]} ${keywords[1]}'
                  : keywords[0];

          print('Búsqueda alternativa: "$alternativeQuery"');
          final productosAlternativos = await apiService.searchProducts(
            alternativeQuery,
          );

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
              content: Text(
                'No se encontró "$productQuery". Intenta buscar con otra frase.',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      print('Productos encontrados: ${productos.length}');

      if (productos.length == 1) {
        _addProductToCart(productos[0]);
      } else {
        if (context.mounted) {
          _showProductSelectionDialog(productos);
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se pudo buscar el producto. $e')),
        );
      }
      print('Error en búsqueda: $e');
    }
  }

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
      ),
    );
  }

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
                  leading:
                      producto.imagen != null
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
                    Navigator.pop(context);
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

  void _performVoiceSearch(String query) async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, especifica qué producto quieres buscar'),
        ),
      );
      return;
    }

    print('Iniciando búsqueda por voz: "$query"');

    if (context.mounted) {
      final searchDelegate = ProductSearchDelegate();
      searchDelegate.query = query;

      final int? selectedProductId = await showSearch<int?>(
        context: context,
        delegate: searchDelegate,
        query: query,
      );

      if (selectedProductId != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ProductDetailScreen(productId: selectedProductId),
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
          IconButton(
            icon: Icon(
              _speechToText.isListening ? Icons.mic : Icons.mic_none,
              color: _speechToText.isListening ? Colors.red : null,
            ),
            onPressed:
                _speechEnabled
                    ? (_speechToText.isListening
                        ? _stopListening
                        : _startListening)
                    : null,
            tooltip: 'Búsqueda por voz',
          ),
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
                    builder:
                        (context) =>
                            ProductDetailScreen(productId: selectedProductId),
                  ),
                );
              }
            },
          ),
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
          if (_speechToText.isListening)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
            final apiService = Provider.of<ApiService>(context, listen: false);
            final isLoggedIn = await apiService.isUserLoggedIn();

            if (!isLoggedIn) {
              Navigator.pushNamed(context, '/login');
              return;
            } else {
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorías',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
