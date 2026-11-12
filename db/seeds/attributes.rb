# frozen_string_literal: true

# Phase 1c catalogue: attribute definitions and their options.
#
# Options are listed as strings; `generic_labels` supplies the six-locale
# translation for labels that are generic words. Brand names, model names,
# numbers and acronyms stay identical in every locale.
locales = %i[es en fr de it pt]

generic_labels = {
  "Other" => {
    es: "Otro", en: "Other", fr: "Autre", de: "Andere", it: "Altro", pt: "Outro"
  },
  "None" => {
    es: "Ninguno", en: "None", fr: "Aucun", de: "Keine", it: "Nessuno", pt: "Nenhum"
  },
  "Air" => {
    es: "Aire", en: "Air", fr: "Air", de: "Luft", it: "Aria", pt: "Ar"
  },
  "Custom loop" => {
    es: "Circuito personalizado",
    en: "Custom loop",
    fr: "Boucle personnalisée",
    de: "Custom-Loop",
    it: "Circuito personalizzato",
    pt: "Loop personalizado"
  },
  "Passive/Fanless" => {
    es: "Pasivo/Sin ventilador",
    en: "Passive/Fanless",
    fr: "Passif/Sans ventilateur",
    de: "Passiv/Lüfterlos",
    it: "Passivo/Senza ventola",
    pt: "Passivo/Sem ventoinha"
  },
  "Multiple Intel" => {
    es: "Varios Intel",
    en: "Multiple Intel",
    fr: "Plusieurs Intel",
    de: "Mehrere Intel",
    it: "Più Intel",
    pt: "Vários Intel"
  },
  "Multiple AMD" => {
    es: "Varios AMD",
    en: "Multiple AMD",
    fr: "Plusieurs AMD",
    de: "Mehrere AMD",
    it: "Più AMD",
    pt: "Vários AMD"
  },
  "Multiple Intel and AMD" => {
    es: "Varios Intel y AMD",
    en: "Multiple Intel and AMD",
    fr: "Plusieurs Intel et AMD",
    de: "Mehrere Intel und AMD",
    it: "Più Intel e AMD",
    pt: "Vários Intel e AMD"
  },
  "Integrated" => {
    es: "Integrada", en: "Integrated", fr: "Intégrée", de: "Integriert", it: "Integrata", pt: "Integrada"
  },
  "Less than 8" => {
    es: "Menos de 8", en: "Less than 8", fr: "Moins de 8", de: "Weniger als 8", it: "Meno di 8", pt: "Menos de 8"
  },
  "More than 16TB" => {
    es: "Más de 16 TB",
    en: "More than 16TB",
    fr: "Plus de 16 To",
    de: "Mehr als 16 TB",
    it: "Più di 16 TB",
    pt: "Mais de 16 TB"
  },
  "DIMM (Desktop)" => {
    es: "DIMM (sobremesa)",
    en: "DIMM (Desktop)",
    fr: "DIMM (bureau)",
    de: "DIMM (Desktop)",
    it: "DIMM (desktop)",
    pt: "DIMM (secretária)"
  },
  "SO-DIMM (Laptop)" => {
    es: "SO-DIMM (portátil)",
    en: "SO-DIMM (Laptop)",
    fr: "SO-DIMM (portable)",
    de: "SO-DIMM (Laptop)",
    it: "SO-DIMM (portatile)",
    pt: "SO-DIMM (portátil)"
  },
  "2.5 inch" => {
    es: "2,5 pulgadas", en: "2.5 inch", fr: "2,5 pouces", de: "2,5 Zoll", it: "2,5 pollici", pt: "2,5 polegadas"
  },
  "3.5 inch" => {
    es: "3,5 pulgadas", en: "3.5 inch", fr: "3,5 pouces", de: "3,5 Zoll", it: "3,5 pollici", pt: "3,5 polegadas"
  },
  "Ethernet and Wi-Fi" => {
    es: "Ethernet y Wi-Fi",
    en: "Ethernet and Wi-Fi",
    fr: "Ethernet et Wi-Fi",
    de: "Ethernet und WLAN",
    it: "Ethernet e Wi-Fi",
    pt: "Ethernet e Wi-Fi"
  },
  "Ethernet only" => {
    es: "Solo Ethernet",
    en: "Ethernet only",
    fr: "Ethernet uniquement",
    de: "Nur Ethernet",
    it: "Solo Ethernet",
    pt: "Apenas Ethernet"
  },
  "Wi-Fi only" => {
    es: "Solo Wi-Fi",
    en: "Wi-Fi only",
    fr: "Wi-Fi uniquement",
    de: "Nur WLAN",
    it: "Solo Wi-Fi",
    pt: "Apenas Wi-Fi"
  },
  "Extended ATX" => {
    es: "ATX extendido",
    en: "Extended ATX",
    fr: "ATX étendu",
    de: "Erweitertes ATX",
    it: "ATX esteso",
    pt: "ATX estendido"
  },
  "Mid-Tower" => {
    es: "Torre media", en: "Mid-Tower", fr: "Tour moyenne", de: "Midi-Tower", it: "Mid-Tower", pt: "Mid-Tower"
  },
  "Mini-Tower" => {
    es: "Mini torre", en: "Mini-Tower", fr: "Mini tour", de: "Mini-Tower", it: "Mini-Tower", pt: "Mini-Tower"
  },
  "Full-Tower" => {
    es: "Torre completa", en: "Full-Tower", fr: "Tour complète", de: "Big-Tower", it: "Full-Tower", pt: "Full-Tower"
  },
  "Small form factor" => {
    es: "Formato pequeño",
    en: "Small form factor",
    fr: "Petit format",
    de: "Kleines Format",
    it: "Formato ridotto",
    pt: "Formato compacto"
  },
  "Open frame" => {
    es: "Estructura abierta",
    en: "Open frame",
    fr: "Châssis ouvert",
    de: "Offener Rahmen",
    it: "Telaio aperto",
    pt: "Estrutura aberta"
  },
  "Home theatre PC" => {
    es: "PC para cine en casa",
    en: "Home theatre PC",
    fr: "PC home cinéma",
    de: "Heimkino-PC",
    it: "PC home theatre",
    pt: "PC de cinema em casa"
  },
  "Server" => {
    es: "Servidor", en: "Server", fr: "Serveur", de: "Server", it: "Server", pt: "Servidor"
  },
  "Black" => {
    es: "Negro", en: "Black", fr: "Noir", de: "Schwarz", it: "Nero", pt: "Preto"
  },
  "White" => {
    es: "Blanco", en: "White", fr: "Blanc", de: "Weiß", it: "Bianco", pt: "Branco"
  },
  "Silver" => {
    es: "Plata", en: "Silver", fr: "Argent", de: "Silber", it: "Argento", pt: "Prata"
  },
  "Grey" => {
    es: "Gris", en: "Grey", fr: "Gris", de: "Grau", it: "Grigio", pt: "Cinzento"
  },
  "Black and white" => {
    es: "Negro y blanco",
    en: "Black and white",
    fr: "Noir et blanc",
    de: "Schwarz und Weiß",
    it: "Nero e bianco",
    pt: "Preto e branco"
  },
  "Multicolour" => {
    es: "Multicolor",
    en: "Multicolour",
    fr: "Multicolore",
    de: "Mehrfarbig",
    it: "Multicolore",
    pt: "Multicolor"
  },
  "Blue" => {
    es: "Azul", en: "Blue", fr: "Bleu", de: "Blau", it: "Blu", pt: "Azul"
  },
  "Green" => {
    es: "Verde", en: "Green", fr: "Vert", de: "Grün", it: "Verde", pt: "Verde"
  },
  "Pink" => {
    es: "Rosa", en: "Pink", fr: "Rose", de: "Rosa", it: "Rosa", pt: "Rosa"
  },
  "Purple" => {
    es: "Morado", en: "Purple", fr: "Violet", de: "Lila", it: "Viola", pt: "Roxo"
  },
  "Red" => {
    es: "Rojo", en: "Red", fr: "Rouge", de: "Rot", it: "Rosso", pt: "Vermelho"
  },
  "Gold" => {
    es: "Oro", en: "Gold", fr: "Or", de: "Gold", it: "Oro", pt: "Ouro"
  },
  "Wood" => {
    es: "Madera", en: "Wood", fr: "Bois", de: "Holz", it: "Legno", pt: "Madeira"
  },
  "Less than 400W" => {
    es: "Menos de 400 W",
    en: "Less than 400W",
    fr: "Moins de 400 W",
    de: "Weniger als 400 W",
    it: "Meno di 400 W",
    pt: "Menos de 400 W"
  },
  "Micro ATX" => {
    es: "Micro ATX", en: "Micro ATX", fr: "Micro ATX", de: "Micro ATX", it: "Micro ATX", pt: "Micro ATX"
  },
  "80+ White" => {
    es: "80+ Blanco", en: "80+ White", fr: "80+ Blanc", de: "80+ Weiß", it: "80+ Bianco", pt: "80+ Branco"
  },
  "Bronze" => {
    es: "Bronce", en: "Bronze", fr: "Bronze", de: "Bronze", it: "Bronzo", pt: "Bronze"
  },
  "Platinum" => {
    es: "Platino", en: "Platinum", fr: "Platine", de: "Platin", it: "Platino", pt: "Platina"
  },
  "Titanium" => {
    es: "Titanio", en: "Titanium", fr: "Titane", de: "Titan", it: "Titanio", pt: "Titânio"
  },
  "Addressable (ARGB)" => {
    es: "Direccionable (ARGB)",
    en: "Addressable (ARGB)",
    fr: "Adressable (ARGB)",
    de: "Adressierbar (ARGB)",
    it: "Indirizzabile (ARGB)",
    pt: "Endereçável (ARGB)"
  },
  "Static RGB" => {
    es: "RGB estático",
    en: "Static RGB",
    fr: "RGB statique",
    de: "Statisches RGB",
    it: "RGB statico",
    pt: "RGB estático"
  },
  "Wired" => {
    es: "Con cable", en: "Wired", fr: "Filaire", de: "Kabelgebunden", it: "Cablato", pt: "Com fios"
  },
  "Wireless 2.4 GHz" => {
    es: "Inalámbrico 2,4 GHz",
    en: "Wireless 2.4 GHz",
    fr: "Sans fil 2,4 GHz",
    de: "Kabellos 2,4 GHz",
    it: "Wireless 2,4 GHz",
    pt: "Sem fios 2,4 GHz"
  },
  "Spanish (ES)" => {
    es: "Español (ES)",
    en: "Spanish (ES)",
    fr: "Espagnol (ES)",
    de: "Spanisch (ES)",
    it: "Spagnolo (ES)",
    pt: "Espanhol (ES)"
  },
  "UK" => {
    es: "Reino Unido (UK)",
    en: "UK",
    fr: "Royaume-Uni (UK)",
    de: "Vereinigtes Königreich (UK)",
    it: "Regno Unito (UK)",
    pt: "Reino Unido (UK)"
  },
  "US" => {
    es: "Estados Unidos (US)",
    en: "US",
    fr: "États-Unis (US)",
    de: "USA (US)",
    it: "Stati Uniti (US)",
    pt: "Estados Unidos (US)"
  },
  "French (AZERTY)" => {
    es: "Francés (AZERTY)",
    en: "French (AZERTY)",
    fr: "Français (AZERTY)",
    de: "Französisch (AZERTY)",
    it: "Francese (AZERTY)",
    pt: "Francês (AZERTY)"
  },
  "German (QWERTZ)" => {
    es: "Alemán (QWERTZ)",
    en: "German (QWERTZ)",
    fr: "Allemand (QWERTZ)",
    de: "Deutsch (QWERTZ)",
    it: "Tedesco (QWERTZ)",
    pt: "Alemão (QWERTZ)"
  },
  "Italian" => {
    es: "Italiano", en: "Italian", fr: "Italien", de: "Italienisch", it: "Italiano", pt: "Italiano"
  },
  "Portuguese" => {
    es: "Portugués", en: "Portuguese", fr: "Portugais", de: "Portugiesisch", it: "Portoghese", pt: "Português"
  },
  "Full size" => {
    es: "Tamaño completo",
    en: "Full size",
    fr: "Taille complète",
    de: "Volle Größe",
    it: "Dimensioni complete",
    pt: "Tamanho completo"
  },
  "Linear" => {
    es: "Lineal", en: "Linear", fr: "Linéaire", de: "Linear", it: "Lineare", pt: "Linear"
  },
  "Tactile" => {
    es: "Táctil", en: "Tactile", fr: "Tactile", de: "Taktil", it: "Tattile", pt: "Tátil"
  },
  "Clicky" => {
    es: "Clic", en: "Clicky", fr: "Clic", de: "Klickend", it: "Clic", pt: "Clic"
  },
  "Optical" => {
    es: "Óptico", en: "Optical", fr: "Optique", de: "Optisch", it: "Ottico", pt: "Ótico"
  },
  "Membrane" => {
    es: "Membrana", en: "Membrane", fr: "Membrane", de: "Membran", it: "Membrana", pt: "Membrana"
  },
  "Ultrawide 1440p" => {
    es: "Ultrapanorámica 1440p",
    en: "Ultrawide 1440p",
    fr: "Ultra-large 1440p",
    de: "Ultrabreit 1440p",
    it: "Ultra-wide 1440p",
    pt: "Ultra-wide 1440p"
  },
  "Retro (Other)" => {
    es: "Retro (otras)",
    en: "Retro (Other)",
    fr: "Rétro (autre)",
    de: "Retro (andere)",
    it: "Retro (altre)",
    pt: "Retro (outras)"
  }
}

definitions = [
  {
    key: "cpu_brand",
    group: "cpu",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Marca de CPU",
      en: "CPU brand",
      fr: "Marque de CPU",
      de: "CPU-Marke",
      it: "Marca della CPU",
      pt: "Marca da CPU"
    },
    popular: %w[Intel AMD Apple Qualcomm Other]
  },
  {
    key: "cpu_cores",
    group: "cpu",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Núcleos de CPU",
      en: "CPU cores",
      fr: "Cœurs de CPU",
      de: "CPU-Kerne",
      it: "Core della CPU",
      pt: "Núcleos da CPU"
    },
    popular: %w[4 6 8 10 12 14 16 20 24 Other],
    additional: %w[2 11 15 18 28 30 32 36 64]
  },
  {
    key: "cpu_model",
    group: "cpu",
    input_type: :text,
    unit: nil,
    show_on_card: true,
    name: {
      es: "Modelo de CPU",
      en: "CPU model",
      fr: "Modèle de CPU",
      de: "CPU-Modell",
      it: "Modello della CPU",
      pt: "Modelo da CPU"
    }
  },
  {
    key: "cpu_cooler_brand",
    group: "cpu",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Marca de refrigeración",
      en: "CPU cooler brand",
      fr: "Marque de refroidissement",
      de: "Kühler-Marke",
      it: "Marca del dissipatore",
      pt: "Marca do cooler"
    },
    popular: [
      "Antec", "ARCTIC", "Asus", "be quiet!", "Cooler Master", "Corsair",
      "Deepcool", "EK", "Gamdias", "ID-COOLING", "Intel", "Jonsbo", "Lian Li",
      "MSI", "Noctua", "NZXT", "Phanteks", "Thermalright", "Thermaltake", "Other"
    ],
    additional: [
      "Akasa", "Alphacool", "Alpenföhn", "Cougar", "Cryorig", "Endorfy",
      "Enermax", "Fractal Design", "Gigabyte", "Scythe", "Silverstone", "Xigmatek"
    ]
  },
  {
    key: "cpu_cooler_type",
    group: "cpu",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Tipo de refrigeración",
      en: "CPU cooler type",
      fr: "Type de refroidissement",
      de: "Kühler-Typ",
      it: "Tipo di dissipatore",
      pt: "Tipo de cooler"
    },
    popular: [ "Air", "AIO", "Custom loop", "Other" ],
    additional: [ "Passive/Fanless" ]
  },
  {
    key: "cpu_socket",
    group: "cpu",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Zócalo de CPU",
      en: "CPU socket",
      fr: "Socket de CPU",
      de: "CPU-Sockel",
      it: "Socket della CPU",
      pt: "Socket da CPU"
    },
    popular: [
      "LGA 1851", "LGA 1700", "LGA 1200", "AM5", "AM4", "Multiple Intel",
      "Multiple AMD", "Multiple Intel and AMD", "Other"
    ],
    additional: [ "LGA 4189", "TR4", "sTRX4" ]
  },
  {
    key: "gpu_chipset",
    group: "gpu",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Chipset de GPU",
      en: "GPU chipset",
      fr: "Chipset de GPU",
      de: "GPU-Chipsatz",
      it: "Chipset della GPU",
      pt: "Chipset da GPU"
    },
    popular: %w[NVIDIA AMD Intel Apple Integrated None]
  },
  {
    key: "gpu_model",
    group: "gpu",
    input_type: :text,
    unit: nil,
    show_on_card: true,
    name: {
      es: "Modelo de GPU",
      en: "GPU model",
      fr: "Modèle de GPU",
      de: "GPU-Modell",
      it: "Modello della GPU",
      pt: "Modelo da GPU"
    }
  },
  {
    key: "gpu_memory",
    group: "gpu",
    input_type: :single_select,
    unit: "GB",
    show_on_card: false,
    name: {
      es: "Memoria de GPU",
      en: "GPU memory",
      fr: "Mémoire de GPU",
      de: "GPU-Speicher",
      it: "Memoria della GPU",
      pt: "Memória da GPU"
    },
    popular: %w[2 3 4 6 8 10 11 12 16 20 24 32 Other],
    additional: [ "<1", "1", "48", "64", "96", "128" ]
  },
  {
    key: "memory_capacity",
    group: "memory",
    input_type: :single_select,
    unit: "GB",
    show_on_card: true,
    name: {
      es: "Capacidad de memoria",
      en: "Memory capacity",
      fr: "Capacité de mémoire",
      de: "Speicherkapazität",
      it: "Capacità di memoria",
      pt: "Capacidade de memória"
    },
    popular: %w[8 12 16 24 32 48 64 128] + [ "Less than 8" ],
    additional: %w[4 6 96 192 256]
  },
  {
    key: "memory_brand",
    group: "memory",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Marca de memoria",
      en: "Memory brand",
      fr: "Marque de mémoire",
      de: "Arbeitsspeicher-Marke",
      it: "Marca di memoria",
      pt: "Marca de memória"
    },
    popular: [
      "ADATA", "Corsair", "Crucial", "G.Skill", "Kingston", "Patriot",
      "Samsung", "Teamgroup", "Other"
    ],
    additional: [
      "Gigabyte", "GoodRAM", "Mushkin", "Lexar", "PNY", "Thermaltake", "KLEVV",
      "Micron", "SK hynix", "HP", "Lenovo"
    ]
  },
  {
    key: "memory_type",
    group: "memory",
    input_type: :single_select,
    unit: nil,
    show_on_card: true,
    name: {
      es: "Tipo de memoria",
      en: "Memory type",
      fr: "Type de mémoire",
      de: "Speichertyp",
      it: "Tipo di memoria",
      pt: "Tipo de memória"
    },
    popular: [ "DDR3", "DDR4", "DDR5", "LPDDR5", "Other" ]
  },
  {
    key: "memory_modules",
    group: "memory",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Número de módulos",
      en: "Number of modules",
      fr: "Nombre de modules",
      de: "Anzahl der Module",
      it: "Numero di moduli",
      pt: "Número de módulos"
    },
    popular: %w[1 2 3 4 8 Other],
    additional: %w[6 16]
  },
  {
    key: "memory_form_factor",
    group: "memory",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Factor de forma",
      en: "Form factor",
      fr: "Format",
      de: "Bauform",
      it: "Fattore di forma",
      pt: "Fator de forma"
    },
    popular: [ "DIMM (Desktop)", "SO-DIMM (Laptop)", "Other" ]
  },
  {
    key: "storage_capacity",
    group: "storage",
    input_type: :single_select,
    unit: nil,
    show_on_card: true,
    name: {
      es: "Capacidad de almacenamiento",
      en: "Storage capacity",
      fr: "Capacité de stockage",
      de: "Speicherkapazität",
      it: "Capacità di archiviazione",
      pt: "Capacidade de armazenamento"
    },
    popular: %w[128GB 256GB 480GB 500GB 512GB 1TB 2TB 4TB Other],
    additional: [ "64GB", "3TB", "6TB", "8TB", "12TB", "16TB", "More than 16TB" ]
  },
  {
    key: "storage_interface",
    group: "storage",
    input_type: :single_select,
    unit: nil,
    show_on_card: true,
    name: {
      es: "Interfaz de almacenamiento",
      en: "Storage interface",
      fr: "Interface de stockage",
      de: "Speicherschnittstelle",
      it: "Interfaccia di archiviazione",
      pt: "Interface de armazenamento"
    },
    popular: [ "SATA HDD", "SATA SSD", "NVMe SSD", "PCIe SSD", "Other" ]
  },
  {
    key: "storage_form_factor",
    group: "storage",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Formato de almacenamiento",
      en: "Storage form factor",
      fr: "Format de stockage",
      de: "Speicher-Bauform",
      it: "Fattore di forma dello storage",
      pt: "Fator de forma do armazenamento"
    },
    popular: [ "M.2", "2.5 inch", "3.5 inch", "mSATA", "Other" ],
    additional: [ "U.2" ]
  },
  {
    key: "storage_brand",
    group: "storage",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Marca de almacenamiento",
      en: "Storage brand",
      fr: "Marque de stockage",
      de: "Speicher-Marke",
      it: "Marca di archiviazione",
      pt: "Marca de armazenamento"
    },
    popular: [
      "ADATA", "Corsair", "Crucial", "Kingston", "Samsung", "SanDisk",
      "Seagate", "SK hynix", "Toshiba", "Western Digital", "WD_BLACK", "Other"
    ],
    additional: [
      "Lexar", "Sabrent", "Teamgroup", "Intenso", "Transcend", "PNY", "Micron",
      "Kioxia"
    ]
  },
  {
    key: "motherboard_brand",
    group: "motherboard",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Marca de placa base",
      en: "Motherboard brand",
      fr: "Marque de carte mère",
      de: "Mainboard-Marke",
      it: "Marca della scheda madre",
      pt: "Marca da placa-mãe"
    },
    popular: %w[ASRock Asus Biostar Gigabyte MSI NZXT Other],
    additional: %w[Colorful EVGA Supermicro]
  },
  {
    key: "motherboard_form_factor",
    group: "motherboard",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Factor de forma de placa base",
      en: "Motherboard form factor",
      fr: "Format de carte mère",
      de: "Mainboard-Bauform",
      it: "Fattore di forma della scheda madre",
      pt: "Fator de forma da placa-mãe"
    },
    popular: [ "ATX", "Micro-ATX", "Mini-ITX", "Other" ],
    additional: [ "Extended ATX" ]
  },
  {
    key: "motherboard_networking",
    group: "motherboard",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Conectividad de red",
      en: "Motherboard networking",
      fr: "Réseau de la carte mère",
      de: "Mainboard-Netzwerk",
      it: "Connettività di rete",
      pt: "Conectividade de rede"
    },
    popular: [ "Ethernet and Wi-Fi", "Ethernet only" ],
    additional: [ "Wi-Fi only", "None" ]
  },
  {
    key: "case_brand",
    group: "case",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Marca de caja",
      en: "Case brand",
      fr: "Marque de boîtier",
      de: "Gehäuse-Marke",
      it: "Marca del case",
      pt: "Marca da caixa"
    },
    popular: [
      "Antec", "Asus", "be quiet!", "Cooler Master", "Corsair", "Deepcool",
      "Fractal Design", "Hyte", "Jonsbo", "Lian Li", "Montech", "MSI", "NZXT",
      "Phanteks", "Thermaltake", "Other"
    ],
    additional: [
      "Aerocool", "Chieftec", "Endorfy", "Mars Gaming", "Nox", "Sharkoon",
      "Silverstone", "Tempest", "Kolink"
    ]
  },
  {
    key: "case_form_factor",
    group: "case",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Tipo de caja",
      en: "Case form factor",
      fr: "Format de boîtier",
      de: "Gehäuseform",
      it: "Tipo di case",
      pt: "Tipo de caixa"
    },
    popular: [ "Mid-Tower", "Mini-Tower", "Full-Tower", "Small form factor", "Other" ],
    additional: [ "Open frame", "Home theatre PC", "Server" ]
  },
  {
    key: "case_colour",
    group: "case",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Color de caja",
      en: "Case colour",
      fr: "Couleur du boîtier",
      de: "Gehäusefarbe",
      it: "Colore del case",
      pt: "Cor da caixa"
    },
    popular: [ "Black", "White", "Silver", "Grey", "Black and white", "Multicolour", "Other" ],
    additional: [ "Blue", "Green", "Pink", "Purple", "Red", "Gold", "Wood" ]
  },
  {
    key: "psu_brand",
    group: "power",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Marca de fuente",
      en: "PSU brand",
      fr: "Marque d'alimentation",
      de: "Netzteil-Marke",
      it: "Marca dell'alimentatore",
      pt: "Marca da fonte"
    },
    popular: [
      "be quiet!", "Cooler Master", "Corsair", "EVGA", "Gigabyte", "MSI",
      "NZXT", "Seasonic", "Super Flower", "Thermaltake", "Other"
    ],
    additional: [
      "Antec", "Aerocool", "Chieftec", "Deepcool", "Enermax", "FSP Group",
      "Mars Gaming", "Nox", "Sharkoon", "Tempest", "XPG"
    ]
  },
  {
    key: "psu_wattage",
    group: "power",
    input_type: :single_select,
    unit: "W",
    show_on_card: false,
    name: {
      es: "Potencia de fuente",
      en: "PSU wattage",
      fr: "Puissance de l'alimentation",
      de: "Netzteilleistung",
      it: "Potenza dell'alimentatore",
      pt: "Potência da fonte"
    },
    popular: [
      "Less than 400W", "400", "450", "500", "550", "600", "650", "700", "750",
      "800", "850", "1000", "1200", "1600", "Other"
    ],
    additional: %w[1400 2000]
  },
  {
    key: "psu_form_factor",
    group: "power",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Formato de fuente",
      en: "PSU form factor",
      fr: "Format d'alimentation",
      de: "Netzteil-Bauform",
      it: "Fattore di forma dell'alimentatore",
      pt: "Fator de forma da fonte"
    },
    popular: [ "ATX", "SFX", "SFX-L", "Other" ],
    additional: [ "Micro ATX", "Flex ATX", "TFX" ]
  },
  {
    key: "psu_efficiency",
    group: "power",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Eficiencia de fuente",
      en: "PSU efficiency",
      fr: "Rendement de l'alimentation",
      de: "Netzteil-Effizienz",
      it: "Efficienza dell'alimentatore",
      pt: "Eficiência da fonte"
    },
    popular: [ "80+ White", "Bronze", "Silver", "Gold", "Platinum", "Titanium", "None" ]
  },
  {
    key: "rgb_lighting",
    group: "lighting",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Iluminación RGB",
      en: "RGB lighting",
      fr: "Éclairage RGB",
      de: "RGB-Beleuchtung",
      it: "Illuminazione RGB",
      pt: "Iluminação RGB"
    },
    popular: [ "Addressable (ARGB)", "Static RGB", "None" ]
  },
  {
    key: "os",
    group: "general",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Sistema operativo",
      en: "Operating system",
      fr: "Système d'exploitation",
      de: "Betriebssystem",
      it: "Sistema operativo",
      pt: "Sistema operativo"
    },
    popular: [
      "Windows 11", "Windows 10", "Linux", "macOS", "ChromeOS", "Android",
      "iOS / iPadOS", "None"
    ]
  },
  {
    key: "screen_size",
    group: "general",
    input_type: :single_select,
    unit: "\"",
    show_on_card: true,
    name: {
      es: "Tamaño de pantalla",
      en: "Screen size",
      fr: "Taille d'écran",
      de: "Bildschirmgröße",
      it: "Dimensione dello schermo",
      pt: "Tamanho do ecrã"
    },
    popular: %w[11 13 14 15 16 17 18 Other]
  },
  {
    key: "monitor_size",
    group: "general",
    input_type: :single_select,
    unit: "\"",
    show_on_card: false,
    name: {
      es: "Tamaño de monitor",
      en: "Monitor size",
      fr: "Taille du moniteur",
      de: "Monitorgröße",
      it: "Dimensione del monitor",
      pt: "Tamanho do monitor"
    },
    popular: %w[24 27 32 34 38 43 49 Other],
    additional: %w[21.5 22 25 45]
  },
  {
    key: "monitor_resolution",
    group: "general",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Resolución de monitor",
      en: "Monitor resolution",
      fr: "Résolution du moniteur",
      de: "Monitorauflösung",
      it: "Risoluzione del monitor",
      pt: "Resolução do monitor"
    },
    popular: [ "1080p (Full HD)", "1440p (QHD)", "2160p (4K UHD)", "Ultrawide 1440p", "Other" ],
    additional: [ "5K", "8K" ]
  },
  {
    key: "refresh_rate",
    group: "general",
    input_type: :single_select,
    unit: "Hz",
    show_on_card: false,
    name: {
      es: "Frecuencia de refresco",
      en: "Refresh rate",
      fr: "Fréquence de rafraîchissement",
      de: "Bildwiederholrate",
      it: "Frequenza di aggiornamento",
      pt: "Taxa de atualização"
    },
    popular: %w[60 75 100 120 144 165 180 240 360 Other],
    additional: %w[500]
  },
  {
    key: "panel_type",
    group: "general",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Tipo de panel",
      en: "Panel type",
      fr: "Type de dalle",
      de: "Paneltyp",
      it: "Tipo di pannello",
      pt: "Tipo de painel"
    },
    popular: [ "IPS", "VA", "TN", "OLED", "Mini-LED", "Other" ]
  },
  {
    key: "device_brand",
    group: "general",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Marca del dispositivo",
      en: "Device brand",
      fr: "Marque de l'appareil",
      de: "Gerätemarke",
      it: "Marca del dispositivo",
      pt: "Marca do dispositivo"
    },
    popular: [
      "Apple", "Samsung", "Google", "Xiaomi", "OnePlus", "Huawei", "Motorola",
      "Lenovo", "Asus", "Acer", "HP", "Dell", "MSI", "Razer", "Microsoft",
      "Sony", "Nintendo", "Valve", "Other"
    ]
  },
  {
    key: "device_storage",
    group: "general",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Almacenamiento del dispositivo",
      en: "Device storage",
      fr: "Stockage de l'appareil",
      de: "Gerätespeicher",
      it: "Archiviazione del dispositivo",
      pt: "Armazenamento do dispositivo"
    },
    popular: %w[64GB 128GB 256GB 512GB 1TB Other]
  },
  {
    key: "console_platform",
    group: "general",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Plataforma",
      en: "Console platform",
      fr: "Plateforme",
      de: "Konsolenplattform",
      it: "Piattaforma",
      pt: "Plataforma"
    },
    popular: [
      "PlayStation 5", "PlayStation 4", "Xbox Series X|S", "Xbox One",
      "Nintendo Switch 2", "Nintendo Switch", "Steam Deck", "ROG Ally",
      "Legion Go", "Retro (Other)", "Other"
    ]
  },
  {
    key: "connectivity",
    group: "general",
    input_type: :multi_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Conectividad",
      en: "Connectivity",
      fr: "Connectivité",
      de: "Konnektivität",
      it: "Connettività",
      pt: "Conectividade"
    },
    popular: [ "Wired", "Wireless 2.4 GHz", "Bluetooth" ]
  },
  {
    key: "keyboard_layout",
    group: "general",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Distribución del teclado",
      en: "Keyboard layout",
      fr: "Disposition du clavier",
      de: "Tastaturlayout",
      it: "Layout della tastiera",
      pt: "Layout do teclado"
    },
    popular: [
      "Spanish (ES)", "UK", "US", "French (AZERTY)", "German (QWERTZ)",
      "Italian", "Portuguese", "Other"
    ]
  },
  {
    key: "keyboard_size",
    group: "general",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Tamaño del teclado",
      en: "Keyboard size",
      fr: "Taille du clavier",
      de: "Tastaturgröße",
      it: "Dimensione della tastiera",
      pt: "Tamanho do teclado"
    },
    popular: [ "Full size", "TKL", "75%", "65%", "60%", "Other" ]
  },
  {
    key: "switch_type",
    group: "general",
    input_type: :single_select,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Tipo de interruptor",
      en: "Switch type",
      fr: "Type de commutateur",
      de: "Schaltertyp",
      it: "Tipo di switch",
      pt: "Tipo de switch"
    },
    popular: [ "Linear", "Tactile", "Clicky", "Optical", "Membrane", "Other" ]
  },
  {
    key: "battery_health",
    group: "general",
    input_type: :number,
    unit: "%",
    show_on_card: false,
    name: {
      es: "Salud de la batería",
      en: "Battery health",
      fr: "Santé de la batterie",
      de: "Batteriezustand",
      it: "Salute della batteria",
      pt: "Saúde da bateria"
    }
  },
  {
    key: "warranty_months",
    group: "general",
    input_type: :number,
    unit: "months",
    show_on_card: false,
    name: {
      es: "Garantía (meses)",
      en: "Warranty (months)",
      fr: "Garantie (mois)",
      de: "Garantie (Monate)",
      it: "Garanzia (mesi)",
      pt: "Garantia (meses)"
    }
  },
  {
    key: "includes_original_box",
    group: "general",
    input_type: :boolean,
    unit: nil,
    show_on_card: false,
    name: {
      es: "Incluye caja original",
      en: "Includes original box",
      fr: "Boîte d'origine incluse",
      de: "Originalverpackung enthalten",
      it: "Include scatola originale",
      pt: "Inclui caixa original"
    }
  }
]

localized_label = lambda do |entry|
  label = entry.is_a?(Hash) ? entry : generic_labels.fetch(entry, entry)
  label.is_a?(Hash) ? label : locales.to_h { |locale| [ locale, label ] }
end

option_value = lambda do |english_label|
  english_label == "<1" ? "lt_1" : english_label.parameterize(separator: "_")
end

definitions.each_with_index do |definition, definition_index|
  record = AttributeDefinition.find_or_initialize_by(key: definition[:key])
  record.assign_attributes(
    group: definition[:group],
    input_type: definition[:input_type],
    unit: definition[:unit],
    filterable: true,
    show_on_card: definition[:show_on_card],
    position: definition_index + 1,
    active: true
  )
  definition[:name].each { |locale, value| record.public_send(:"name_#{locale}=", value) }
  record.save!

  options = Array(definition[:popular]).map { |entry| [ entry, true ] } +
            Array(definition[:additional]).map { |entry| [ entry, false ] }

  options.each_with_index do |(entry, popular), option_index|
    label = localized_label.call(entry)
    option = record.attribute_options.find_or_initialize_by(value: option_value.call(label[:en]))
    option.assign_attributes(position: option_index + 1, popular: popular, active: true)
    label.each { |locale, value| option.public_send(:"label_#{locale}=", value) }
    option.save!
  end
end

# Category ↔ attribute assignments. A trailing "!" marks a required attribute;
# positions follow the array order. Physical leaves additionally receive the
# warranty and original-box attributes, except digital goods and the accessory
# leaves that do not carry a warranty.
desktop_specs = %w[
  cpu_brand! cpu_model! cpu_cores cpu_cooler_brand cpu_cooler_type cpu_socket
  gpu_chipset! gpu_model! gpu_memory memory_capacity! memory_brand memory_type
  memory_modules memory_form_factor storage_capacity! storage_interface
  storage_form_factor storage_brand motherboard_brand motherboard_form_factor
  motherboard_networking case_brand case_form_factor case_colour psu_brand
  psu_wattage psu_form_factor psu_efficiency rgb_lighting os warranty_months
  includes_original_box
]

console_specs = %w[console_platform! device_storage warranty_months includes_original_box]

category_specs = {
  "gaming-pcs" => desktop_specs,
  "laptops" => %w[
    device_brand! cpu_brand cpu_model gpu_chipset gpu_model memory_capacity!
    storage_capacity! screen_size! refresh_rate os battery_health keyboard_layout
    warranty_months includes_original_box
  ],
  "phones" => %w[
    device_brand! device_storage! screen_size os battery_health warranty_months
    includes_original_box
  ],
  "tablets" => %w[
    device_brand! device_storage! screen_size os battery_health warranty_months
    includes_original_box
  ],
  "consoles" => console_specs,
  "home-consoles" => console_specs,
  "handheld-consoles" => console_specs,
  "retro-consoles" => console_specs,
  "retro-handhelds" => console_specs,
  "workstations" => desktop_specs,
  "creator-rigs" => desktop_specs,
  "streaming-rigs" => desktop_specs,
  "local-ai-rigs" => desktop_specs,
  "components" => %w[],
  "gpus" => %w[
    gpu_chipset! gpu_model! gpu_memory! rgb_lighting warranty_months
    includes_original_box
  ],
  "cpus" => %w[cpu_brand! cpu_model! cpu_cores cpu_socket! includes_original_box],
  "cpu-coolers" => %w[cpu_cooler_brand! cpu_cooler_type! cpu_socket rgb_lighting],
  "motherboards" => %w[
    motherboard_brand! motherboard_form_factor! cpu_socket! memory_type
    motherboard_networking
  ],
  "motherboard-bundles" => %w[
    motherboard_brand! motherboard_form_factor! cpu_socket! memory_type
    motherboard_networking cpu_brand cpu_model memory_capacity
  ],
  "memory" => %w[
    memory_brand! memory_capacity! memory_type! memory_modules
    memory_form_factor! rgb_lighting
  ],
  "storage" => %w[
    storage_brand! storage_capacity! storage_interface! storage_form_factor
  ],
  "cases" => %w[case_brand! case_form_factor! case_colour rgb_lighting],
  "case-fans" => %w[rgb_lighting],
  "power-supplies" => %w[
    psu_brand! psu_wattage! psu_form_factor! psu_efficiency
  ],
  "expansion-cards" => %w[],
  "network-adapters" => %w[],
  "other-components" => %w[],
  "thermal-paste" => %w[],
  "peripherals" => %w[],
  "monitors" => %w[
    monitor_size! monitor_resolution! refresh_rate! panel_type
  ],
  "headphones" => %w[connectivity rgb_lighting],
  "keyboards" => %w[
    connectivity keyboard_layout! keyboard_size switch_type rgb_lighting
  ],
  "mice" => %w[connectivity rgb_lighting],
  "speakers" => %w[connectivity],
  "controllers" => %w[connectivity],
  "retro-controllers" => %w[connectivity],
  "sim-racing" => %w[],
  "webcams" => %w[],
  "vr" => %w[],
  "external-storage" => %w[
    storage_brand! storage_capacity! storage_interface! storage_form_factor
  ],
  "other-peripherals" => %w[],
  "microphones" => %w[connectivity],
  "accessories" => %w[],
  "art-decor" => %w[],
  "desk-accessories" => %w[],
  "collectibles" => %w[],
  "clothing-gear" => %w[],
  "other-accessories" => %w[],
  "games-software" => %w[],
  "games" => %w[],
  "software" => %w[]
}

leaf_extras = %w[warranty_months includes_original_box]
no_leaf_extras = %w[games software art-decor desk-accessories clothing-gear other-accessories]
definitions_by_key = AttributeDefinition.all.index_by(&:key)

Category.where(slug: category_specs.keys).includes(:children).find_each do |category|
  keys = Array(category_specs[category.slug]).map(&:dup)

  if category.children.empty? && !no_leaf_extras.include?(category.slug)
    leaf_extras.each do |key|
      keys << key unless keys.any? { |candidate| candidate.chomp("!") == key }
    end
  end

  links = keys.each_with_index.map do |key, index|
    definition = definitions_by_key.fetch(key.chomp("!"))
    link = CategoryAttribute.find_or_initialize_by(
      category: category,
      attribute_definition: definition
    )
    link.assign_attributes(required: key.end_with?("!"), position: index + 1)
    link.save!
    link
  end

  CategoryAttribute.where(category: category).where.not(id: links.map(&:id)).delete_all
end
