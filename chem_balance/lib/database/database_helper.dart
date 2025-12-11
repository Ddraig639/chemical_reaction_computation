import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/element.dart';
import '../models/reaction.dart';
import '../models/history_item.dart';
import '../models/compound.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chem_balance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Increment version for migration
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add compounds table
      await db.execute('''
        CREATE TABLE compounds (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          formula TEXT NOT NULL,
          name TEXT NOT NULL,
          common_name TEXT,
          molar_mass REAL NOT NULL,
          category TEXT NOT NULL,
          state TEXT NOT NULL,
          description TEXT,
          uses TEXT
        )
      ''');
      await _populateCompounds(db);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Elements Table
    await db.execute('''
      CREATE TABLE elements (
        id $idType,
        symbol $textType,
        name $textType,
        atomic_number $intType,
        atomic_mass $realType,
        category $textType,
        group_number INTEGER,
        period_number INTEGER,
        oxidation_states TEXT,
        description TEXT
      )
    ''');

    // Compounds Table
    await db.execute('''
      CREATE TABLE compounds (
        id $idType,
        formula $textType,
        name $textType,
        common_name TEXT,
        molar_mass $realType,
        category $textType,
        state $textType,
        description TEXT,
        uses TEXT
      )
    ''');

    // Reactions Table
    await db.execute('''
      CREATE TABLE reactions (
        id $idType,
        reactants $textType,
        products $textType,
        balanced_equation $textType,
        reaction_type $textType,
        description TEXT,
        alternative_products TEXT
      )
    ''');

    // History Table
    await db.execute('''
      CREATE TABLE history (
        id $idType,
        original_equation $textType,
        balanced_equation $textType,
        reaction_type $textType,
        timestamp $textType,
        verification_data TEXT,
        is_saved INTEGER DEFAULT 0
      )
    ''');

    // Reaction Rules Table
    await db.execute('''
      CREATE TABLE reaction_rules (
        id $idType,
        rule_name $textType,
        pattern $textType,
        description TEXT
      )
    ''');

    // Populate initial data
    await _populateElements(db);
    await _populateCompounds(db);
    await _populateReactions(db);
    await _populateReactionRules(db);
  }

  Future<void> _populateElements(Database db) async {
    final elements = [
      // Period 1
      {
        'symbol': 'H',
        'name': 'Hydrogen',
        'atomic_number': 1,
        'atomic_mass': 1.008,
        'category': 'Nonmetal',
        'group_number': 1,
        'period_number': 1,
        'oxidation_states': '+1,-1',
        'description': 'Lightest element, highly reactive, used in fuel cells'
      },
      {
        'symbol': 'He',
        'name': 'Helium',
        'atomic_number': 2,
        'atomic_mass': 4.003,
        'category': 'Noble Gas',
        'group_number': 18,
        'period_number': 1,
        'oxidation_states': '0',
        'description': 'Inert noble gas, used in balloons and cooling'
      },

      // Period 2
      {
        'symbol': 'Li',
        'name': 'Lithium',
        'atomic_number': 3,
        'atomic_mass': 6.941,
        'category': 'Alkali Metal',
        'group_number': 1,
        'period_number': 2,
        'oxidation_states': '+1',
        'description': 'Soft reactive metal, used in batteries'
      },
      {
        'symbol': 'Be',
        'name': 'Beryllium',
        'atomic_number': 4,
        'atomic_mass': 9.012,
        'category': 'Alkaline Earth',
        'group_number': 2,
        'period_number': 2,
        'oxidation_states': '+2',
        'description': 'Hard brittle metal, used in aerospace'
      },
      {
        'symbol': 'B',
        'name': 'Boron',
        'atomic_number': 5,
        'atomic_mass': 10.811,
        'category': 'Metalloid',
        'group_number': 13,
        'period_number': 2,
        'oxidation_states': '+3',
        'description': 'Semiconductor, used in glass and ceramics'
      },
      {
        'symbol': 'C',
        'name': 'Carbon',
        'atomic_number': 6,
        'atomic_mass': 12.011,
        'category': 'Nonmetal',
        'group_number': 14,
        'period_number': 2,
        'oxidation_states': '+4,+2,-4',
        'description': 'Basis of organic chemistry, forms diamonds and graphite'
      },
      {
        'symbol': 'N',
        'name': 'Nitrogen',
        'atomic_number': 7,
        'atomic_mass': 14.007,
        'category': 'Nonmetal',
        'group_number': 15,
        'period_number': 2,
        'oxidation_states': '+5,+3,-3',
        'description': 'Major component of air (78%), essential for life'
      },
      {
        'symbol': 'O',
        'name': 'Oxygen',
        'atomic_number': 8,
        'atomic_mass': 15.999,
        'category': 'Nonmetal',
        'group_number': 16,
        'period_number': 2,
        'oxidation_states': '-2',
        'description': 'Essential for respiration, 21% of atmosphere'
      },
      {
        'symbol': 'F',
        'name': 'Fluorine',
        'atomic_number': 9,
        'atomic_mass': 18.998,
        'category': 'Halogen',
        'group_number': 17,
        'period_number': 2,
        'oxidation_states': '-1',
        'description': 'Most reactive element, used in toothpaste'
      },
      {
        'symbol': 'Ne',
        'name': 'Neon',
        'atomic_number': 10,
        'atomic_mass': 20.180,
        'category': 'Noble Gas',
        'group_number': 18,
        'period_number': 2,
        'oxidation_states': '0',
        'description': 'Inert gas, used in colorful signs and lights'
      },

      // Period 3
      {
        'symbol': 'Na',
        'name': 'Sodium',
        'atomic_number': 11,
        'atomic_mass': 22.990,
        'category': 'Alkali Metal',
        'group_number': 1,
        'period_number': 3,
        'oxidation_states': '+1',
        'description': 'Soft reactive metal, essential for body function'
      },
      {
        'symbol': 'Mg',
        'name': 'Magnesium',
        'atomic_number': 12,
        'atomic_mass': 24.305,
        'category': 'Alkaline Earth',
        'group_number': 2,
        'period_number': 3,
        'oxidation_states': '+2',
        'description': 'Light structural metal, burns with white flame'
      },
      {
        'symbol': 'Al',
        'name': 'Aluminum',
        'atomic_number': 13,
        'atomic_mass': 26.982,
        'category': 'Post-transition Metal',
        'group_number': 13,
        'period_number': 3,
        'oxidation_states': '+3',
        'description': 'Lightweight corrosion-resistant metal'
      },
      {
        'symbol': 'Si',
        'name': 'Silicon',
        'atomic_number': 14,
        'atomic_mass': 28.085,
        'category': 'Metalloid',
        'group_number': 14,
        'period_number': 3,
        'oxidation_states': '+4,-4',
        'description': 'Semiconductor material, basis of computer chips'
      },
      {
        'symbol': 'P',
        'name': 'Phosphorus',
        'atomic_number': 15,
        'atomic_mass': 30.974,
        'category': 'Nonmetal',
        'group_number': 15,
        'period_number': 3,
        'oxidation_states': '+5,+3,-3',
        'description': 'Essential for DNA and ATP, used in fertilizers'
      },
      {
        'symbol': 'S',
        'name': 'Sulfur',
        'atomic_number': 16,
        'atomic_mass': 32.065,
        'category': 'Nonmetal',
        'group_number': 16,
        'period_number': 3,
        'oxidation_states': '+6,+4,-2',
        'description': 'Yellow nonmetal, used in sulfuric acid production'
      },
      {
        'symbol': 'Cl',
        'name': 'Chlorine',
        'atomic_number': 17,
        'atomic_mass': 35.453,
        'category': 'Halogen',
        'group_number': 17,
        'period_number': 3,
        'oxidation_states': '+7,+5,+1,-1',
        'description': 'Reactive halogen gas, used in water purification'
      },
      {
        'symbol': 'Ar',
        'name': 'Argon',
        'atomic_number': 18,
        'atomic_mass': 39.948,
        'category': 'Noble Gas',
        'group_number': 18,
        'period_number': 3,
        'oxidation_states': '0',
        'description': 'Inert gas, about 1% of atmosphere'
      },

      // Period 4
      {
        'symbol': 'K',
        'name': 'Potassium',
        'atomic_number': 19,
        'atomic_mass': 39.098,
        'category': 'Alkali Metal',
        'group_number': 1,
        'period_number': 4,
        'oxidation_states': '+1',
        'description': 'Essential for nerve and muscle function'
      },
      {
        'symbol': 'Ca',
        'name': 'Calcium',
        'atomic_number': 20,
        'atomic_mass': 40.078,
        'category': 'Alkaline Earth',
        'group_number': 2,
        'period_number': 4,
        'oxidation_states': '+2',
        'description': 'Important for bones and teeth, reactive metal'
      },
      {
        'symbol': 'Sc',
        'name': 'Scandium',
        'atomic_number': 21,
        'atomic_mass': 44.956,
        'category': 'Transition Metal',
        'group_number': 3,
        'period_number': 4,
        'oxidation_states': '+3',
        'description': 'Rare earth metal, used in aerospace alloys'
      },
      {
        'symbol': 'Ti',
        'name': 'Titanium',
        'atomic_number': 22,
        'atomic_mass': 47.867,
        'category': 'Transition Metal',
        'group_number': 4,
        'period_number': 4,
        'oxidation_states': '+4,+3',
        'description': 'Strong lightweight metal, corrosion resistant'
      },
      {
        'symbol': 'V',
        'name': 'Vanadium',
        'atomic_number': 23,
        'atomic_mass': 50.942,
        'category': 'Transition Metal',
        'group_number': 5,
        'period_number': 4,
        'oxidation_states': '+5,+4,+3,+2',
        'description': 'Used in steel alloys for strength'
      },
      {
        'symbol': 'Cr',
        'name': 'Chromium',
        'atomic_number': 24,
        'atomic_mass': 51.996,
        'category': 'Transition Metal',
        'group_number': 6,
        'period_number': 4,
        'oxidation_states': '+6,+3,+2',
        'description': 'Hard metal, used in stainless steel'
      },
      {
        'symbol': 'Mn',
        'name': 'Manganese',
        'atomic_number': 25,
        'atomic_mass': 54.938,
        'category': 'Transition Metal',
        'group_number': 7,
        'period_number': 4,
        'oxidation_states': '+7,+4,+2',
        'description': 'Used in steel production and batteries'
      },
      {
        'symbol': 'Fe',
        'name': 'Iron',
        'atomic_number': 26,
        'atomic_mass': 55.845,
        'category': 'Transition Metal',
        'group_number': 8,
        'period_number': 4,
        'oxidation_states': '+3,+2',
        'description': 'Most common metal, used in construction'
      },
      {
        'symbol': 'Co',
        'name': 'Cobalt',
        'atomic_number': 27,
        'atomic_mass': 58.933,
        'category': 'Transition Metal',
        'group_number': 9,
        'period_number': 4,
        'oxidation_states': '+3,+2',
        'description': 'Magnetic metal, used in batteries and alloys'
      },
      {
        'symbol': 'Ni',
        'name': 'Nickel',
        'atomic_number': 28,
        'atomic_mass': 58.693,
        'category': 'Transition Metal',
        'group_number': 10,
        'period_number': 4,
        'oxidation_states': '+2',
        'description': 'Corrosion-resistant, used in coins and alloys'
      },
      {
        'symbol': 'Cu',
        'name': 'Copper',
        'atomic_number': 29,
        'atomic_mass': 63.546,
        'category': 'Transition Metal',
        'group_number': 11,
        'period_number': 4,
        'oxidation_states': '+2,+1',
        'description': 'Excellent conductor, used in wiring'
      },
      {
        'symbol': 'Zn',
        'name': 'Zinc',
        'atomic_number': 30,
        'atomic_mass': 65.38,
        'category': 'Transition Metal',
        'group_number': 12,
        'period_number': 4,
        'oxidation_states': '+2',
        'description': 'Corrosion-resistant coating, essential nutrient'
      },
      {
        'symbol': 'Ga',
        'name': 'Gallium',
        'atomic_number': 31,
        'atomic_mass': 69.723,
        'category': 'Post-transition Metal',
        'group_number': 13,
        'period_number': 4,
        'oxidation_states': '+3',
        'description': 'Melts just above room temperature'
      },
      {
        'symbol': 'Ge',
        'name': 'Germanium',
        'atomic_number': 32,
        'atomic_mass': 72.630,
        'category': 'Metalloid',
        'group_number': 14,
        'period_number': 4,
        'oxidation_states': '+4,+2',
        'description': 'Semiconductor used in electronics'
      },
      {
        'symbol': 'As',
        'name': 'Arsenic',
        'atomic_number': 33,
        'atomic_mass': 74.922,
        'category': 'Metalloid',
        'group_number': 15,
        'period_number': 4,
        'oxidation_states': '+5,+3,-3',
        'description': 'Toxic metalloid, used in semiconductors'
      },
      {
        'symbol': 'Se',
        'name': 'Selenium',
        'atomic_number': 34,
        'atomic_mass': 78.971,
        'category': 'Nonmetal',
        'group_number': 16,
        'period_number': 4,
        'oxidation_states': '+6,+4,-2',
        'description': 'Essential trace element, photoconductor'
      },
      {
        'symbol': 'Br',
        'name': 'Bromine',
        'atomic_number': 35,
        'atomic_mass': 79.904,
        'category': 'Halogen',
        'group_number': 17,
        'period_number': 4,
        'oxidation_states': '+5,+1,-1',
        'description': 'Red-brown liquid halogen, used in flame retardants'
      },
      {
        'symbol': 'Kr',
        'name': 'Krypton',
        'atomic_number': 36,
        'atomic_mass': 83.798,
        'category': 'Noble Gas',
        'group_number': 18,
        'period_number': 4,
        'oxidation_states': '0',
        'description': 'Noble gas used in high-performance lighting'
      },

      // Period 5 (Selected important elements)
      {
        'symbol': 'Rb',
        'name': 'Rubidium',
        'atomic_number': 37,
        'atomic_mass': 85.468,
        'category': 'Alkali Metal',
        'group_number': 1,
        'period_number': 5,
        'oxidation_states': '+1',
        'description': 'Highly reactive alkali metal'
      },
      {
        'symbol': 'Sr',
        'name': 'Strontium',
        'atomic_number': 38,
        'atomic_mass': 87.62,
        'category': 'Alkaline Earth',
        'group_number': 2,
        'period_number': 5,
        'oxidation_states': '+2',
        'description': 'Burns with red flame, used in fireworks'
      },
      {
        'symbol': 'Ag',
        'name': 'Silver',
        'atomic_number': 47,
        'atomic_mass': 107.868,
        'category': 'Transition Metal',
        'group_number': 11,
        'period_number': 5,
        'oxidation_states': '+1',
        'description': 'Precious metal, best electrical conductor'
      },
      {
        'symbol': 'Cd',
        'name': 'Cadmium',
        'atomic_number': 48,
        'atomic_mass': 112.414,
        'category': 'Transition Metal',
        'group_number': 12,
        'period_number': 5,
        'oxidation_states': '+2',
        'description': 'Toxic metal, used in batteries'
      },
      {
        'symbol': 'In',
        'name': 'Indium',
        'atomic_number': 49,
        'atomic_mass': 114.818,
        'category': 'Post-transition Metal',
        'group_number': 13,
        'period_number': 5,
        'oxidation_states': '+3',
        'description': 'Soft metal, used in touch screens'
      },
      {
        'symbol': 'Sn',
        'name': 'Tin',
        'atomic_number': 50,
        'atomic_mass': 118.710,
        'category': 'Post-transition Metal',
        'group_number': 14,
        'period_number': 5,
        'oxidation_states': '+4,+2',
        'description': 'Used in solder and tin cans'
      },
      {
        'symbol': 'Sb',
        'name': 'Antimony',
        'atomic_number': 51,
        'atomic_mass': 121.760,
        'category': 'Metalloid',
        'group_number': 15,
        'period_number': 5,
        'oxidation_states': '+5,+3,-3',
        'description': 'Used in flame retardants and alloys'
      },
      {
        'symbol': 'I',
        'name': 'Iodine',
        'atomic_number': 53,
        'atomic_mass': 126.904,
        'category': 'Halogen',
        'group_number': 17,
        'period_number': 5,
        'oxidation_states': '+7,+5,+1,-1',
        'description': 'Essential for thyroid function, antiseptic'
      },
      {
        'symbol': 'Xe',
        'name': 'Xenon',
        'atomic_number': 54,
        'atomic_mass': 131.293,
        'category': 'Noble Gas',
        'group_number': 18,
        'period_number': 5,
        'oxidation_states': '0',
        'description': 'Noble gas used in lighting and anesthesia'
      },

      // Period 6 (Selected important elements)
      {
        'symbol': 'Cs',
        'name': 'Cesium',
        'atomic_number': 55,
        'atomic_mass': 132.905,
        'category': 'Alkali Metal',
        'group_number': 1,
        'period_number': 6,
        'oxidation_states': '+1',
        'description': 'Most reactive alkali metal, used in atomic clocks'
      },
      {
        'symbol': 'Ba',
        'name': 'Barium',
        'atomic_number': 56,
        'atomic_mass': 137.327,
        'category': 'Alkaline Earth',
        'group_number': 2,
        'period_number': 6,
        'oxidation_states': '+2',
        'description': 'Used in medical imaging and fireworks'
      },
      {
        'symbol': 'W',
        'name': 'Tungsten',
        'atomic_number': 74,
        'atomic_mass': 183.84,
        'category': 'Transition Metal',
        'group_number': 6,
        'period_number': 6,
        'oxidation_states': '+6,+4',
        'description': 'Highest melting point, used in light bulb filaments'
      },
      {
        'symbol': 'Pt',
        'name': 'Platinum',
        'atomic_number': 78,
        'atomic_mass': 195.084,
        'category': 'Transition Metal',
        'group_number': 10,
        'period_number': 6,
        'oxidation_states': '+4,+2',
        'description': 'Precious metal catalyst, very unreactive'
      },
      {
        'symbol': 'Au',
        'name': 'Gold',
        'atomic_number': 79,
        'atomic_mass': 196.967,
        'category': 'Transition Metal',
        'group_number': 11,
        'period_number': 6,
        'oxidation_states': '+3,+1',
        'description': 'Precious metal, excellent conductor, malleable'
      },
      {
        'symbol': 'Hg',
        'name': 'Mercury',
        'atomic_number': 80,
        'atomic_mass': 200.592,
        'category': 'Transition Metal',
        'group_number': 12,
        'period_number': 6,
        'oxidation_states': '+2,+1',
        'description': 'Only liquid metal at room temperature, toxic'
      },
      {
        'symbol': 'Pb',
        'name': 'Lead',
        'atomic_number': 82,
        'atomic_mass': 207.2,
        'category': 'Post-transition Metal',
        'group_number': 14,
        'period_number': 6,
        'oxidation_states': '+4,+2',
        'description':
            'Dense toxic metal, used in batteries and radiation shielding'
      },
      {
        'symbol': 'Ra',
        'name': 'Radium',
        'atomic_number': 88,
        'atomic_mass': 226.0,
        'category': 'Alkaline Earth',
        'group_number': 2,
        'period_number': 7,
        'oxidation_states': '+2',
        'description': 'Highly radioactive, glows in the dark'
      },
      {
        'symbol': 'U',
        'name': 'Uranium',
        'atomic_number': 92,
        'atomic_mass': 238.029,
        'category': 'Actinide',
        'group_number': 0,
        'period_number': 7,
        'oxidation_states': '+6,+4,+3',
        'description': 'Radioactive, used in nuclear power and weapons'
      },
    ];

    for (var element in elements) {
      await db.insert('elements', element);
    }
  }

  Future<void> _populateCompounds(Database db) async {
    final compounds = [
      // Salts
      {
        'formula': 'NaCl',
        'name': 'Sodium Chloride',
        'common_name': 'Table Salt',
        'molar_mass': 58.44,
        'category': 'Salt',
        'state': 'Solid',
        'description': 'Common table salt, essential for human health',
        'uses': 'Food seasoning, food preservation, de-icing roads'
      },
      {
        'formula': 'KCl',
        'name': 'Potassium Chloride',
        'common_name': 'Potash',
        'molar_mass': 74.55,
        'category': 'Salt',
        'state': 'Solid',
        'description': 'Salt substitute and fertilizer component',
        'uses': 'Fertilizers, medical supplements, salt substitute'
      },
      {
        'formula': 'CaCO3',
        'name': 'Calcium Carbonate',
        'common_name': 'Limestone',
        'molar_mass': 100.09,
        'category': 'Salt',
        'state': 'Solid',
        'description': 'Found in rocks, shells, and pearls',
        'uses': 'Construction, antacid, dietary supplement'
      },

      // Acids
      {
        'formula': 'HCl',
        'name': 'Hydrochloric Acid',
        'common_name': 'Muriatic Acid',
        'molar_mass': 36.46,
        'category': 'Acid',
        'state': 'Aqueous',
        'description': 'Strong acid, naturally found in stomach',
        'uses': 'Cleaning, pH control, food processing'
      },
      {
        'formula': 'H2SO4',
        'name': 'Sulfuric Acid',
        'common_name': 'Battery Acid',
        'molar_mass': 98.08,
        'category': 'Acid',
        'state': 'Liquid',
        'description': 'Strong acid, most produced chemical worldwide',
        'uses': 'Fertilizer production, batteries, manufacturing'
      },
      {
        'formula': 'HNO3',
        'name': 'Nitric Acid',
        'common_name': 'Aqua Fortis',
        'molar_mass': 63.01,
        'category': 'Acid',
        'state': 'Aqueous',
        'description': 'Strong acid used in fertilizers',
        'uses': 'Fertilizers, explosives, cleaning'
      },
      {
        'formula': 'CH3COOH',
        'name': 'Acetic Acid',
        'common_name': 'Vinegar',
        'molar_mass': 60.05,
        'category': 'Acid',
        'state': 'Liquid',
        'description': 'Weak acid giving vinegar its sour taste',
        'uses': 'Food preservation, cooking, cleaning'
      },

      // Bases
      {
        'formula': 'NaOH',
        'name': 'Sodium Hydroxide',
        'common_name': 'Caustic Soda',
        'molar_mass': 40.00,
        'category': 'Base',
        'state': 'Solid',
        'description': 'Strong base used in many industries',
        'uses': 'Soap making, drain cleaner, paper production'
      },
      {
        'formula': 'KOH',
        'name': 'Potassium Hydroxide',
        'common_name': 'Caustic Potash',
        'molar_mass': 56.11,
        'category': 'Base',
        'state': 'Solid',
        'description': 'Strong base similar to sodium hydroxide',
        'uses': 'Batteries, soap making, food processing'
      },
      {
        'formula': 'Ca(OH)2',
        'name': 'Calcium Hydroxide',
        'common_name': 'Slaked Lime',
        'molar_mass': 74.09,
        'category': 'Base',
        'state': 'Solid',
        'description': 'Base used in construction and agriculture',
        'uses': 'Mortar, plaster, water treatment'
      },
      {
        'formula': 'NH3',
        'name': 'Ammonia',
        'common_name': 'Ammonia',
        'molar_mass': 17.03,
        'category': 'Base',
        'state': 'Gas',
        'description': 'Weak base with pungent odor',
        'uses': 'Fertilizers, cleaning products, refrigerant'
      },

      // Oxides
      {
        'formula': 'H2O',
        'name': 'Water',
        'common_name': 'Water',
        'molar_mass': 18.02,
        'category': 'Oxide',
        'state': 'Liquid',
        'description': 'Essential for all known forms of life',
        'uses': 'Drinking, agriculture, industrial processes'
      },
      {
        'formula': 'CO2',
        'name': 'Carbon Dioxide',
        'common_name': 'Dry Ice (solid)',
        'molar_mass': 44.01,
        'category': 'Oxide',
        'state': 'Gas',
        'description': 'Greenhouse gas, product of respiration',
        'uses': 'Carbonated drinks, fire extinguishers, refrigeration'
      },
      {
        'formula': 'Fe2O3',
        'name': 'Iron(III) Oxide',
        'common_name': 'Rust',
        'molar_mass': 159.69,
        'category': 'Oxide',
        'state': 'Solid',
        'description': 'Reddish-brown compound formed when iron corrodes',
        'uses': 'Pigments, polishing compounds, magnetic storage'
      },
      {
        'formula': 'Al2O3',
        'name': 'Aluminum Oxide',
        'common_name': 'Alumina',
        'molar_mass': 101.96,
        'category': 'Oxide',
        'state': 'Solid',
        'description': 'Very hard compound, found in rubies and sapphires',
        'uses': 'Abrasives, ceramics, aluminum production'
      },

      // Organic Compounds
      {
        'formula': 'C6H12O6',
        'name': 'Glucose',
        'common_name': 'Blood Sugar',
        'molar_mass': 180.16,
        'category': 'Organic',
        'state': 'Solid',
        'description': 'Simple sugar, primary energy source for cells',
        'uses': 'Food, medicine, fermentation'
      },
      {
        'formula': 'C2H5OH',
        'name': 'Ethanol',
        'common_name': 'Alcohol',
        'molar_mass': 46.07,
        'category': 'Organic',
        'state': 'Liquid',
        'description': 'Alcohol found in beverages',
        'uses': 'Beverages, fuel, solvent, disinfectant'
      },
      {
        'formula': 'CH4',
        'name': 'Methane',
        'common_name': 'Natural Gas',
        'molar_mass': 16.04,
        'category': 'Organic',
        'state': 'Gas',
        'description': 'Simplest hydrocarbon, main component of natural gas',
        'uses': 'Fuel, heating, electricity generation'
      },

      // Other Common Compounds
      {
        'formula': 'NaHCO3',
        'name': 'Sodium Bicarbonate',
        'common_name': 'Baking Soda',
        'molar_mass': 84.01,
        'category': 'Salt',
        'state': 'Solid',
        'description': 'Mild base used in cooking and cleaning',
        'uses': 'Baking, antacid, cleaning, fire extinguisher'
      },
      {
        'formula': 'CaSO4',
        'name': 'Calcium Sulfate',
        'common_name': 'Gypsum',
        'molar_mass': 136.14,
        'category': 'Salt',
        'state': 'Solid',
        'description': 'Common mineral used in construction',
        'uses': 'Plaster, drywall, cement'
      },
      {
        'formula': 'H2O2',
        'name': 'Hydrogen Peroxide',
        'common_name': 'Peroxide',
        'molar_mass': 34.01,
        'category': 'Oxide',
        'state': 'Liquid',
        'description': 'Mild antiseptic and bleaching agent',
        'uses': 'Disinfectant, bleaching, wound care'
      },
      {
        'formula': 'C12H22O11',
        'name': 'Sucrose',
        'common_name': 'Table Sugar',
        'molar_mass': 342.30,
        'category': 'Organic',
        'state': 'Solid',
        'description': 'Common sugar extracted from sugar cane or beet',
        'uses': 'Food sweetener, preservative'
      },
      {
        'formula': 'MgSO4',
        'name': 'Magnesium Sulfate',
        'common_name': 'Epsom Salt',
        'molar_mass': 120.37,
        'category': 'Salt',
        'state': 'Solid',
        'description': 'Salt used for therapeutic baths',
        'uses': 'Bath salts, laxative, fertilizer'
      },
    ];

    for (var compound in compounds) {
      await db.insert('compounds', compound);
    }
  }

  Future<void> _populateReactions(Database db) async {
    final reactions = [
      // Basic Synthesis Reactions
      {
        'reactants': 'H2+O2',
        'products': 'H2O',
        'balanced_equation': '2H2+O2->2H2O',
        'reaction_type': 'Synthesis',
        'description': 'Formation of water',
        'alternative_products': ''
      },
      {
        'reactants': 'N2+H2',
        'products': 'NH3',
        'balanced_equation': 'N2+3H2->2NH3',
        'reaction_type': 'Synthesis',
        'description': 'Haber process for ammonia',
        'alternative_products': ''
      },
      {
        'reactants': 'Na+Cl2',
        'products': 'NaCl',
        'balanced_equation': '2Na+Cl2->2NaCl',
        'reaction_type': 'Synthesis',
        'description': 'Formation of table salt',
        'alternative_products': ''
      },
      {
        'reactants': 'Mg+O2',
        'products': 'MgO',
        'balanced_equation': '2Mg+O2->2MgO',
        'reaction_type': 'Synthesis',
        'description': 'Burning magnesium',
        'alternative_products': ''
      },
      {
        'reactants': 'Fe+O2',
        'products': 'Fe2O3',
        'balanced_equation': '4Fe+3O2->2Fe2O3',
        'reaction_type': 'Synthesis',
        'description': 'Rusting of iron',
        'alternative_products': '2Fe+O2->2FeO'
      },
      {
        'reactants': 'Ca+O2',
        'products': 'CaO',
        'balanced_equation': '2Ca+O2->2CaO',
        'reaction_type': 'Synthesis',
        'description': 'Calcium oxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Al+O2',
        'products': 'Al2O3',
        'balanced_equation': '4Al+3O2->2Al2O3',
        'reaction_type': 'Synthesis',
        'description': 'Aluminum oxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'S+O2',
        'products': 'SO2',
        'balanced_equation': 'S+O2->SO2',
        'reaction_type': 'Synthesis',
        'description': 'Sulfur dioxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'P+O2',
        'products': 'P2O5',
        'balanced_equation': '4P+5O2->2P2O5',
        'reaction_type': 'Synthesis',
        'description': 'Phosphorus pentoxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'K+Cl2',
        'products': 'KCl',
        'balanced_equation': '2K+Cl2->2KCl',
        'reaction_type': 'Synthesis',
        'description': 'Potassium chloride formation',
        'alternative_products': ''
      },

      // Combustion Reactions
      {
        'reactants': 'CH4+O2',
        'products': 'CO2+H2O',
        'balanced_equation': 'CH4+2O2->CO2+2H2O',
        'reaction_type': 'Combustion',
        'description': 'Complete combustion of methane',
        'alternative_products': '2CH4+3O2->2CO+4H2O'
      },
      {
        'reactants': 'C3H8+O2',
        'products': 'CO2+H2O',
        'balanced_equation': 'C3H8+5O2->3CO2+4H2O',
        'reaction_type': 'Combustion',
        'description': 'Complete combustion of propane',
        'alternative_products': '2C3H8+7O2->6CO+8H2O'
      },
      {
        'reactants': 'C2H5OH+O2',
        'products': 'CO2+H2O',
        'balanced_equation': 'C2H5OH+3O2->2CO2+3H2O',
        'reaction_type': 'Combustion',
        'description': 'Complete combustion of ethanol',
        'alternative_products': ''
      },
      {
        'reactants': 'C2H6+O2',
        'products': 'CO2+H2O',
        'balanced_equation': '2C2H6+7O2->4CO2+6H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of ethane',
        'alternative_products': ''
      },
      {
        'reactants': 'C4H10+O2',
        'products': 'CO2+H2O',
        'balanced_equation': '2C4H10+13O2->8CO2+10H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of butane',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H12O6+O2',
        'products': 'CO2+H2O',
        'balanced_equation': 'C6H12O6+6O2->6CO2+6H2O',
        'reaction_type': 'Combustion',
        'description': 'Cellular respiration',
        'alternative_products': ''
      },

      // Single Replacement Reactions
      {
        'reactants': 'Zn+HCl',
        'products': 'ZnCl2+H2',
        'balanced_equation': 'Zn+2HCl->ZnCl2+H2',
        'reaction_type': 'Single Replacement',
        'description': 'Zinc displacing hydrogen',
        'alternative_products': ''
      },
      {
        'reactants': 'Al+HCl',
        'products': 'AlCl3+H2',
        'balanced_equation': '2Al+6HCl->2AlCl3+3H2',
        'reaction_type': 'Single Replacement',
        'description': 'Aluminum displacing hydrogen',
        'alternative_products': ''
      },
      {
        'reactants': 'Fe+HCl',
        'products': 'FeCl3+H2',
        'balanced_equation': '2Fe+6HCl->2FeCl3+3H2',
        'reaction_type': 'Single Replacement',
        'description': 'Iron(III) formation',
        'alternative_products': 'Fe+2HCl->FeCl2+H2'
      },
      {
        'reactants': 'Mg+HCl',
        'products': 'MgCl2+H2',
        'balanced_equation': 'Mg+2HCl->MgCl2+H2',
        'reaction_type': 'Single Replacement',
        'description': 'Magnesium displacing hydrogen',
        'alternative_products': ''
      },
      {
        'reactants': 'Ca+H2O',
        'products': 'Ca(OH)2+H2',
        'balanced_equation': 'Ca+2H2O->Ca(OH)2+H2',
        'reaction_type': 'Single Replacement',
        'description': 'Calcium reacting with water',
        'alternative_products': ''
      },
      {
        'reactants': 'Cu+AgNO3',
        'products': 'Cu(NO3)2+Ag',
        'balanced_equation': 'Cu+2AgNO3->Cu(NO3)2+2Ag',
        'reaction_type': 'Single Replacement',
        'description': 'Copper displacing silver',
        'alternative_products': ''
      },
      {
        'reactants': 'Zn+CuSO4',
        'products': 'ZnSO4+Cu',
        'balanced_equation': 'Zn+CuSO4->ZnSO4+Cu',
        'reaction_type': 'Single Replacement',
        'description': 'Zinc displacing copper',
        'alternative_products': ''
      },
      {
        'reactants': 'Fe+CuSO4',
        'products': 'FeSO4+Cu',
        'balanced_equation': 'Fe+CuSO4->FeSO4+Cu',
        'reaction_type': 'Single Replacement',
        'description': 'Iron displacing copper',
        'alternative_products': ''
      },
      {
        'reactants': 'Cl2+NaBr',
        'products': 'NaCl+Br2',
        'balanced_equation': 'Cl2+2NaBr->2NaCl+Br2',
        'reaction_type': 'Single Replacement',
        'description': 'Halogen displacement',
        'alternative_products': ''
      },

      // Double Replacement Reactions
      {
        'reactants': 'NaOH+HCl',
        'products': 'NaCl+H2O',
        'balanced_equation': 'NaOH+HCl->NaCl+H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Neutralization reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'AgNO3+NaCl',
        'products': 'AgCl+NaNO3',
        'balanced_equation': 'AgNO3+NaCl->AgCl+NaNO3',
        'reaction_type': 'Double Replacement',
        'description': 'Precipitation reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'H2SO4+NaOH',
        'products': 'Na2SO4+H2O',
        'balanced_equation': 'H2SO4+2NaOH->Na2SO4+2H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Acid-base neutralization',
        'alternative_products': ''
      },
      {
        'reactants': 'BaCl2+Na2SO4',
        'products': 'BaSO4+NaCl',
        'balanced_equation': 'BaCl2+Na2SO4->BaSO4+2NaCl',
        'reaction_type': 'Double Replacement',
        'description': 'Precipitation of barium sulfate',
        'alternative_products': ''
      },
      {
        'reactants': 'Pb(NO3)2+KI',
        'products': 'PbI2+KNO3',
        'balanced_equation': 'Pb(NO3)2+2KI->PbI2+2KNO3',
        'reaction_type': 'Double Replacement',
        'description': 'Yellow precipitate formation',
        'alternative_products': ''
      },
      {
        'reactants': 'CaCl2+Na2CO3',
        'products': 'CaCO3+NaCl',
        'balanced_equation': 'CaCl2+Na2CO3->CaCO3+2NaCl',
        'reaction_type': 'Double Replacement',
        'description': 'Calcium carbonate precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'HNO3+KOH',
        'products': 'KNO3+H2O',
        'balanced_equation': 'HNO3+KOH->KNO3+H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Neutralization reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'H3PO4+NaOH',
        'products': 'Na3PO4+H2O',
        'balanced_equation': 'H3PO4+3NaOH->Na3PO4+3H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Phosphoric acid neutralization',
        'alternative_products': ''
      },

      // Decomposition Reactions
      {
        'reactants': 'CaCO3',
        'products': 'CaO+CO2',
        'balanced_equation': 'CaCO3->CaO+CO2',
        'reaction_type': 'Decomposition',
        'description': 'Thermal decomposition of limestone',
        'alternative_products': ''
      },
      {
        'reactants': 'H2O',
        'products': 'H2+O2',
        'balanced_equation': '2H2O->2H2+O2',
        'reaction_type': 'Decomposition',
        'description': 'Electrolysis of water',
        'alternative_products': ''
      },
      {
        'reactants': 'KClO3',
        'products': 'KCl+O2',
        'balanced_equation': '2KClO3->2KCl+3O2',
        'reaction_type': 'Decomposition',
        'description': 'Decomposition of potassium chlorate',
        'alternative_products': ''
      },
      {
        'reactants': 'H2O2',
        'products': 'H2O+O2',
        'balanced_equation': '2H2O2->2H2O+O2',
        'reaction_type': 'Decomposition',
        'description': 'Hydrogen peroxide decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'NH4NO3',
        'products': 'N2O+H2O',
        'balanced_equation': 'NH4NO3->N2O+2H2O',
        'reaction_type': 'Decomposition',
        'description': 'Ammonium nitrate decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'NaHCO3',
        'products': 'Na2CO3+H2O+CO2',
        'balanced_equation': '2NaHCO3->Na2CO3+H2O+CO2',
        'reaction_type': 'Decomposition',
        'description': 'Baking soda decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'Mg(OH)2',
        'products': 'MgO+H2O',
        'balanced_equation': 'Mg(OH)2->MgO+H2O',
        'reaction_type': 'Decomposition',
        'description': 'Magnesium hydroxide decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'Cu(OH)2',
        'products': 'CuO+H2O',
        'balanced_equation': 'Cu(OH)2->CuO+H2O',
        'reaction_type': 'Decomposition',
        'description': 'Copper hydroxide decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'HgO',
        'products': 'Hg+O2',
        'balanced_equation': '2HgO->2Hg+O2',
        'reaction_type': 'Decomposition',
        'description': 'Mercury oxide decomposition',
        'alternative_products': ''
      },

      // Additional Important Reactions
      {
        'reactants': 'NH3+O2',
        'products': 'NO+H2O',
        'balanced_equation': '4NH3+5O2->4NO+6H2O',
        'reaction_type': 'Combustion',
        'description': 'Ostwald process',
        'alternative_products': ''
      },
      {
        'reactants': 'SO2+O2',
        'products': 'SO3',
        'balanced_equation': '2SO2+O2->2SO3',
        'reaction_type': 'Synthesis',
        'description': 'Sulfur trioxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'N2+O2',
        'products': 'NO',
        'balanced_equation': 'N2+O2->2NO',
        'reaction_type': 'Synthesis',
        'description': 'Nitrogen monoxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'CO+O2',
        'products': 'CO2',
        'balanced_equation': '2CO+O2->2CO2',
        'reaction_type': 'Combustion',
        'description': 'Carbon monoxide combustion',
        'alternative_products': ''
      },
      {
        'reactants': 'C+O2',
        'products': 'CO2',
        'balanced_equation': 'C+O2->CO2',
        'reaction_type': 'Combustion',
        'description': 'Carbon combustion (complete)',
        'alternative_products': '2C+O2->2CO'
      },
      {
        'reactants': 'Fe2O3+C',
        'products': 'Fe+CO2',
        'balanced_equation': '2Fe2O3+3C->4Fe+3CO2',
        'reaction_type': 'Single Replacement',
        'description': 'Iron smelting',
        'alternative_products': ''
      },
      {
        'reactants': 'CuO+H2',
        'products': 'Cu+H2O',
        'balanced_equation': 'CuO+H2->Cu+H2O',
        'reaction_type': 'Single Replacement',
        'description': 'Copper oxide reduction',
        'alternative_products': ''
      },
      {
        'reactants': 'Na2CO3+HCl',
        'products': 'NaCl+H2O+CO2',
        'balanced_equation': 'Na2CO3+2HCl->2NaCl+H2O+CO2',
        'reaction_type': 'Double Replacement',
        'description': 'Carbonate and acid reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'CaO+H2O',
        'products': 'Ca(OH)2',
        'balanced_equation': 'CaO+H2O->Ca(OH)2',
        'reaction_type': 'Synthesis',
        'description': 'Slaking of lime',
        'alternative_products': ''
      },
      {
        'reactants': 'P4+O2',
        'products': 'P4O10',
        'balanced_equation': 'P4+5O2->P4O10',
        'reaction_type': 'Synthesis',
        'description': 'Phosphorus combustion',
        'alternative_products': ''
      },
      {
        'reactants': 'Li+H2O',
        'products': 'LiOH+H2',
        'balanced_equation': '2Li+2H2O->2LiOH+H2',
        'reaction_type': 'Single Replacement',
        'description': 'Lithium reacting with water',
        'alternative_products': ''
      },
      {
        'reactants': 'Na+H2O',
        'products': 'NaOH+H2',
        'balanced_equation': '2Na+2H2O->2NaOH+H2',
        'reaction_type': 'Single Replacement',
        'description': 'Sodium reacting with water',
        'alternative_products': ''
      },
      {
        'reactants': 'K+H2O',
        'products': 'KOH+H2',
        'balanced_equation': '2K+2H2O->2KOH+H2',
        'reaction_type': 'Single Replacement',
        'description': 'Potassium reacting with water',
        'alternative_products': ''
      },
      {
        'reactants': 'Mg+N2',
        'products': 'Mg3N2',
        'balanced_equation': '3Mg+N2->Mg3N2',
        'reaction_type': 'Synthesis',
        'description': 'Magnesium nitride formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Al+Br2',
        'products': 'AlBr3',
        'balanced_equation': '2Al+3Br2->2AlBr3',
        'reaction_type': 'Synthesis',
        'description': 'Aluminum bromide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'H2+Cl2',
        'products': 'HCl',
        'balanced_equation': 'H2+Cl2->2HCl',
        'reaction_type': 'Synthesis',
        'description': 'Hydrogen chloride formation',
        'alternative_products': ''
      },
      {
        'reactants': 'CaCO3+HCl',
        'products': 'CaCl2+H2O+CO2',
        'balanced_equation': 'CaCO3+2HCl->CaCl2+H2O+CO2',
        'reaction_type': 'Double Replacement',
        'description': 'Limestone and acid reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'Fe+S',
        'products': 'FeS',
        'balanced_equation': 'Fe+S->FeS',
        'reaction_type': 'Synthesis',
        'description': 'Iron sulfide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Al+Fe2O3',
        'products': 'Al2O3+Fe',
        'balanced_equation': '2Al+Fe2O3->Al2O3+2Fe',
        'reaction_type': 'Single Replacement',
        'description': 'Thermite reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'NH4Cl+Ca(OH)2',
        'products': 'CaCl2+NH3+H2O',
        'balanced_equation': '2NH4Cl+Ca(OH)2->CaCl2+2NH3+2H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Ammonia gas preparation',
        'alternative_products': ''
      },
      {
        'reactants': 'Ba(OH)2+H2SO4',
        'products': 'BaSO4+H2O',
        'balanced_equation': 'Ba(OH)2+H2SO4->BaSO4+2H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Neutralization with precipitation',
        'alternative_products': ''
      },
      // Redox and Metal Reactions
      {
        'reactants': 'Mg+HNO3',
        'products': 'Mg(NO3)2+H2',
        'balanced_equation': 'Mg+2HNO3->Mg(NO3)2+H2',
        'reaction_type': 'Single Replacement',
        'description': 'Magnesium with nitric acid',
        'alternative_products': ''
      },
      {
        'reactants': 'Al+H2SO4',
        'products': 'Al2(SO4)3+H2',
        'balanced_equation': '2Al+3H2SO4->Al2(SO4)3+3H2',
        'reaction_type': 'Single Replacement',
        'description': 'Aluminum with sulfuric acid',
        'alternative_products': ''
      },
      {
        'reactants': 'Zn+H2SO4',
        'products': 'ZnSO4+H2',
        'balanced_equation': 'Zn+H2SO4->ZnSO4+H2',
        'reaction_type': 'Single Replacement',
        'description': 'Zinc with sulfuric acid',
        'alternative_products': ''
      },
      {
        'reactants': 'Fe+H2SO4',
        'products': 'FeSO4+H2',
        'balanced_equation': 'Fe+H2SO4->FeSO4+H2',
        'reaction_type': 'Single Replacement',
        'description': 'Iron with sulfuric acid',
        'alternative_products': ''
      },
      {
        'reactants': 'Mg+AgNO3',
        'products': 'Mg(NO3)2+Ag',
        'balanced_equation': 'Mg+2AgNO3->Mg(NO3)2+2Ag',
        'reaction_type': 'Single Replacement',
        'description': 'Magnesium displacing silver',
        'alternative_products': ''
      },
      {
        'reactants': 'Al+CuSO4',
        'products': 'Al2(SO4)3+Cu',
        'balanced_equation': '2Al+3CuSO4->Al2(SO4)3+3Cu',
        'reaction_type': 'Single Replacement',
        'description': 'Aluminum displacing copper',
        'alternative_products': ''
      },
      {
        'reactants': 'Zn+AgNO3',
        'products': 'Zn(NO3)2+Ag',
        'balanced_equation': 'Zn+2AgNO3->Zn(NO3)2+2Ag',
        'reaction_type': 'Single Replacement',
        'description': 'Zinc displacing silver',
        'alternative_products': ''
      },
      {
        'reactants': 'Cu+HNO3',
        'products': 'Cu(NO3)2+NO+H2O',
        'balanced_equation': '3Cu+8HNO3->3Cu(NO3)2+2NO+4H2O',
        'reaction_type': 'Single Replacement',
        'description': 'Copper with dilute nitric acid',
        'alternative_products': 'Cu+4HNO3->Cu(NO3)2+2NO2+2H2O'
      },
      {
        'reactants': 'Br2+KI',
        'products': 'KBr+I2',
        'balanced_equation': 'Br2+2KI->2KBr+I2',
        'reaction_type': 'Single Replacement',
        'description': 'Bromine displacing iodine',
        'alternative_products': ''
      },
      {
        'reactants': 'F2+NaCl',
        'products': 'NaF+Cl2',
        'balanced_equation': 'F2+2NaCl->2NaF+Cl2',
        'reaction_type': 'Single Replacement',
        'description': 'Fluorine displacing chlorine',
        'alternative_products': ''
      },
      {
        'reactants': 'Cl2+KI',
        'products': 'KCl+I2',
        'balanced_equation': 'Cl2+2KI->2KCl+I2',
        'reaction_type': 'Single Replacement',
        'description': 'Chlorine displacing iodine',
        'alternative_products': ''
      },

// More Combustion Reactions
      {
        'reactants': 'C5H12+O2',
        'products': 'CO2+H2O',
        'balanced_equation': 'C5H12+8O2->5CO2+6H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of pentane',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H14+O2',
        'products': 'CO2+H2O',
        'balanced_equation': '2C6H14+19O2->12CO2+14H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of hexane',
        'alternative_products': ''
      },
      {
        'reactants': 'C7H16+O2',
        'products': 'CO2+H2O',
        'balanced_equation': 'C7H16+11O2->7CO2+8H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of heptane',
        'alternative_products': ''
      },
      {
        'reactants': 'C8H18+O2',
        'products': 'CO2+H2O',
        'balanced_equation': '2C8H18+25O2->16CO2+18H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of octane',
        'alternative_products': ''
      },
      {
        'reactants': 'CH3OH+O2',
        'products': 'CO2+H2O',
        'balanced_equation': '2CH3OH+3O2->2CO2+4H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of methanol',
        'alternative_products': ''
      },
      {
        'reactants': 'C3H6+O2',
        'products': 'CO2+H2O',
        'balanced_equation': '2C3H6+9O2->6CO2+6H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of propene',
        'alternative_products': ''
      },
      {
        'reactants': 'C2H4+O2',
        'products': 'CO2+H2O',
        'balanced_equation': 'C2H4+3O2->2CO2+2H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of ethene',
        'alternative_products': ''
      },
      {
        'reactants': 'C2H2+O2',
        'products': 'CO2+H2O',
        'balanced_equation': '2C2H2+5O2->4CO2+2H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of acetylene',
        'alternative_products': ''
      },
      {
        'reactants': 'C12H22O11+O2',
        'products': 'CO2+H2O',
        'balanced_equation': 'C12H22O11+12O2->12CO2+11H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of sucrose',
        'alternative_products': ''
      },
      {
        'reactants': 'H2+O2',
        'products': 'H2O',
        'balanced_equation': '2H2+O2->2H2O',
        'reaction_type': 'Combustion',
        'description': 'Combustion of hydrogen',
        'alternative_products': ''
      },

// More Synthesis Reactions
      {
        'reactants': 'SO3+H2O',
        'products': 'H2SO4',
        'balanced_equation': 'SO3+H2O->H2SO4',
        'reaction_type': 'Synthesis',
        'description': 'Sulfuric acid formation',
        'alternative_products': ''
      },
      {
        'reactants': 'CO2+H2O',
        'products': 'H2CO3',
        'balanced_equation': 'CO2+H2O->H2CO3',
        'reaction_type': 'Synthesis',
        'description': 'Carbonic acid formation',
        'alternative_products': ''
      },
      {
        'reactants': 'NO2+H2O',
        'products': 'HNO3+HNO2',
        'balanced_equation': '2NO2+H2O->HNO3+HNO2',
        'reaction_type': 'Synthesis',
        'description': 'Nitric acid formation',
        'alternative_products': ''
      },
      {
        'reactants': 'P2O5+H2O',
        'products': 'H3PO4',
        'balanced_equation': 'P2O5+3H2O->2H3PO4',
        'reaction_type': 'Synthesis',
        'description': 'Phosphoric acid formation',
        'alternative_products': ''
      },
      {
        'reactants': 'N2O5+H2O',
        'products': 'HNO3',
        'balanced_equation': 'N2O5+H2O->2HNO3',
        'reaction_type': 'Synthesis',
        'description': 'Nitric acid from nitrogen pentoxide',
        'alternative_products': ''
      },
      {
        'reactants': 'BaO+H2O',
        'products': 'Ba(OH)2',
        'balanced_equation': 'BaO+H2O->Ba(OH)2',
        'reaction_type': 'Synthesis',
        'description': 'Barium hydroxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Na2O+H2O',
        'products': 'NaOH',
        'balanced_equation': 'Na2O+H2O->2NaOH',
        'reaction_type': 'Synthesis',
        'description': 'Sodium hydroxide from oxide',
        'alternative_products': ''
      },
      {
        'reactants': 'K2O+H2O',
        'products': 'KOH',
        'balanced_equation': 'K2O+H2O->2KOH',
        'reaction_type': 'Synthesis',
        'description': 'Potassium hydroxide from oxide',
        'alternative_products': ''
      },
      {
        'reactants': 'CaO+CO2',
        'products': 'CaCO3',
        'balanced_equation': 'CaO+CO2->CaCO3',
        'reaction_type': 'Synthesis',
        'description': 'Calcium carbonate formation',
        'alternative_products': ''
      },
      {
        'reactants': 'MgO+CO2',
        'products': 'MgCO3',
        'balanced_equation': 'MgO+CO2->MgCO3',
        'reaction_type': 'Synthesis',
        'description': 'Magnesium carbonate formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Fe+Cl2',
        'products': 'FeCl3',
        'balanced_equation': '2Fe+3Cl2->2FeCl3',
        'reaction_type': 'Synthesis',
        'description': 'Iron(III) chloride formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Cu+S',
        'products': 'CuS',
        'balanced_equation': 'Cu+S->CuS',
        'reaction_type': 'Synthesis',
        'description': 'Copper sulfide formation',
        'alternative_products': '2Cu+S->Cu2S'
      },
      {
        'reactants': 'Zn+S',
        'products': 'ZnS',
        'balanced_equation': 'Zn+S->ZnS',
        'reaction_type': 'Synthesis',
        'description': 'Zinc sulfide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Ca+Cl2',
        'products': 'CaCl2',
        'balanced_equation': 'Ca+Cl2->CaCl2',
        'reaction_type': 'Synthesis',
        'description': 'Calcium chloride formation',
        'alternative_products': ''
      },
      {
        'reactants': 'H2+S',
        'products': 'H2S',
        'balanced_equation': 'H2+S->H2S',
        'reaction_type': 'Synthesis',
        'description': 'Hydrogen sulfide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'H2+Br2',
        'products': 'HBr',
        'balanced_equation': 'H2+Br2->2HBr',
        'reaction_type': 'Synthesis',
        'description': 'Hydrogen bromide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'H2+I2',
        'products': 'HI',
        'balanced_equation': 'H2+I2->2HI',
        'reaction_type': 'Synthesis',
        'description': 'Hydrogen iodide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Li+N2',
        'products': 'Li3N',
        'balanced_equation': '6Li+N2->2Li3N',
        'reaction_type': 'Synthesis',
        'description': 'Lithium nitride formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Ca+N2',
        'products': 'Ca3N2',
        'balanced_equation': '3Ca+N2->Ca3N2',
        'reaction_type': 'Synthesis',
        'description': 'Calcium nitride formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Al+S',
        'products': 'Al2S3',
        'balanced_equation': '2Al+3S->Al2S3',
        'reaction_type': 'Synthesis',
        'description': 'Aluminum sulfide formation',
        'alternative_products': ''
      },

// More Decomposition Reactions
      {
        'reactants': 'H2CO3',
        'products': 'H2O+CO2',
        'balanced_equation': 'H2CO3->H2O+CO2',
        'reaction_type': 'Decomposition',
        'description': 'Carbonic acid decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'MgCO3',
        'products': 'MgO+CO2',
        'balanced_equation': 'MgCO3->MgO+CO2',
        'reaction_type': 'Decomposition',
        'description': 'Magnesium carbonate decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'ZnCO3',
        'products': 'ZnO+CO2',
        'balanced_equation': 'ZnCO3->ZnO+CO2',
        'reaction_type': 'Decomposition',
        'description': 'Zinc carbonate decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'FeCO3',
        'products': 'FeO+CO2',
        'balanced_equation': 'FeCO3->FeO+CO2',
        'reaction_type': 'Decomposition',
        'description': 'Iron carbonate decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'Ca(OH)2',
        'products': 'CaO+H2O',
        'balanced_equation': 'Ca(OH)2->CaO+H2O',
        'reaction_type': 'Decomposition',
        'description': 'Calcium hydroxide decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'Fe(OH)3',
        'products': 'Fe2O3+H2O',
        'balanced_equation': '2Fe(OH)3->Fe2O3+3H2O',
        'reaction_type': 'Decomposition',
        'description': 'Iron(III) hydroxide decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'Al(OH)3',
        'products': 'Al2O3+H2O',
        'balanced_equation': '2Al(OH)3->Al2O3+3H2O',
        'reaction_type': 'Decomposition',
        'description': 'Aluminum hydroxide decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'Zn(OH)2',
        'products': 'ZnO+H2O',
        'balanced_equation': 'Zn(OH)2->ZnO+H2O',
        'reaction_type': 'Decomposition',
        'description': 'Zinc hydroxide decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'KClO4',
        'products': 'KCl+O2',
        'balanced_equation': 'KClO4->KCl+2O2',
        'reaction_type': 'Decomposition',
        'description': 'Potassium perchlorate decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'NaClO3',
        'products': 'NaCl+O2',
        'balanced_equation': '2NaClO3->2NaCl+3O2',
        'reaction_type': 'Decomposition',
        'description': 'Sodium chlorate decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'Ag2O',
        'products': 'Ag+O2',
        'balanced_equation': '2Ag2O->4Ag+O2',
        'reaction_type': 'Decomposition',
        'description': 'Silver oxide decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'PbO2',
        'products': 'PbO+O2',
        'balanced_equation': '2PbO2->2PbO+O2',
        'reaction_type': 'Decomposition',
        'description': 'Lead dioxide decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'CuCO3',
        'products': 'CuO+CO2',
        'balanced_equation': 'CuCO3->CuO+CO2',
        'reaction_type': 'Decomposition',
        'description': 'Copper carbonate decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'BaCO3',
        'products': 'BaO+CO2',
        'balanced_equation': 'BaCO3->BaO+CO2',
        'reaction_type': 'Decomposition',
        'description': 'Barium carbonate decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'NH4Cl',
        'products': 'NH3+HCl',
        'balanced_equation': 'NH4Cl->NH3+HCl',
        'reaction_type': 'Decomposition',
        'description': 'Ammonium chloride sublimation',
        'alternative_products': ''
      },
      {
        'reactants': 'NH4OH',
        'products': 'NH3+H2O',
        'balanced_equation': 'NH4OH->NH3+H2O',
        'reaction_type': 'Decomposition',
        'description': 'Ammonium hydroxide decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'H2SO3',
        'products': 'H2O+SO2',
        'balanced_equation': 'H2SO3->H2O+SO2',
        'reaction_type': 'Decomposition',
        'description': 'Sulfurous acid decomposition',
        'alternative_products': ''
      },
      {
        'reactants': 'CaSO4.2H2O',
        'products': 'CaSO4+H2O',
        'balanced_equation': 'CaSO4.2H2O->CaSO4+2H2O',
        'reaction_type': 'Decomposition',
        'description': 'Gypsum dehydration',
        'alternative_products': ''
      },

// More Double Replacement Reactions
      {
        'reactants': 'KOH+HNO3',
        'products': 'KNO3+H2O',
        'balanced_equation': 'KOH+HNO3->KNO3+H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Potassium hydroxide neutralization',
        'alternative_products': ''
      },
      {
        'reactants': 'Ca(OH)2+HCl',
        'products': 'CaCl2+H2O',
        'balanced_equation': 'Ca(OH)2+2HCl->CaCl2+2H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Calcium hydroxide neutralization',
        'alternative_products': ''
      },
      {
        'reactants': 'Mg(OH)2+HCl',
        'products': 'MgCl2+H2O',
        'balanced_equation': 'Mg(OH)2+2HCl->MgCl2+2H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Magnesium hydroxide neutralization',
        'alternative_products': ''
      },
      {
        'reactants': 'Al(OH)3+HCl',
        'products': 'AlCl3+H2O',
        'balanced_equation': 'Al(OH)3+3HCl->AlCl3+3H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Aluminum hydroxide neutralization',
        'alternative_products': ''
      },
      {
        'reactants': 'NH4OH+HCl',
        'products': 'NH4Cl+H2O',
        'balanced_equation': 'NH4OH+HCl->NH4Cl+H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Ammonium hydroxide neutralization',
        'alternative_products': ''
      },
      {
        'reactants': 'FeCl3+NaOH',
        'products': 'Fe(OH)3+NaCl',
        'balanced_equation': 'FeCl3+3NaOH->Fe(OH)3+3NaCl',
        'reaction_type': 'Double Replacement',
        'description': 'Iron(III) hydroxide precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'CuSO4+NaOH',
        'products': 'Cu(OH)2+Na2SO4',
        'balanced_equation': 'CuSO4+2NaOH->Cu(OH)2+Na2SO4',
        'reaction_type': 'Double Replacement',
        'description': 'Copper(II) hydroxide precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'ZnSO4+NaOH',
        'products': 'Zn(OH)2+Na2SO4',
        'balanced_equation': 'ZnSO4+2NaOH->Zn(OH)2+Na2SO4',
        'reaction_type': 'Double Replacement',
        'description': 'Zinc hydroxide precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'Al2(SO4)3+NaOH',
        'products': 'Al(OH)3+Na2SO4',
        'balanced_equation': 'Al2(SO4)3+6NaOH->2Al(OH)3+3Na2SO4',
        'reaction_type': 'Double Replacement',
        'description': 'Aluminum hydroxide precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'FeSO4+NaOH',
        'products': 'Fe(OH)2+Na2SO4',
        'balanced_equation': 'FeSO4+2NaOH->Fe(OH)2+Na2SO4',
        'reaction_type': 'Double Replacement',
        'description': 'Iron(II) hydroxide precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'Ca(NO3)2+Na2CO3',
        'products': 'CaCO3+NaNO3',
        'balanced_equation': 'Ca(NO3)2+Na2CO3->CaCO3+2NaNO3',
        'reaction_type': 'Double Replacement',
        'description': 'Calcium carbonate precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'MgSO4+Na2CO3',
        'products': 'MgCO3+Na2SO4',
        'balanced_equation': 'MgSO4+Na2CO3->MgCO3+Na2SO4',
        'reaction_type': 'Double Replacement',
        'description': 'Magnesium carbonate precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'BaCl2+K2SO4',
        'products': 'BaSO4+KCl',
        'balanced_equation': 'BaCl2+K2SO4->BaSO4+2KCl',
        'reaction_type': 'Double Replacement',
        'description': 'Barium sulfate precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'AgNO3+KCl',
        'products': 'AgCl+KNO3',
        'balanced_equation': 'AgNO3+KCl->AgCl+KNO3',
        'reaction_type': 'Double Replacement',
        'description': 'Silver chloride precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'AgNO3+K2CrO4',
        'products': 'Ag2CrO4+KNO3',
        'balanced_equation': '2AgNO3+K2CrO4->Ag2CrO4+2KNO3',
        'reaction_type': 'Double Replacement',
        'description': 'Silver chromate precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'Pb(NO3)2+NaCl',
        'products': 'PbCl2+NaNO3',
        'balanced_equation': 'Pb(NO3)2+2NaCl->PbCl2+2NaNO3',
        'reaction_type': 'Double Replacement',
        'description': 'Lead chloride precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'Pb(NO3)2+Na2SO4',
        'products': 'PbSO4+NaNO3',
        'balanced_equation': 'Pb(NO3)2+Na2SO4->PbSO4+2NaNO3',
        'reaction_type': 'Double Replacement',
        'description': 'Lead sulfate precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'CuCl2+Na2S',
        'products': 'CuS+NaCl',
        'balanced_equation': 'CuCl2+Na2S->CuS+2NaCl',
        'reaction_type': 'Double Replacement',
        'description': 'Copper sulfide precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'FeCl3+Na2S',
        'products': 'Fe2S3+NaCl',
        'balanced_equation': '2FeCl3+3Na2S->Fe2S3+6NaCl',
        'reaction_type': 'Double Replacement',
        'description': 'Iron sulfide precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'ZnCl2+Na2S',
        'products': 'ZnS+NaCl',
        'balanced_equation': 'ZnCl2+Na2S->ZnS+2NaCl',
        'reaction_type': 'Double Replacement',
        'description': 'Zinc sulfide precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'MgCO3+HCl',
        'products': 'MgCl2+H2O+CO2',
        'balanced_equation': 'MgCO3+2HCl->MgCl2+H2O+CO2',
        'reaction_type': 'Double Replacement',
        'description': 'Magnesium carbonate with acid',
        'alternative_products': ''
      },
      {
        'reactants': 'NaHCO3+HCl',
        'products': 'NaCl+H2O+CO2',
        'balanced_equation': 'NaHCO3+HCl->NaCl+H2O+CO2',
        'reaction_type': 'Double Replacement',
        'description': 'Sodium bicarbonate with acid',
        'alternative_products': ''
      },
      {
        'reactants': 'K2CO3+HCl',
        'products': 'KCl+H2O+CO2',
        'balanced_equation': 'K2CO3+2HCl->2KCl+H2O+CO2',
        'reaction_type': 'Double Replacement',
        'description': 'Potassium carbonate with acid',
        'alternative_products': ''
      },
      {
        'reactants': 'NH4Cl+NaOH',
        'products': 'NaCl+NH3+H2O',
        'balanced_equation': 'NH4Cl+NaOH->NaCl+NH3+H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Ammonia gas generation',
        'alternative_products': ''
      },
      {
        'reactants': '(NH4)2SO4+NaOH',
        'products': 'Na2SO4+NH3+H2O',
        'balanced_equation': '(NH4)2SO4+2NaOH->Na2SO4+2NH3+2H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Ammonium sulfate with base',
        'alternative_products': ''
      },

// Additional Important Reactions
      {
        'reactants': 'Mg+CO2',
        'products': 'MgO+C',
        'balanced_equation': '2Mg+CO2->2MgO+C',
        'reaction_type': 'Single Replacement',
        'description': 'Magnesium burning in CO2',
        'alternative_products': ''
      },
      {
        'reactants': 'C+CO2',
        'products': 'CO',
        'balanced_equation': 'C+CO2->2CO',
        'reaction_type': 'Synthesis',
        'description': 'Carbon monoxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'FeO+CO',
        'products': 'Fe+CO2',
        'balanced_equation': 'FeO+CO->Fe+CO2',
        'reaction_type': 'Single Replacement',
        'description': 'Iron ore reduction',
        'alternative_products': ''
      },
      {
        'reactants': 'Fe3O4+CO',
        'products': 'Fe+CO2',
        'balanced_equation': 'Fe3O4+4CO->3Fe+4CO2',
        'reaction_type': 'Single Replacement',
        'description': 'Magnetite reduction',
        'alternative_products': ''
      },
      {
        'reactants': 'ZnO+C',
        'products': 'Zn+CO',
        'balanced_equation': 'ZnO+C->Zn+CO',
        'reaction_type': 'Single Replacement',
        'description': 'Zinc oxide reduction',
        'alternative_products': ''
      },
      {
        'reactants': 'CuO+C',
        'products': 'Cu+CO',
        'balanced_equation': '2CuO+C->2Cu+CO2',
        'reaction_type': 'Single Replacement',
        'description': 'Copper oxide reduction with carbon',
        'alternative_products': ''
      },
      {
        'reactants': 'PbO+C',
        'products': 'Pb+CO',
        'balanced_equation': '2PbO+C->2Pb+CO2',
        'reaction_type': 'Single Replacement',
        'description': 'Lead oxide reduction',
        'alternative_products': ''
      },
      {
        'reactants': 'SnO2+C',
        'products': 'Sn+CO',
        'balanced_equation': 'SnO2+2C->Sn+2CO',
        'reaction_type': 'Single Replacement',
        'description': 'Tin oxide reduction',
        'alternative_products': ''
      },
      {
        'reactants': 'SiO2+C',
        'products': 'Si+CO',
        'balanced_equation': 'SiO2+2C->Si+2CO',
        'reaction_type': 'Single Replacement',
        'description': 'Silicon production',
        'alternative_products': ''
      },
      {
        'reactants': 'CaCl2+Na2CO3',
        'products': 'CaCO3+NaCl',
        'balanced_equation': 'CaCl2+Na2CO3->CaCO3+2NaCl',
        'reaction_type': 'Double Replacement',
        'description': 'Calcium carbonate precipitation',
        'alternative_products': ''
      },
      {
        'reactants': 'Mn+O2',
        'products': 'MnO2',
        'balanced_equation': 'Mn+O2->MnO2',
        'reaction_type': 'Synthesis',
        'description': 'Manganese dioxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Cr+O2',
        'products': 'Cr2O3',
        'balanced_equation': '4Cr+3O2->2Cr2O3',
        'reaction_type': 'Synthesis',
        'description': 'Chromium oxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Ni+O2',
        'products': 'NiO',
        'balanced_equation': '2Ni+O2->2NiO',
        'reaction_type': 'Synthesis',
        'description': 'Nickel oxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Zn+O2',
        'products': 'ZnO',
        'balanced_equation': '2Zn+O2->2ZnO',
        'reaction_type': 'Synthesis',
        'description': 'Zinc oxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'Pb+O2',
        'products': 'PbO',
        'balanced_equation': '2Pb+O2->2PbO',
        'reaction_type': 'Synthesis',
        'description': 'Lead oxide formation',
        'alternative_products': 'Pb+O2->PbO2'
      },
      {
        'reactants': 'Cu+O2',
        'products': 'CuO',
        'balanced_equation': '2Cu+O2->2CuO',
        'reaction_type': 'Synthesis',
        'description': 'Copper oxide formation',
        'alternative_products': '4Cu+O2->2Cu2O'
      },
      {
        'reactants': 'Sn+O2',
        'products': 'SnO2',
        'balanced_equation': 'Sn+O2->SnO2',
        'reaction_type': 'Synthesis',
        'description': 'Tin oxide formation',
        'alternative_products': ''
      },
      {
        'reactants': 'NH3+HCl',
        'products': 'NH4Cl',
        'balanced_equation': 'NH3+HCl->NH4Cl',
        'reaction_type': 'Synthesis',
        'description': 'Ammonium chloride formation',
        'alternative_products': ''
      },
      {
        'reactants': 'NH3+HNO3',
        'products': 'NH4NO3',
        'balanced_equation': 'NH3+HNO3->NH4NO3',
        'reaction_type': 'Synthesis',
        'description': 'Ammonium nitrate formation',
        'alternative_products': ''
      },
      {
        'reactants': 'NH3+H2SO4',
        'products': '(NH4)2SO4',
        'balanced_equation': '2NH3+H2SO4->(NH4)2SO4',
        'reaction_type': 'Synthesis',
        'description': 'Ammonium sulfate formation',
        'alternative_products': ''
      },
      {
        'reactants': 'CH4+Cl2',
        'products': 'CH3Cl+HCl',
        'balanced_equation': 'CH4+Cl2->CH3Cl+HCl',
        'reaction_type': 'Single Replacement',
        'description': 'Chlorination of methane',
        'alternative_products': 'CH4+2Cl2->CH2Cl2+2HCl'
      },
      {
        'reactants': 'C2H4+Br2',
        'products': 'C2H4Br2',
        'balanced_equation': 'C2H4+Br2->C2H4Br2',
        'reaction_type': 'Synthesis',
        'description': 'Ethylene bromination',
        'alternative_products': ''
      },
      {
        'reactants': 'C2H4+H2O',
        'products': 'C2H5OH',
        'balanced_equation': 'C2H4+H2O->C2H5OH',
        'reaction_type': 'Synthesis',
        'description': 'Ethanol synthesis',
        'alternative_products': ''
      },
      {
        'reactants': 'C2H4+H2',
        'products': 'C2H6',
        'balanced_equation': 'C2H4+H2->C2H6',
        'reaction_type': 'Synthesis',
        'description': 'Ethane from ethylene',
        'alternative_products': ''
      }, // Complex Organic Reactions
      {
        'reactants': 'C6H5Br+Mg+CO2+H3O+',
        'products': 'C6H5COOH+MgBrOH',
        'balanced_equation':
            'C6H5Br+Mg->C6H5MgBr; C6H5MgBr+CO2->C6H5COOMgBr; C6H5COOMgBr+H3O+->C6H5COOH+MgBrOH',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Grignard synthesis of benzoic acid',
        'alternative_products': ''
      },
      {
        'reactants': 'CH3CH2Br+Mg+CH3CHO+H3O+',
        'products': 'CH3CH(OH)CH2CH3+MgBrOH',
        'balanced_equation':
            'CH3CH2Br+Mg->CH3CH2MgBr; CH3CH2MgBr+CH3CHO->CH3CH(OMgBr)CH2CH3; CH3CH(OMgBr)CH2CH3+H3O+->CH3CH(OH)CH2CH3+MgBrOH',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Grignard addition to aldehyde',
        'alternative_products': ''
      },
      {
        'reactants': 'CH3COCH3+LDA+CH3I',
        'products': 'CH3COCH2CH3+LiI',
        'balanced_equation':
            'CH3COCH3+LDA->CH3COCH2Li; CH3COCH2Li+CH3I->CH3COCH2CH3+LiI',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Enolate alkylation',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5CHO+NaBH4+H2O',
        'products': 'C6H5CH2OH+NaBO2',
        'balanced_equation':
            '4C6H5CHO+NaBH4->intermediate; intermediate+H2O->4C6H5CH2OH+NaBO2',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Sodium borohydride reduction',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5COCH3+Br2+NaOH',
        'products': 'C6H5COONa+CHBr3',
        'balanced_equation': 'C6H5COCH3+3Br2+4NaOH->C6H5COONa+CHBr3+3NaBr+3H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Haloform reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'CH3CHO+CH3CHO+NaOH',
        'products': 'CH3CH(OH)CH2CHO',
        'balanced_equation': '2CH3CHO+NaOH->CH3CH(OH)CH2CHO+Na+',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Aldol condensation',
        'alternative_products': 'CH3CH=CHCHO+H2O'
      },
      {
        'reactants': 'C6H6+CH3COCl+AlCl3',
        'products': 'C6H5COCH3+HCl',
        'balanced_equation': 'C6H6+CH3COCl+AlCl3->C6H5COCH3+HCl+AlCl3',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Friedel-Crafts acylation',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H6+CH3Cl+AlCl3',
        'products': 'C6H5CH3+HCl',
        'balanced_equation': 'C6H6+CH3Cl+AlCl3->C6H5CH3+HCl+AlCl3',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Friedel-Crafts alkylation',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H6+HNO3+H2SO4',
        'products': 'C6H5NO2+H2O',
        'balanced_equation': 'C6H6+HNO3+H2SO4->C6H5NO2+H2O+H2SO4',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Nitration of benzene',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5NO2+Fe+HCl',
        'products': 'C6H5NH2+FeCl3+H2O',
        'balanced_equation': 'C6H5NO2+2Fe+6HCl->C6H5NH2+2FeCl3+2H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Reduction of nitrobenzene to aniline',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5NH2+NaNO2+HCl+CuCN',
        'products': 'C6H5CN+N2+NaCl+CuCl+H2O',
        'balanced_equation':
            'C6H5NH2+NaNO2+2HCl->C6H5N2Cl+NaCl+2H2O; C6H5N2Cl+CuCN->C6H5CN+N2+CuCl',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Sandmeyer reaction - cyanide',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5NH2+NaNO2+HCl+CuBr',
        'products': 'C6H5Br+N2+NaCl+CuCl+H2O',
        'balanced_equation':
            'C6H5NH2+NaNO2+2HCl->C6H5N2Cl+NaCl+2H2O; C6H5N2Cl+CuBr->C6H5Br+N2+CuCl',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Sandmeyer reaction - bromide',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5NH2+(CH3CO)2O',
        'products': 'C6H5NHCOCH3+CH3COOH',
        'balanced_equation': 'C6H5NH2+(CH3CO)2O->C6H5NHCOCH3+CH3COOH',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Acetylation of aniline',
        'alternative_products': ''
      },
      {
        'reactants': 'CH3COOH+CH3CH2OH+H2SO4',
        'products': 'CH3COOCH2CH3+H2O',
        'balanced_equation': 'CH3COOH+CH3CH2OH+H2SO4->CH3COOCH2CH3+H2O+H2SO4',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Fischer esterification',
        'alternative_products': ''
      },
      {
        'reactants': 'CH3COOCH2CH3+NaOH+H2O',
        'products': 'CH3COONa+CH3CH2OH',
        'balanced_equation': 'CH3COOCH2CH3+NaOH->CH3COONa+CH3CH2OH',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Saponification of ester',
        'alternative_products': ''
      },
      {
        'reactants': 'CH3COCl+NH3',
        'products': 'CH3CONH2+HCl',
        'balanced_equation': 'CH3COCl+2NH3->CH3CONH2+NH4Cl',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Amide formation from acid chloride',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5OH+NaOH+CO2+H2SO4',
        'products': 'C6H4(OH)COOH+Na2SO4+H2O',
        'balanced_equation':
            'C6H5OH+NaOH->C6H5ONa+H2O; C6H5ONa+CO2->C6H4(OH)COONa; C6H4(OH)COONa+H2SO4->C6H4(OH)COOH+Na2SO4',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Kolbe-Schmitt reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H12O6+Yeast',
        'products': 'C2H5OH+CO2',
        'balanced_equation': 'C6H12O6->2C2H5OH+2CO2',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Fermentation of glucose',
        'alternative_products': ''
      },
      {
        'reactants': 'CH2=CH2+H2O+H2SO4',
        'products': 'CH3CH2OH',
        'balanced_equation':
            'CH2=CH2+H2O+H2SO4->CH3CH2OSO3H+H2O->CH3CH2OH+H2SO4',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Indirect hydration of ethylene',
        'alternative_products': ''
      },
      {
        'reactants': 'CH3CH2OH+K2Cr2O7+H2SO4',
        'products': 'CH3COOH+Cr2(SO4)3+K2SO4+H2O',
        'balanced_equation':
            '3CH3CH2OH+2K2Cr2O7+8H2SO4->3CH3COOH+2Cr2(SO4)3+2K2SO4+11H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Oxidation of ethanol to acetic acid',
        'alternative_products': 'CH3CHO'
      },

// Complex Inorganic Reactions
      {
        'reactants': 'KMnO4+H2C2O4+H2SO4',
        'products': 'K2SO4+MnSO4+CO2+H2O',
        'balanced_equation': '2KMnO4+5H2C2O4+3H2SO4->K2SO4+2MnSO4+10CO2+8H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Permanganate titration',
        'alternative_products': ''
      },
      {
        'reactants': 'FeSO4+KMnO4+H2SO4',
        'products': 'Fe2(SO4)3+K2SO4+MnSO4+H2O',
        'balanced_equation':
            '10FeSO4+2KMnO4+8H2SO4->5Fe2(SO4)3+K2SO4+2MnSO4+8H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Redox titration',
        'alternative_products': ''
      },
      {
        'reactants': 'Cu+HNO3+H2SO4',
        'products': 'Cu(NO3)2+NO2+H2O',
        'balanced_equation': 'Cu+4HNO3->Cu(NO3)2+2NO2+2H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Copper with concentrated nitric acid',
        'alternative_products': ''
      },
      {
        'reactants': 'MnO2+HCl',
        'products': 'MnCl2+Cl2+H2O',
        'balanced_equation': 'MnO2+4HCl->MnCl2+Cl2+2H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Chlorine gas preparation',
        'alternative_products': ''
      },
      {
        'reactants': 'Cr2O3+Al',
        'products': 'Al2O3+Cr',
        'balanced_equation': 'Cr2O3+2Al->Al2O3+2Cr',
        'reaction_type': 'Single Replacement',
        'description': 'Aluminothermic reduction of chromium',
        'alternative_products': ''
      },
      {
        'reactants': 'V2O5+Al',
        'products': 'Al2O3+V',
        'balanced_equation': '3V2O5+10Al->5Al2O3+6V',
        'reaction_type': 'Single Replacement',
        'description': 'Aluminothermic reduction of vanadium',
        'alternative_products': ''
      },
      {
        'reactants': 'KClO3+C12H22O11+H2SO4',
        'products': 'KCl+CO2+H2O+SO2',
        'balanced_equation': '8KClO3+C12H22O11->8KCl+12CO2+11H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Sugar and chlorate reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'KClO3+MnO2',
        'products': 'KCl+O2',
        'balanced_equation': '2KClO3+MnO2->2KCl+3O2+MnO2',
        'reaction_type': 'Decomposition',
        'description': 'Catalyzed oxygen generation',
        'alternative_products': ''
      },
      {
        'reactants': 'Na2S2O3+I2',
        'products': 'Na2S4O6+NaI',
        'balanced_equation': '2Na2S2O3+I2->Na2S4O6+2NaI',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Iodometric titration',
        'alternative_products': ''
      },
      {
        'reactants': 'FeS+HCl',
        'products': 'FeCl2+H2S',
        'balanced_equation': 'FeS+2HCl->FeCl2+H2S',
        'reaction_type': 'Double Replacement',
        'description': 'Hydrogen sulfide generation',
        'alternative_products': ''
      },
      {
        'reactants': 'CaC2+H2O',
        'products': 'Ca(OH)2+C2H2',
        'balanced_equation': 'CaC2+2H2O->Ca(OH)2+C2H2',
        'reaction_type': 'Double Replacement',
        'description': 'Acetylene generation',
        'alternative_products': ''
      },
      {
        'reactants': 'Al4C3+H2O',
        'products': 'Al(OH)3+CH4',
        'balanced_equation': 'Al4C3+12H2O->4Al(OH)3+3CH4',
        'reaction_type': 'Double Replacement',
        'description': 'Methane from aluminum carbide',
        'alternative_products': ''
      },
      {
        'reactants': 'Mg3N2+H2O',
        'products': 'Mg(OH)2+NH3',
        'balanced_equation': 'Mg3N2+6H2O->3Mg(OH)2+2NH3',
        'reaction_type': 'Double Replacement',
        'description': 'Ammonia from magnesium nitride',
        'alternative_products': ''
      },
      {
        'reactants': 'P4+NaOH+H2O',
        'products': 'PH3+NaH2PO2',
        'balanced_equation': 'P4+3NaOH+3H2O->PH3+3NaH2PO2',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Phosphine generation',
        'alternative_products': ''
      },
      {
        'reactants': 'NH4NO2',
        'products': 'N2+H2O',
        'balanced_equation': 'NH4NO2->N2+2H2O',
        'reaction_type': 'Decomposition',
        'description': 'Nitrogen gas from ammonium nitrite',
        'alternative_products': ''
      },
      {
        'reactants': 'NH4NO3+NaOH',
        'products': 'NaNO3+NH3+H2O',
        'balanced_equation': 'NH4NO3+NaOH->NaNO3+NH3+H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Ammonia from ammonium salt',
        'alternative_products': ''
      },

// Complex Catalytic and Industrial Reactions
      {
        'reactants': 'NH3+CH4+O2+Pt',
        'products': 'HCN+H2O',
        'balanced_equation': '2NH3+2CH4+3O2->2HCN+6H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Andrussow process for HCN',
        'alternative_products': ''
      },
      {
        'reactants': 'C2H4+O2+Ag',
        'products': 'C2H4O',
        'balanced_equation': '2C2H4+O2->2C2H4O',
        'reaction_type': 'Synthesis',
        'description': 'Ethylene oxide synthesis',
        'alternative_products': ''
      },
      {
        'reactants': 'CH3OH+CO',
        'products': 'CH3COOH',
        'balanced_equation': 'CH3OH+CO->CH3COOH',
        'reaction_type': 'Synthesis',
        'description': 'Monsanto acetic acid process',
        'alternative_products': ''
      },
      {
        'reactants': 'C3H6+NH3+O2',
        'products': 'C3H3N+H2O',
        'balanced_equation': '2C3H6+2NH3+3O2->2C3H3N+6H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Acrylonitrile synthesis (Sohio process)',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H6+C2H4+H3PO4',
        'products': 'C6H5C2H5+H2O',
        'balanced_equation': 'C6H6+C2H4->C6H5C2H5',
        'reaction_type': 'Synthesis',
        'description': 'Ethylbenzene synthesis',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5C2H5+Fe2O3',
        'products': 'C6H5CH=CH2+H2O+Fe2O3',
        'balanced_equation': 'C6H5C2H5->C6H5CH=CH2+H2',
        'reaction_type': 'Decomposition',
        'description': 'Styrene production',
        'alternative_products': ''
      },
      {
        'reactants': 'CH3OH+O2+Ag',
        'products': 'HCHO+H2O',
        'balanced_equation': '2CH3OH+O2->2HCHO+2H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Formaldehyde synthesis',
        'alternative_products': ''
      },
      {
        'reactants': 'CO+H2+Catalyst',
        'products': 'CH3OH',
        'balanced_equation': 'CO+2H2->CH3OH',
        'reaction_type': 'Synthesis',
        'description': 'Methanol synthesis',
        'alternative_products': ''
      },
      {
        'reactants': 'CO+H2+Co',
        'products': 'CnH2n+2+H2O',
        'balanced_equation': 'nCO+2nH2->CnH2n+2+nH2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Fischer-Tropsch synthesis',
        'alternative_products': ''
      },
      {
        'reactants': 'C7H8+O2+V2O5',
        'products': 'C6H5CHO+H2O',
        'balanced_equation': '2C7H8+O2->2C6H5CHO+2H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Toluene oxidation to benzaldehyde',
        'alternative_products': ''
      },
      {
        'reactants': 'CH4+H2O+Ni',
        'products': 'CO+H2',
        'balanced_equation': 'CH4+H2O->CO+3H2',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Steam reforming of methane',
        'alternative_products': ''
      },
      {
        'reactants': 'CO+H2O+Fe3O4',
        'products': 'CO2+H2',
        'balanced_equation': 'CO+H2O->CO2+H2',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Water-gas shift reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'C2H4+HCl+PdCl2',
        'products': 'CH3CHO+Pd+HCl',
        'balanced_equation': 'C2H4+PdCl2+H2O->CH3CHO+Pd+2HCl',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Wacker process',
        'alternative_products': ''
      },
      {
        'reactants': 'C4H6+Cl2',
        'products': 'C4H6Cl2',
        'balanced_equation': 'C4H6+Cl2->C4H6Cl2',
        'reaction_type': 'Synthesis',
        'description': 'Neoprene precursor synthesis',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5CH3+Cl2+FeCl3',
        'products': 'C6H5CH2Cl+HCl',
        'balanced_equation': 'C6H5CH3+Cl2->C6H5CH2Cl+HCl',
        'reaction_type': 'Single Replacement',
        'description': 'Benzylic chlorination',
        'alternative_products': 'C6H5CHCl2+HCl'
      },

// Named Organic Reactions
      {
        'reactants': 'C6H5CHO+CH3COCH3+NaOH',
        'products': 'C6H5CH=CHCOCH3+H2O',
        'balanced_equation': 'C6H5CHO+CH3COCH3+NaOH->C6H5CH=CHCOCH3+NaOH+H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Claisen-Schmidt condensation',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5CHO+(C6H5)3P=CH2',
        'products': 'C6H5CH=CH2+(C6H5)3PO',
        'balanced_equation': 'C6H5CHO+(C6H5)3P=CH2->C6H5CH=CH2+(C6H5)3PO',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Wittig reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'CH2=CHCHO+C4H6',
        'products': 'C7H10O',
        'balanced_equation': 'CH2=CHCHO+C4H6->C7H10O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Diels-Alder reaction',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5COOH+SOCl2',
        'products': 'C6H5COCl+SO2+HCl',
        'balanced_equation': 'C6H5COOH+SOCl2->C6H5COCl+SO2+HCl',
        'reaction_type': 'Single Replacement',
        'description': 'Acid chloride formation',
        'alternative_products': ''
      },
      {
        'reactants': 'RCOOH+R\'OH+DCC',
        'products': 'RCOOR\'+Urea',
        'balanced_equation': 'RCOOH+R\'OH+DCC->RCOOR\'+Dicyclohexylurea',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'DCC coupling for ester formation',
        'alternative_products': ''
      },
      {
        'reactants': 'RNH2+R\'CHO+NaBH3CN',
        'products': 'RNHCH2R\'+NaCN+BH3',
        'balanced_equation':
            'RNH2+R\'CHO->R-N=CHR\'; R-N=CHR\'+NaBH3CN->RNHCH2R\'+NaCN',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Reductive amination',
        'alternative_products': ''
      },
      {
        'reactants': 'C6H5N2Cl+H2O',
        'products': 'C6H5OH+N2+HCl',
        'balanced_equation': 'C6H5N2Cl+H2O->C6H5OH+N2+HCl',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Phenol from diazonium salt',
        'alternative_products': ''
      },
      {
        'reactants': 'RCH2COOH+Br2+P',
        'products': 'RCHBrCOOH+HBr',
        'balanced_equation': 'RCH2COOH+Br2+P->RCHBrCOOH+HBr',
        'reaction_type': 'Single Replacement',
        'description': 'Hell-Volhard-Zelinsky reaction',
        'alternative_products': ''
      },
// Reactions with Multiple Alternative Products
      {
        'reactants': 'C+H2O',
        'products': 'CO+H2',
        'balanced_equation': 'C+H2O->CO+H2',
        'reaction_type': 'Single Replacement',
        'description': 'Water gas reaction',
        'alternative_products': 'C+2H2O->CO2+2H2'
      },
      {
        'reactants': 'NH3+O2',
        'products': 'NO+H2O',
        'balanced_equation': '4NH3+5O2->4NO+6H2O',
        'reaction_type': 'Combustion',
        'description': 'Catalytic oxidation of ammonia',
        'alternative_products': '4NH3+3O2->2N2+6H2O; 2NH3+2O2->N2O+3H2O'
      },
      {
        'reactants': 'CH3CH2OH+O2',
        'products': 'CH3CHO+H2O',
        'balanced_equation': '2CH3CH2OH+O2->2CH3CHO+2H2O',
        'reaction_type': 'Combustion',
        'description': 'Partial oxidation of ethanol',
        'alternative_products':
            'CH3CH2OH+3O2->2CO2+3H2O; 2CH3CH2OH+2O2->2CH3COOH+2H2O'
      },
      {
        'reactants': 'C6H12O6',
        'products': 'C2H5OH+CO2',
        'balanced_equation': 'C6H12O6->2C2H5OH+2CO2',
        'reaction_type': 'Decomposition',
        'description': 'Anaerobic fermentation',
        'alternative_products': 'C6H12O6+6O2->6CO2+6H2O; C6H12O6->2CH3CHOHCOOH'
      },
      {
        'reactants': 'C2H5OH+H2SO4',
        'products': 'C2H4+H2O',
        'balanced_equation': 'C2H5OH+H2SO4->C2H4+H2O+H2SO4',
        'reaction_type': 'Decomposition',
        'description': 'Ethanol dehydration at 180°C',
        'alternative_products': '2C2H5OH+H2SO4->C2H5OC2H5+H2O+H2SO4'
      },
      {
        'reactants': 'C6H5CH3+KMnO4+H2SO4',
        'products': 'C6H5COOH+MnSO4+K2SO4+H2O',
        'balanced_equation':
            '5C6H5CH3+6KMnO4+9H2SO4->5C6H5COOH+3K2SO4+6MnSO4+14H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Oxidation of toluene to benzoic acid',
        'alternative_products':
            'C6H5CH3+KMnO4->C6H5CHO+MnO2+KOH; C6H5CH3+O2->C6H5CH2OH+H2O'
      },
      {
        'reactants': 'CH3CH2OH+CrO3+H2SO4',
        'products': 'CH3CHO+Cr2(SO4)3+H2O',
        'balanced_equation': '3CH3CH2OH+2CrO3+3H2SO4->3CH3CHO+Cr2(SO4)3+6H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Oxidation of ethanol to acetaldehyde',
        'alternative_products':
            '3CH3CH2OH+2K2Cr2O7+8H2SO4->3CH3COOH+2Cr2(SO4)3+2K2SO4+11H2O'
      },
      {
        'reactants': 'NO+O2',
        'products': 'NO2',
        'balanced_equation': '2NO+O2->2NO2',
        'reaction_type': 'Synthesis',
        'description': 'Nitrogen dioxide formation',
        'alternative_products': '2NO2->N2O4'
      },
      {
        'reactants': 'SO2+O2',
        'products': 'SO3',
        'balanced_equation': '2SO2+O2->2SO3',
        'reaction_type': 'Synthesis',
        'description': 'Contact process',
        'alternative_products': 'SO2+H2O->H2SO3'
      },
      {
        'reactants': 'Cl2+H2O',
        'products': 'HCl+HOCl',
        'balanced_equation': 'Cl2+H2O->HCl+HOCl',
        'reaction_type': 'Double Replacement',
        'description': 'Chlorine water formation',
        'alternative_products':
            'Cl2+2NaOH->NaCl+NaOCl+H2O; 3Cl2+6NaOH->5NaCl+NaClO3+3H2O'
      },
      {
        'reactants': 'P+Cl2',
        'products': 'PCl3',
        'balanced_equation': '2P+3Cl2->2PCl3',
        'reaction_type': 'Synthesis',
        'description': 'Phosphorus trichloride formation',
        'alternative_products': 'P+5Cl2->PCl5; 2P+5Cl2->2PCl5'
      },
      {
        'reactants': 'S+Cl2',
        'products': 'S2Cl2',
        'balanced_equation': '2S+Cl2->S2Cl2',
        'reaction_type': 'Synthesis',
        'description': 'Disulfur dichloride formation',
        'alternative_products': 'S+Cl2->SCl2'
      },
      {
        'reactants': 'NH3+Cl2',
        'products': 'NH4Cl+N2',
        'balanced_equation': '8NH3+3Cl2->6NH4Cl+N2',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Ammonia with excess chlorine',
        'alternative_products': 'NH3+3Cl2->NCl3+3HCl; 2NH3+3Cl2->N2+6HCl'
      },
      {
        'reactants': 'C6H6+Cl2+FeCl3',
        'products': 'C6H5Cl+HCl',
        'balanced_equation': 'C6H6+Cl2->C6H5Cl+HCl',
        'reaction_type': 'Single Replacement',
        'description': 'Chlorination of benzene',
        'alternative_products': 'C6H6+3Cl2->C6H6Cl6 (hexachlorocyclohexane)'
      },
      {
        'reactants': 'CH4+Cl2+UV',
        'products': 'CH3Cl+HCl',
        'balanced_equation': 'CH4+Cl2->CH3Cl+HCl',
        'reaction_type': 'Single Replacement',
        'description': 'Methane chlorination (1st step)',
        'alternative_products':
            'CH3Cl+Cl2->CH2Cl2+HCl; CH2Cl2+Cl2->CHCl3+HCl; CHCl3+Cl2->CCl4+HCl'
      },
      {
        'reactants': 'Fe+H2O',
        'products': 'Fe3O4+H2',
        'balanced_equation': '3Fe+4H2O->Fe3O4+4H2',
        'reaction_type': 'Single Replacement',
        'description': 'Iron with steam',
        'alternative_products': 'Fe+H2O->FeO+H2; 2Fe+3H2O->Fe2O3+3H2'
      },
      {
        'reactants': 'Zn+NaOH+H2O',
        'products': 'Na2ZnO2+H2',
        'balanced_equation': 'Zn+2NaOH->Na2ZnO2+H2',
        'reaction_type': 'Single Replacement',
        'description': 'Amphoteric zinc with base',
        'alternative_products': 'Zn+2NaOH+2H2O->Na2[Zn(OH)4]+H2'
      },
      {
        'reactants': 'Al+NaOH+H2O',
        'products': 'NaAlO2+H2',
        'balanced_equation': '2Al+2NaOH+2H2O->2NaAlO2+3H2',
        'reaction_type': 'Single Replacement',
        'description': 'Aluminum with sodium hydroxide',
        'alternative_products': 'Al+NaOH+3H2O->Na[Al(OH)4]+3/2H2'
      },
      {
        'reactants': 'Si+NaOH+H2O',
        'products': 'Na2SiO3+H2',
        'balanced_equation': 'Si+2NaOH+H2O->Na2SiO3+2H2',
        'reaction_type': 'Single Replacement',
        'description': 'Silicon with sodium hydroxide',
        'alternative_products': 'Si+4NaOH->Na4SiO4+2H2'
      },
      {
        'reactants': 'CH3COOH+Ca(OH)2',
        'products': '(CH3COO)2Ca+H2O',
        'balanced_equation': '2CH3COOH+Ca(OH)2->(CH3COO)2Ca+2H2O',
        'reaction_type': 'Double Replacement',
        'description': 'Acetic acid neutralization',
        'alternative_products': '(CH3COO)2Ca->CaCO3+CH3COCH3 (pyrolysis)'
      },
      {
        'reactants': 'HCOOH+H2SO4',
        'products': 'CO+H2O',
        'balanced_equation': 'HCOOH+H2SO4->CO+H2O+H2SO4',
        'reaction_type': 'Decomposition',
        'description': 'Formic acid dehydration',
        'alternative_products': 'HCOOH->CO2+H2'
      },
      {
        'reactants': 'C2H5OH+HBr+H2SO4',
        'products': 'C2H5Br+H2O',
        'balanced_equation': 'C2H5OH+HBr->C2H5Br+H2O',
        'reaction_type': 'Single Replacement',
        'description': 'Ethyl bromide synthesis',
        'alternative_products': 'C2H5OH+PBr3->C2H5Br+H3PO3'
      },
      {
        'reactants': 'C6H5OH+Br2',
        'products': 'C6H2Br3OH+HBr',
        'balanced_equation': 'C6H5OH+3Br2->C6H2Br3OH+3HBr',
        'reaction_type': 'Single Replacement',
        'description': 'Tribromophenol formation',
        'alternative_products': 'C6H5OH+Br2->C6H4BrOH+HBr (mono-substitution)'
      },
      {
        'reactants': 'C6H5NH2+Br2',
        'products': 'C6H2Br3NH2+HBr',
        'balanced_equation': 'C6H5NH2+3Br2->C6H2Br3NH2+3HBr',
        'reaction_type': 'Single Replacement',
        'description': 'Tribromoaniline formation',
        'alternative_products': 'C6H5NH2+Br2->C6H4BrNH2+HBr'
      },
      {
        'reactants': 'CH3COOH+PCl5',
        'products': 'CH3COCl+POCl3+HCl',
        'balanced_equation': 'CH3COOH+PCl5->CH3COCl+POCl3+HCl',
        'reaction_type': 'Single Replacement',
        'description': 'Acetyl chloride formation',
        'alternative_products': '3CH3COOH+PCl3->3CH3COCl+H3PO3'
      },
      {
        'reactants': 'C6H5COOH+NH3',
        'products': 'C6H5COONH4',
        'balanced_equation': 'C6H5COOH+NH3->C6H5COONH4',
        'reaction_type': 'Synthesis',
        'description': 'Ammonium benzoate formation',
        'alternative_products': 'C6H5COONH4->C6H5CONH2+H2O (heating)'
      },
      {
        'reactants': 'CH3CHO+NH3',
        'products': 'CH3CH=NH+H2O',
        'balanced_equation': 'CH3CHO+NH3->CH3CH=NH+H2O',
        'reaction_type': 'Synthesis',
        'description': 'Aldimine formation',
        'alternative_products': 'CH3CHO+NH3->CH3CH(OH)NH2 (addition)'
      },
      {
        'reactants': 'CH3COCH3+NH2OH',
        'products': 'CH3C(=NOH)CH3+H2O',
        'balanced_equation': 'CH3COCH3+NH2OH->CH3C(=NOH)CH3+H2O',
        'reaction_type': 'Synthesis',
        'description': 'Oxime formation from acetone',
        'alternative_products':
            'CH3COCH3+NH2NH2->CH3C(=NNH2)CH3+H2O (hydrazone)'
      },
      {
        'reactants': 'C6H5CHO+HCN',
        'products': 'C6H5CH(OH)CN',
        'balanced_equation': 'C6H5CHO+HCN->C6H5CH(OH)CN',
        'reaction_type': 'Synthesis',
        'description': 'Cyanohydrin formation',
        'alternative_products': 'C6H5CHO+NaHSO3->C6H5CH(OH)SO3Na'
      },
      {
        'reactants': 'RCHO+R\'MgBr',
        'products': 'RCH(OH)R\'+MgBrOH',
        'balanced_equation':
            'RCHO+R\'MgBr->RCH(OMgBr)R\'; RCH(OMgBr)R\'+H3O+->RCH(OH)R\'+MgBrOH',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Grignard addition to aldehyde',
        'alternative_products':
            'RCOR\'+R\'\'MgBr->RC(OH)(R\')(R\'\') (addition to ketone)'
      },
      {
        'reactants': 'CH3COOC2H5+CH3MgBr',
        'products': '(CH3)2C(OH)CH3+C2H5OMgBr',
        'balanced_equation': 'CH3COOC2H5+2CH3MgBr->(CH3)3COH+C2H5OMgBr',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Grignard reaction with ester',
        'alternative_products':
            'RCOOR\'+R\'\'MgBr->RCOR\'\'+R\'OMgBr (first addition)'
      },
      {
        'reactants': 'C6H5N2Cl+KI',
        'products': 'C6H5I+N2+KCl',
        'balanced_equation': 'C6H5N2Cl+KI->C6H5I+N2+KCl',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Iodobenzene from diazonium salt',
        'alternative_products':
            'C6H5N2Cl+H3PO2+H2O->C6H6+N2+H3PO3+HCl (reduction to benzene)'
      },
      {
        'reactants': 'C6H5OH+CHCl3+NaOH',
        'products': 'C6H4(OH)CHO+NaCl+H2O',
        'balanced_equation': 'C6H5OH+CHCl3+3NaOH->C6H4(OH)CHO+3NaCl+2H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Reimer-Tiemann reaction',
        'alternative_products':
            'C6H5OH+CCl4+NaOH->C6H4(OH)COONa (formate formation)'
      },
      {
        'reactants': 'C6H5NH2+CHCl3+KOH',
        'products': 'C6H5NC+KCl+H2O',
        'balanced_equation': 'C6H5NH2+CHCl3+3KOH->C6H5NC+3KCl+3H2O',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Carbylamine reaction',
        'alternative_products': 'C6H5NH2+CS2+HgO->C6H5NCS (isothiocyanate)'
      },
      {
        'reactants': 'C2H4+HBr',
        'products': 'C2H5Br',
        'balanced_equation': 'C2H4+HBr->C2H5Br',
        'reaction_type': 'Synthesis',
        'description': 'Ethyl bromide from ethylene',
        'alternative_products': 'C2H4+Br2->C2H4Br2 (dibromoethane)'
      },
      {
        'reactants': 'C3H6+HBr',
        'products': 'C3H7Br',
        'balanced_equation': 'C3H6+HBr->CH3CHBrCH3',
        'reaction_type': 'Synthesis',
        'description': 'Markovnikov addition',
        'alternative_products':
            'C3H6+HBr+Peroxide->CH3CH2CH2Br (anti-Markovnikov)'
      },
      {
        'reactants': 'RX+KCN',
        'products': 'RCN+KX',
        'balanced_equation': 'RX+KCN->RCN+KX',
        'reaction_type': 'Single Replacement',
        'description': 'Nitrile formation',
        'alternative_products': 'RX+AgCN->RNC+AgX (isocyanide)'
      },
      {
        'reactants': 'CH3Br+AgNO2',
        'products': 'CH3NO2+AgBr',
        'balanced_equation': 'CH3Br+AgNO2->CH3NO2+AgBr',
        'reaction_type': 'Single Replacement',
        'description': 'Nitroalkane formation',
        'alternative_products': 'CH3Br+KNO2->CH3ONO+KBr (nitrite ester)'
      },
      {
        'reactants': 'RCOCl+R\'COOAg',
        'products': 'RCOCOR\'+AgCl',
        'balanced_equation': 'RCOCl+R\'COOAg->RCOCOR\'+AgCl',
        'reaction_type': 'Single Replacement',
        'description': 'Diketone synthesis',
        'alternative_products': 'RCOCl+(R\'CO)2O->RCOCOR\'+R\'COCl'
      },
      {
        'reactants': 'C6H5MgBr+CO2',
        'products': 'C6H5COOMgBr',
        'balanced_equation': 'C6H5MgBr+CO2->C6H5COOMgBr',
        'reaction_type': 'Synthesis',
        'description': 'Carboxylic acid synthesis via Grignard',
        'alternative_products':
            'C6H5MgBr+S->C6H5SMgBr (thiol formation); C6H5MgBr+O2->C6H5OOMgBr'
      },
      {
        'reactants': 'C6H5COOH+HNO3+H2SO4',
        'products': 'C6H4(NO2)COOH+H2O',
        'balanced_equation': 'C6H5COOH+HNO3+H2SO4->C6H4(NO2)COOH+H2O+H2SO4',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Nitration of benzoic acid (meta)',
        'alternative_products':
            'C6H5COOH+2HNO3->C6H3(NO2)2COOH+2H2O (dinitration)'
      },
      {
        'reactants': 'C6H5CH3+HNO3+H2SO4',
        'products': 'C6H4(CH3)NO2+H2O',
        'balanced_equation': 'C6H5CH3+HNO3+H2SO4->C6H4(CH3)NO2+H2O+H2SO4',
        'reaction_type': 'Multi-step Synthesis',
        'description': 'Nitration of toluene (ortho/para)',
        'alternative_products':
            'C6H5CH3+3HNO3->C6H2(CH3)(NO2)3+3H2O (trinitrotoluene/TNT)'
      },
      {
        'reactants': 'C6H5OH+H2SO4',
        'products': 'C6H4(OH)SO3H+H2O',
        'balanced_equation': 'C6H5OH+H2SO4->C6H4(OH)SO3H+H2O',
        'reaction_type': 'Single Replacement',
        'description': 'Sulfonation of phenol',
        'alternative_products': 'C6H5OH+H2SO4->C6H5OSO3H (sulfate ester)'
      },
      {
        'reactants': 'RNH2+RCOOH',
        'products': 'RCONHR+H2O',
        'balanced_equation': 'RNH2+RCOOH->RCONHR+H2O',
        'reaction_type': 'Synthesis',
        'description': 'Amide formation from amine and acid',
        'alternative_products': 'RNH2+RCOOH->[RNH3][RCOO] (salt formation)'
      }
    ];
    for (var reaction in reactions) {
      await db.insert('reactions', reaction);
    }
  }

  Future<void> _populateReactionRules(Database db) async {
    final rules = [
      {
        'rule_name': 'Synthesis',
        'pattern': 'A+B->AB',
        'description': 'Two or more substances combine to form a single product'
      },
      {
        'rule_name': 'Decomposition',
        'pattern': 'AB->A+B',
        'description': 'A single compound breaks down into two or more products'
      },
      {
        'rule_name': 'Single Replacement',
        'pattern': 'A+BC->AC+B',
        'description': 'One element replaces another in a compound'
      },
      {
        'rule_name': 'Double Replacement',
        'pattern': 'AB+CD->AD+CB',
        'description': 'Two compounds exchange partners'
      },
      {
        'rule_name': 'Combustion',
        'pattern': 'CxHy+O2->CO2+H2O',
        'description':
            'Hydrocarbon reacts with oxygen to produce carbon dioxide and water'
      },
    ];

    for (var rule in rules) {
      await db.insert('reaction_rules', rule);
    }
  }

  // CRUD Operations for Elements
  Future<List<Element>> getAllElements() async {
    final db = await database;
    final result = await db.query('elements', orderBy: 'atomic_number ASC');
    return result.map((json) => Element.fromJson(json)).toList();
  }

  Future<Element?> getElementBySymbol(String symbol) async {
    final db = await database;
    final result = await db.query(
      'elements',
      where: 'symbol = ?',
      whereArgs: [symbol],
    );
    if (result.isNotEmpty) {
      return Element.fromJson(result.first);
    }
    return null;
  }

  // CRUD Operations for Compounds
  Future<List<Compound>> getAllCompounds() async {
    final db = await database;
    final result = await db.query('compounds', orderBy: 'name ASC');
    return result.map((json) => Compound.fromJson(json)).toList();
  }

  Future<Compound?> getCompoundByFormula(String formula) async {
    final db = await database;
    final result = await db.query(
      'compounds',
      where: 'formula = ?',
      whereArgs: [formula],
    );
    if (result.isNotEmpty) {
      return Compound.fromJson(result.first);
    }
    return null;
  }

  // CRUD Operations for Reactions
  Future<List<Reaction>> getAllReactions() async {
    final db = await database;
    final result = await db.query('reactions');
    return result.map((json) => Reaction.fromJson(json)).toList();
  }

  Future<Reaction?> findReaction(String reactants, String products) async {
    final db = await database;
    final normalized = '$reactants+$products'.replaceAll(' ', '').toLowerCase();

    final result = await db.query('reactions');
    for (var row in result) {
      final dbReactants =
          (row['reactants'] as String).replaceAll(' ', '').toLowerCase();
      final dbProducts =
          (row['products'] as String).replaceAll(' ', '').toLowerCase();
      final dbNormalized = '$dbReactants+$dbProducts';

      if (normalized.contains(dbReactants) && normalized.contains(dbProducts)) {
        return Reaction.fromJson(row);
      }
    }
    return null;
  }

  // CRUD Operations for History
  Future<int> insertHistory(HistoryItem item) async {
    final db = await database;
    return await db.insert('history', item.toJson());
  }

  Future<List<HistoryItem>> getAllHistory() async {
    final db = await database;
    final result = await db.query('history', orderBy: 'id DESC');
    return result.map((json) => HistoryItem.fromJson(json)).toList();
  }

  Future<int> deleteHistory(int id) async {
    final db = await database;
    return await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAllHistory() async {
    final db = await database;
    return await db.delete('history');
  }

  Future<int> toggleSaveHistory(int id, bool isSaved) async {
    final db = await database;
    return await db.update(
      'history',
      {'is_saved': isSaved ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<HistoryItem>> getSavedHistory() async {
    final db = await database;
    final result = await db.query(
      'history',
      where: 'is_saved = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );
    return result.map((json) => HistoryItem.fromJson(json)).toList();
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
