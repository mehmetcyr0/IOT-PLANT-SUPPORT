import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/plant.dart';

class LedControlScreen extends StatefulWidget {
  const LedControlScreen({super.key});

  @override
  State<LedControlScreen> createState() => _LedControlScreenState();
}

class _LedControlScreenState extends State<LedControlScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService(
    SupabaseService.client,
  );

  String _led1Value = 'off'; // 'red', 'blue', 'off'
  String _led2Value = 'off'; // 'red', 'blue', 'off'
  bool _isLoading = false;
  bool _isConnected = false;
  Plant? _selectedPlant;
  GrowthPeriod? _selectedPeriod;
  bool _isPlantSelectionExpanded = false;
  bool _isPeriodSelectionExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Varsayılan olarak hiçbir bitki seçili değil
    _selectedPlant = null;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadLedValues();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLedValues() async {
    setState(() => _isLoading = true);
    try {
      final values = await _supabaseService.getLedValues();
      setState(() {
        _led1Value = values['led1'] ?? 'off';
        _led2Value = values['led2'] ?? 'off';
        _isConnected = true;
      });
    } catch (e) {
      setState(() => _isConnected = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Bağlantı hatası: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLed1(String value) async {
    setState(() => _led1Value = value);
    final success = await _supabaseService.updateLed1(value);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('LED1 güncellenemedi'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _updateLed2(String value) async {
    setState(() => _led2Value = value);
    final success = await _supabaseService.updateLed2(value);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('LED2 güncellenemedi'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Bitki Işık Destek'),
          ],
        ),
        actions: [
          // Bağlantı Durumu İkonu
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Bağlı' : 'Bağlantı Yok',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isConnected ? Icons.refresh : Icons.refresh,
              color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
            ),
            onPressed: _loadLedValues,
            tooltip: 'Bağlantıyı Yenile',
          ),
        ],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.grey.shade900, Colors.grey.shade800]
                  : [Colors.green.shade50, Colors.white],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Colors.grey.shade900,
                    Colors.grey.shade800,
                    Colors.green.shade900.withOpacity(0.3),
                  ]
                : [Colors.green.shade50, Colors.white, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Yükleniyor...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Bitki Seçimi Kartı
                        _buildPlantSelectionCard(context, theme),
                        const SizedBox(height: 24),

                        // Dönem Seçimi (Sadece bitki seçildiyse ve dönemleri varsa)
                        if (_selectedPlant != null &&
                            _selectedPlant!.periods != null &&
                            _selectedPlant!.periods!.isNotEmpty) ...[
                          _buildPeriodSelectionCard(context, theme),
                          const SizedBox(height: 24),
                        ],

                        // LED1 Kontrolü
                        _buildLedCard(
                          context: context,
                          title: 'LED1',
                          subtitle: 'Kırmızı/Mavi LED Kontrolü',
                          value: _led1Value,
                          onChanged: _updateLed1,
                        ),
                        const SizedBox(height: 20),

                        // LED2 Kontrolü
                        _buildLedCard(
                          context: context,
                          title: 'LED2',
                          subtitle: 'Kırmızı/Mavi LED Kontrolü',
                          value: _led2Value,
                          onChanged: _updateLed2,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPlantSelectionCard(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.green.shade100.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isPlantSelectionExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isPlantSelectionExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          leading: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_florist,
              color: Colors.white,
              size: 32,
            ),
          ),
          title: Text(
            'Bitki Seçimi',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          subtitle: _selectedPlant != null
              ? Text(
                  'Seçili: ${_selectedPlant!.name} ${_selectedPlant!.icon}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade700,
                  ),
                )
              : Text(
                  'Bitki seçilmedi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
          trailing: Icon(
            _isPlantSelectionExpanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            color: Colors.green.shade700,
            size: 32,
          ),
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Seçimi Kaldır butonu
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPlant = null;
                          _selectedPeriod =
                              null; // Bitki kaldırıldığında dönem de sıfırla
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: _selectedPlant == null
                              ? LinearGradient(
                                  colors: [
                                    Colors.grey.shade400,
                                    Colors.grey.shade600,
                                  ],
                                )
                              : null,
                          color: _selectedPlant == null ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedPlant == null
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                            width: _selectedPlant == null ? 2 : 1,
                          ),
                          boxShadow: _selectedPlant == null
                              ? [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close,
                              color: _selectedPlant == null
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Seçimi Kaldır',
                              style: TextStyle(
                                color: _selectedPlant == null
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: _selectedPlant == null
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Bitki seçenekleri
                ...PlantData.plants.map((plant) {
                  final isSelected = _selectedPlant?.id == plant.id;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            // Eğer zaten seçiliyse seçimi kaldır, değilse seç
                            _selectedPlant = isSelected ? null : plant;
                            _selectedPeriod =
                                null; // Bitki değiştiğinde dönem sıfırla
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green.shade700
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                plant.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                plant.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.green.shade800,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
            if (_selectedPlant != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade100, Colors.green.shade50],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedPlant!.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPlant!.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedPlant!.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelectionCard(BuildContext context, ThemeData theme) {
    if (_selectedPlant?.periods == null || _selectedPlant!.periods!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isPeriodSelectionExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isPeriodSelectionExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade600],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            'Büyüme Dönemi',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          subtitle: _selectedPeriod != null
              ? Text(
                  'Seçili: ${_selectedPeriod!.name} ${_selectedPeriod!.icon}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade700,
                  ),
                )
              : Text(
                  'Dönem seçin',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
          trailing: Icon(
            _isPeriodSelectionExpanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            color: Colors.blue.shade700,
            size: 28,
          ),
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _selectedPlant!.periods!.map((period) {
                final isSelected = _selectedPeriod?.id == period.id;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        setState(() {
                          _selectedPeriod = isSelected ? null : period;
                        });
                        // Dönem seçildiğinde LED değerlerini otomatik gönder
                        if (!isSelected) {
                          await _updateLed1(period.led1);
                          await _updateLed2(period.led2);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.purple.shade600,
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              period.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              period.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.blue.shade800,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              period.mode,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.blue.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedPeriod != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.purple.shade50],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade300, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _selectedPeriod!.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedPeriod!.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'LED1: ${_getStatusText(_selectedPeriod!.led1)}, LED2: ${_getStatusText(_selectedPeriod!.led2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLedCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String value,
    required Function(String) onChanged,
  }) {
    final theme = Theme.of(context);
    final isRed = value == 'red';
    final isBlue = value == 'blue';

    Color primaryColor;
    List<Color> gradient;
    IconData icon;

    if (isRed) {
      primaryColor = Colors.red;
      gradient = [Colors.red.shade400, Colors.red.shade700];
      icon = Icons.lightbulb;
    } else if (isBlue) {
      primaryColor = Colors.blue;
      gradient = [Colors.blue.shade400, Colors.blue.shade700];
      icon = Icons.lightbulb_outline;
    } else {
      primaryColor = Colors.grey;
      gradient = [Colors.grey.shade400, Colors.grey.shade700];
      icon = Icons.lightbulb_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: primaryColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(value),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Durum Göstergesi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getStatusIcon(value), color: primaryColor, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    _getStatusText(value),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Kontrol Butonları
            Row(
              children: [
                Expanded(
                  child: _buildLedOptionButton(
                    context: context,
                    label: 'Kırmızı',
                    value: 'red',
                    currentValue: value,
                    color: Colors.red,
                    icon: Icons.lightbulb,
                    onPressed: () => onChanged('red'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLedOptionButton(
                    context: context,
                    label: 'Mavi',
                    value: 'blue',
                    currentValue: value,
                    color: Colors.blue,
                    icon: Icons.lightbulb_outline,
                    onPressed: () => onChanged('blue'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLedOptionButton(
                    context: context,
                    label: 'Kapalı',
                    value: 'off',
                    currentValue: value,
                    color: Colors.grey,
                    icon: Icons.power_off,
                    onPressed: () => onChanged('off'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedOptionButton({
    required BuildContext context,
    required String label,
    required String value,
    required String currentValue,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final isSelected = value == currentValue;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: [color.withOpacity(0.8), color])
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isSelected ? Colors.white : color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(String value) {
    switch (value) {
      case 'red':
        return 'Kırmızı';
      case 'blue':
        return 'Mavi';
      case 'off':
        return 'Kapalı';
      default:
        return 'Bilinmiyor';
    }
  }

  IconData _getStatusIcon(String value) {
    switch (value) {
      case 'red':
        return Icons.lightbulb;
      case 'blue':
        return Icons.lightbulb_outline;
      case 'off':
        return Icons.power_off;
      default:
        return Icons.help_outline;
    }
  }
}
