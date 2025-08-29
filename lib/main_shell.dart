import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/shell_app.dart';
import 'core/asset_manager.dart';
import 'core/smart_preloader.dart';
import 'config/app_config.dart';
import 'theme/light_theme.dart';
import 'widgets/logo_branding.dart';
import 'core/deferred_maps.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  final shellApp = ShellApp();
  final assetManager = DynamicAssetManager();
  final smartPreloader = SmartPreloader();
  
  await shellApp.initialize();
  await assetManager.initialize();
  await smartPreloader.initialize();
  
  runApp(OptionShellApp());
}

class OptionShellApp extends StatelessWidget {
  const OptionShellApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'OPTION - Shell App',
      theme: LightTheme.theme,
      home: const ShellHomeScreen(),
      routes: {
        '/passenger': (context) => const ShellPassengerScreen(),
        '/driver': (context) => const ShellDriverScreen(),
        '/maps': (context) => const ShellMapsScreen(),
      },
    );
}

class ShellHomeScreen extends StatefulWidget {
  const ShellHomeScreen({super.key});

  @override
  State<ShellHomeScreen> createState() => _ShellHomeScreenState();
}

class _ShellHomeScreenState extends State<ShellHomeScreen> {
  final DynamicAssetManager _assetManager = DynamicAssetManager();
  
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: const LogoAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VerticalBrandLogo(),
            const SizedBox(height: 24),
            
            _buildShellInfo(),
            const SizedBox(height: 24),
            
            _buildModuleCards(),
            const SizedBox(height: 24),
            
            _buildOptimizationInfo(),
          ],
        ),
      ),
    );
  
  Widget _buildShellInfo() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rocket_launch, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Shell App Ativo',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                _InfoChip(
                  icon: Icons.download,
                  label: 'Download: 8MB',
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.speed,
                  label: 'Lazy Loading',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                _InfoChip(
                  icon: Icons.psychology,
                  label: 'AI Predictive',
                  color: Colors.purple,
                ),
                SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.cloud_download,
                  label: 'CDN Assets',
                  color: Colors.cyan,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  
  Widget _buildModuleCards() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Módulos Disponíveis',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ModuleCard(
                title: 'Passageiro',
                subtitle: 'Solicitar viagens',
                icon: Icons.person,
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, '/passenger'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModuleCard(
                title: 'Motorista',
                subtitle: 'Aceitar corridas',
                icon: Icons.local_taxi,
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, '/driver'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ModuleCard(
                title: 'Mapas',
                subtitle: 'Navegação avançada',
                icon: Icons.map,
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/maps'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModuleCard(
                title: 'Chat',
                subtitle: 'Comunicação',
                icon: Icons.chat,
                color: Colors.purple,
                onTap: () => _showComingSoon(context, 'Chat'),
              ),
            ),
          ],
        ),
      ],
    );
  
  Widget _buildOptimizationInfo() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  'Otimizações Ativas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _OptimizationItem(
              icon: Icons.compress,
              title: 'App Bundle & Split APKs',
              description: 'Download reduzido de 61MB → 8MB',
            ),
            const _OptimizationItem(
              icon: Icons.psychology_alt,
              title: 'AI Predictive Loading',
              description: 'Módulos carregados antes do uso',
            ),
            const _OptimizationItem(
              icon: Icons.cloud_sync,
              title: 'Dynamic Assets via CDN',
              description: 'Imagens carregadas sob demanda',
            ),
            const _OptimizationItem(
              icon: Icons.map_outlined,
              title: 'Google Maps Lazy Loading',
              description: 'Maps carregado apenas quando necessário',
            ),
          ],
        ),
      ),
    );
  
  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature - Em Breve'),
        content: Text('O módulo $feature será carregado dinamicamente quando necessário.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class ShellPassengerScreen extends StatelessWidget {
  const ShellPassengerScreen({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
      future: ShellApp().loadScreenWidget('passenger_home'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(moduleName: 'Passageiro');
        }
        if (snapshot.hasError) {
          return _ErrorScreen(
            moduleName: 'Passageiro',
            error: snapshot.error.toString(),
          );
        }
        return snapshot.data ?? const _ErrorScreen(moduleName: 'Passageiro');
      },
    );
}

class ShellDriverScreen extends StatelessWidget {
  const ShellDriverScreen({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
      future: ShellApp().loadScreenWidget('driver_home'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen(moduleName: 'Motorista');
        }
        if (snapshot.hasError) {
          return _ErrorScreen(
            moduleName: 'Motorista',
            error: snapshot.error.toString(),
          );
        }
        return snapshot.data ?? const _ErrorScreen(moduleName: 'Motorista');
      },
    );
}

class ShellMapsScreen extends StatelessWidget {
  const ShellMapsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Mapas - Lazy Loading')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.map, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Google Maps - Carregamento Inteligente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Os mapas são carregados dinamicamente quando necessário, '
                      'reduzindo o tamanho inicial do app.',
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<Map<String, double>?>(
                      future: DeferredLocationService.getCurrentLocation(),
                      builder: (context, snapshot) {
                        final location = snapshot.data ?? 
                            DeferredLocationService.getDefaultLocation();
                        
                        return SimpleMapsWidget(
                          latitude: location['latitude']!,
                          longitude: location['longitude']!,
                          title: 'Localização Atual',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

class _LoadingScreen extends StatelessWidget {
  
  const _LoadingScreen({required this.moduleName});
  final String moduleName;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(moduleName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Carregando módulo $moduleName...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Shell App - Dynamic Loading'),
          ],
        ),
      ),
    );
}

class _ErrorScreen extends StatelessWidget {
  
  const _ErrorScreen({required this.moduleName, this.error});
  final String moduleName;
  final String? error;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(moduleName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'Erro ao carregar $moduleName',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(fontSize: 12)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
}

class _InfoChip extends StatelessWidget {
  
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
}

class _ModuleCard extends StatelessWidget {
  
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
}

class _OptimizationItem extends StatelessWidget {
  
  const _OptimizationItem({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
}