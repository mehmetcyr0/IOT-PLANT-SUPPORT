class Plant {
  final String id;
  final String name;
  final String icon;
  final String description;
  final List<GrowthPeriod>? periods;

  Plant({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.periods,
  });
}

class GrowthPeriod {
  final String id;
  final String name;
  final String led1;
  final String led2;
  final String mode;
  final String icon;

  GrowthPeriod({
    required this.id,
    required this.name,
    required this.led1,
    required this.led2,
    required this.mode,
    required this.icon,
  });
}

class PlantData {
  static final List<Plant> plants = [
    Plant(
      id: 'domates',
      name: 'Domates',
      icon: '🍅',
      description: 'Domates bitkisi için özel ışık ayarları',
      periods: [
        GrowthPeriod(
          id: 'vegetatif',
          name: 'Yaprak',
          led1: 'blue',
          led2: 'blue',
          mode: 'Vegetatif',
          icon: '🌱',
        ),
        GrowthPeriod(
          id: 'cicek',
          name: 'Çiçek',
          led1: 'red',
          led2: 'red',
          mode: 'Çiçek',
          icon: '🌸',
        ),
        GrowthPeriod(
          id: 'dinlenme',
          name: 'Dinlenme',
          led1: 'off',
          led2: 'off',
          mode: 'Kapalı',
          icon: '😴',
        ),
        GrowthPeriod(
          id: 'gecis',
          name: 'Geçiş',
          led1: 'blue',
          led2: 'red',
          mode: 'Deneysel',
          icon: '🔄',
        ),
      ],
    ),
    // Gelecekte daha fazla bitki eklenebilir
  ];
}
