# frozen_string_literal: true

module Demo
  # Realistic catalogue data for the demo marketplace. Every generator returns a
  # Product whose specs use the exact option values seeded by db/seeds/attributes.rb.
  class Catalog
    Product = Struct.new(:title, :description, :specs, :base_price_cents, :tier, keyword_init: true)

    GPUS = [
      { chipset: "nvidia", model: "GeForce RTX 5090", memory: "32", price: 234_900, tier: 10 },
      { chipset: "nvidia", model: "GeForce RTX 5080", memory: "16", price: 119_900, tier: 9 },
      { chipset: "nvidia", model: "GeForce RTX 5070 Ti", memory: "16", price: 84_900, tier: 8 },
      { chipset: "nvidia", model: "GeForce RTX 5070", memory: "12", price: 61_900, tier: 7 },
      { chipset: "nvidia", model: "GeForce RTX 5060 Ti", memory: "16", price: 47_900, tier: 6 },
      { chipset: "nvidia", model: "GeForce RTX 5060", memory: "8", price: 34_900, tier: 5 },
      { chipset: "nvidia", model: "GeForce RTX 4090", memory: "24", price: 174_900, tier: 10 },
      { chipset: "nvidia", model: "GeForce RTX 4080 Super", memory: "16", price: 109_900, tier: 9 },
      { chipset: "nvidia", model: "GeForce RTX 4070 Ti Super", memory: "16", price: 82_900, tier: 8 },
      { chipset: "nvidia", model: "GeForce RTX 4070 Super", memory: "12", price: 63_900, tier: 7 },
      { chipset: "nvidia", model: "GeForce RTX 4070", memory: "12", price: 56_900, tier: 7 },
      { chipset: "nvidia", model: "GeForce RTX 4060 Ti", memory: "16", price: 44_900, tier: 6 },
      { chipset: "nvidia", model: "GeForce RTX 4060", memory: "8", price: 31_900, tier: 5 },
      { chipset: "nvidia", model: "GeForce RTX 3090", memory: "24", price: 89_900, tier: 9 },
      { chipset: "nvidia", model: "GeForce RTX 3080", memory: "10", price: 54_900, tier: 8 },
      { chipset: "nvidia", model: "GeForce RTX 3070", memory: "8", price: 39_900, tier: 7 },
      { chipset: "nvidia", model: "GeForce RTX 3060 Ti", memory: "8", price: 32_900, tier: 6 },
      { chipset: "nvidia", model: "GeForce RTX 3060", memory: "12", price: 25_900, tier: 5 },
      { chipset: "nvidia", model: "GeForce RTX 3050", memory: "8", price: 17_900, tier: 4 },
      { chipset: "nvidia", model: "GeForce RTX 2080 Ti", memory: "11", price: 39_900, tier: 7 },
      { chipset: "nvidia", model: "GeForce RTX 2070 Super", memory: "8", price: 26_900, tier: 6 },
      { chipset: "nvidia", model: "GeForce RTX 2060", memory: "6", price: 16_900, tier: 4 },
      { chipset: "amd", model: "Radeon RX 9070 XT", memory: "16", price: 79_900, tier: 8 },
      { chipset: "amd", model: "Radeon RX 9070", memory: "16", price: 64_900, tier: 7 },
      { chipset: "amd", model: "Radeon RX 9060 XT", memory: "16", price: 44_900, tier: 6 },
      { chipset: "amd", model: "Radeon RX 7900 XTX", memory: "24", price: 99_900, tier: 9 },
      { chipset: "amd", model: "Radeon RX 7900 XT", memory: "20", price: 74_900, tier: 8 },
      { chipset: "amd", model: "Radeon RX 7900 GRE", memory: "16", price: 59_900, tier: 7 },
      { chipset: "amd", model: "Radeon RX 7800 XT", memory: "16", price: 51_900, tier: 7 },
      { chipset: "amd", model: "Radeon RX 7700 XT", memory: "12", price: 42_900, tier: 6 },
      { chipset: "amd", model: "Radeon RX 7600 XT", memory: "16", price: 33_900, tier: 5 },
      { chipset: "amd", model: "Radeon RX 7600", memory: "8", price: 27_900, tier: 5 },
      { chipset: "amd", model: "Radeon RX 6950 XT", memory: "16", price: 47_900, tier: 7 },
      { chipset: "amd", model: "Radeon RX 6900 XT", memory: "16", price: 41_900, tier: 7 },
      { chipset: "amd", model: "Radeon RX 6800 XT", memory: "16", price: 37_900, tier: 6 },
      { chipset: "amd", model: "Radeon RX 6750 XT", memory: "12", price: 31_900, tier: 6 },
      { chipset: "amd", model: "Radeon RX 6700 XT", memory: "12", price: 27_900, tier: 5 },
      { chipset: "amd", model: "Radeon RX 6600 XT", memory: "8", price: 21_900, tier: 4 },
      { chipset: "amd", model: "Radeon RX 6600", memory: "8", price: 18_900, tier: 4 },
      { chipset: "amd", model: "Radeon RX 5700 XT", memory: "8", price: 17_900, tier: 4 },
      { chipset: "intel", model: "Arc B580", memory: "12", price: 29_900, tier: 5 },
      { chipset: "intel", model: "Arc B570", memory: "10", price: 24_900, tier: 4 },
      { chipset: "intel", model: "Arc A770", memory: "16", price: 25_900, tier: 4 },
      { chipset: "intel", model: "Arc A750", memory: "8", price: 19_900, tier: 4 },
      { chipset: "intel", model: "Arc A580", memory: "8", price: 15_900, tier: 3 }
    ].freeze

    CPUS = [
      { brand: "intel", model: "Core i3-10100F", socket: "lga_1200", cores: "4", price: 5_900, tier: 2 },
      { brand: "intel", model: "Core i5-10400F", socket: "lga_1200", cores: "6", price: 8_900, tier: 3 },
      { brand: "intel", model: "Core i5-11400F", socket: "lga_1200", cores: "6", price: 10_900, tier: 3 },
      { brand: "intel", model: "Core i7-11700K", socket: "lga_1200", cores: "8", price: 18_900, tier: 5 },
      { brand: "intel", model: "Core i9-11900K", socket: "lga_1200", cores: "8", price: 24_900, tier: 6 },
      { brand: "intel", model: "Core i5-12400F", socket: "lga_1700", cores: "6", price: 12_900, tier: 4 },
      { brand: "intel", model: "Core i5-12600K", socket: "lga_1700", cores: "10", price: 18_900, tier: 6 },
      { brand: "intel", model: "Core i7-12700K", socket: "lga_1700", cores: "12", price: 27_900, tier: 7 },
      { brand: "intel", model: "Core i9-12900K", socket: "lga_1700", cores: "16", price: 36_900, tier: 8 },
      { brand: "intel", model: "Core i5-13400F", socket: "lga_1700", cores: "10", price: 15_900, tier: 5 },
      { brand: "intel", model: "Core i5-13600K", socket: "lga_1700", cores: "14", price: 25_900, tier: 7 },
      { brand: "intel", model: "Core i7-13700K", socket: "lga_1700", cores: "16", price: 34_900, tier: 8 },
      { brand: "intel", model: "Core i9-13900K", socket: "lga_1700", cores: "24", price: 52_900, tier: 9 },
      { brand: "intel", model: "Core i5-14400F", socket: "lga_1700", cores: "10", price: 16_900, tier: 5 },
      { brand: "intel", model: "Core i5-14600K", socket: "lga_1700", cores: "14", price: 27_900, tier: 7 },
      { brand: "intel", model: "Core i7-14700K", socket: "lga_1700", cores: "20", price: 39_900, tier: 8 },
      { brand: "intel", model: "Core i9-14900K", socket: "lga_1700", cores: "24", price: 54_900, tier: 9 },
      { brand: "intel", model: "Core Ultra 5 245K", socket: "lga_1851", cores: "14", price: 26_900, tier: 7 },
      { brand: "intel", model: "Core Ultra 7 265K", socket: "lga_1851", cores: "20", price: 36_900, tier: 8 },
      { brand: "intel", model: "Core Ultra 9 285K", socket: "lga_1851", cores: "24", price: 56_900, tier: 9 },
      { brand: "amd", model: "Ryzen 3 3200G", socket: "am4", cores: "4", price: 4_900, tier: 2 },
      { brand: "amd", model: "Ryzen 5 3600", socket: "am4", cores: "6", price: 6_900, tier: 3 },
      { brand: "amd", model: "Ryzen 5 5600", socket: "am4", cores: "6", price: 10_900, tier: 4 },
      { brand: "amd", model: "Ryzen 5 5600X", socket: "am4", cores: "6", price: 12_900, tier: 5 },
      { brand: "amd", model: "Ryzen 7 5700X", socket: "am4", cores: "8", price: 15_900, tier: 5 },
      { brand: "amd", model: "Ryzen 7 5800X3D", socket: "am4", cores: "8", price: 24_900, tier: 7 },
      { brand: "amd", model: "Ryzen 9 5900X", socket: "am4", cores: "12", price: 28_900, tier: 8 },
      { brand: "amd", model: "Ryzen 9 5950X", socket: "am4", cores: "16", price: 36_900, tier: 8 },
      { brand: "amd", model: "Ryzen 5 7600", socket: "am5", cores: "6", price: 18_900, tier: 5 },
      { brand: "amd", model: "Ryzen 5 7600X", socket: "am5", cores: "6", price: 20_900, tier: 6 },
      { brand: "amd", model: "Ryzen 7 7700X", socket: "am5", cores: "8", price: 27_900, tier: 7 },
      { brand: "amd", model: "Ryzen 7 7800X3D", socket: "am5", cores: "8", price: 36_900, tier: 9 },
      { brand: "amd", model: "Ryzen 9 7900X", socket: "am5", cores: "12", price: 37_900, tier: 8 },
      { brand: "amd", model: "Ryzen 9 7950X", socket: "am5", cores: "16", price: 52_900, tier: 9 },
      { brand: "amd", model: "Ryzen 9 7950X3D", socket: "am5", cores: "16", price: 62_900, tier: 10 },
      { brand: "amd", model: "Ryzen 5 9600X", socket: "am5", cores: "6", price: 22_900, tier: 6 },
      { brand: "amd", model: "Ryzen 7 9700X", socket: "am5", cores: "8", price: 31_900, tier: 7 },
      { brand: "amd", model: "Ryzen 9 9900X", socket: "am5", cores: "12", price: 41_900, tier: 8 },
      { brand: "amd", model: "Ryzen 9 9950X", socket: "am5", cores: "16", price: 59_900, tier: 9 },
      { brand: "amd", model: "Ryzen 7 9800X3D", socket: "am5", cores: "8", price: 49_900, tier: 10 }
    ].freeze

    MEMORY = [
      { brand: "corsair", name: "Corsair Vengeance LPX 16 GB (2x8) DDR4-3200", capacity: "16", type: "ddr4", modules: "2", form: "dimm_desktop", price: 4_200 },
      { brand: "corsair", name: "Corsair Vengeance RGB Pro 32 GB (2x16) DDR4-3600", capacity: "32", type: "ddr4", modules: "2", form: "dimm_desktop", price: 7_900 },
      { brand: "g_skill", name: "G.Skill Trident Z Neo 32 GB (2x16) DDR4-3600", capacity: "32", type: "ddr4", modules: "2", form: "dimm_desktop", price: 8_900 },
      { brand: "kingston", name: "Kingston Fury Beast 16 GB (2x8) DDR4-3200", capacity: "16", type: "ddr4", modules: "2", form: "dimm_desktop", price: 4_500 },
      { brand: "crucial", name: "Crucial Pro 32 GB (2x16) DDR5-5600", capacity: "32", type: "ddr5", modules: "2", form: "dimm_desktop", price: 9_900 },
      { brand: "g_skill", name: "G.Skill Trident Z5 RGB 32 GB (2x16) DDR5-6000 CL30", capacity: "32", type: "ddr5", modules: "2", form: "dimm_desktop", price: 12_900 },
      { brand: "corsair", name: "Corsair Dominator Titanium 64 GB (2x32) DDR5-6000", capacity: "64", type: "ddr5", modules: "2", form: "dimm_desktop", price: 26_900 },
      { brand: "kingston", name: "Kingston Fury Renegade 32 GB (2x16) DDR5-6400", capacity: "32", type: "ddr5", modules: "2", form: "dimm_desktop", price: 13_900 },
      { brand: "teamgroup", name: "TeamGroup T-Force Delta 16 GB (2x8) DDR5-5600", capacity: "16", type: "ddr5", modules: "2", form: "dimm_desktop", price: 5_900 },
      { brand: "samsung", name: "Samsung DDR5 32 GB (1x32) 5600 SO-DIMM", capacity: "32", type: "ddr5", modules: "1", form: "so-dimm_laptop", price: 10_900 },
      { brand: "crucial", name: "Crucial 16 GB (1x16) DDR4-3200 SO-DIMM", capacity: "16", type: "ddr4", modules: "1", form: "so-dimm_laptop", price: 3_900 },
      { brand: "patriot", name: "Patriot Viper Steel 64 GB (2x32) DDR4-3600", capacity: "64", type: "ddr4", modules: "2", form: "dimm_desktop", price: 15_900 }
    ].freeze

    STORAGE = [
      { brand: "samsung", name: "Samsung 990 Pro 2 TB NVMe PCIe 4.0", capacity: "2tb", interface: "nvme_ssd", form: "m_2", price: 16_900 },
      { brand: "samsung", name: "Samsung 980 Pro 1 TB NVMe PCIe 4.0", capacity: "1tb", interface: "nvme_ssd", form: "m_2", price: 9_900 },
      { brand: "samsung", name: "Samsung 970 EVO Plus 1 TB NVMe", capacity: "1tb", interface: "nvme_ssd", form: "m_2", price: 7_900 },
      { brand: "western_digital", name: "WD Black SN850X 2 TB NVMe", capacity: "2tb", interface: "nvme_ssd", form: "m_2", price: 14_900 },
      { brand: "western_digital", name: "WD Blue SN580 1 TB NVMe", capacity: "1tb", interface: "nvme_ssd", form: "m_2", price: 6_900 },
      { brand: "crucial", name: "Crucial P3 Plus 1 TB NVMe", capacity: "1tb", interface: "nvme_ssd", form: "m_2", price: 6_500 },
      { brand: "crucial", name: "Crucial T500 2 TB NVMe PCIe 4.0", capacity: "2tb", interface: "nvme_ssd", form: "m_2", price: 14_500 },
      { brand: "kingston", name: "Kingston KC3000 1 TB NVMe", capacity: "1tb", interface: "nvme_ssd", form: "m_2", price: 8_900 },
      { brand: "kingston", name: "Kingston A400 480 GB SATA SSD", capacity: "480gb", interface: "sata_ssd", form: "2_5_inch", price: 3_200 },
      { brand: "sabrent", name: "Sabrent Rocket 4 Plus 2 TB NVMe", capacity: "2tb", interface: "nvme_ssd", form: "m_2", price: 17_900 },
      { brand: "seagate", name: "Seagate FireCuda 530 2 TB NVMe", capacity: "2tb", interface: "nvme_ssd", form: "m_2", price: 18_900 },
      { brand: "sk_hynix", name: "SK hynix Platinum P41 2 TB NVMe", capacity: "2tb", interface: "nvme_ssd", form: "m_2", price: 15_900 },
      { brand: "seagate", name: "Seagate BarraCuda 4 TB HDD", capacity: "4tb", interface: "sata_hdd", form: "3_5_inch", price: 8_900 },
      { brand: "toshiba", name: "Toshiba P300 3 TB HDD", capacity: "3tb", interface: "sata_hdd", form: "3_5_inch", price: 6_900 }
    ].freeze

    EXTERNAL_STORAGE = [
      { brand: "samsung", name: "Samsung T7 Portable SSD 1 TB", capacity: "1tb", interface: "sata_ssd", form: "2_5_inch", price: 8_900 },
      { brand: "samsung", name: "Samsung T9 Portable SSD 2 TB", capacity: "2tb", interface: "nvme_ssd", form: "2_5_inch", price: 16_900 },
      { brand: "sandisk", name: "SanDisk Extreme Portable SSD 2 TB", capacity: "2tb", interface: "nvme_ssd", form: "2_5_inch", price: 14_900 },
      { brand: "crucial", name: "Crucial X9 Pro 1 TB", capacity: "1tb", interface: "nvme_ssd", form: "2_5_inch", price: 8_500 },
      { brand: "western_digital", name: "WD My Passport 4 TB USB 3.0", capacity: "4tb", interface: "sata_hdd", form: "2_5_inch", price: 9_900 },
      { brand: "seagate", name: "Seagate Expansion 8 TB Desktop", capacity: "8tb", interface: "sata_hdd", form: "3_5_inch", price: 15_900 },
      { brand: "lexar", name: "Lexar SL500 512 GB", capacity: "512gb", interface: "nvme_ssd", form: "2_5_inch", price: 5_900 }
    ].freeze

    CASES = [
      { brand: "nzxt", name: "NZXT H5 Flow", form: "mid-tower", colour: "black", price: 8_900 },
      { brand: "nzxt", name: "NZXT H9 Elite", form: "mid-tower", colour: "white", price: 16_900 },
      { brand: "corsair", name: "Corsair 4000D Airflow", form: "mid-tower", colour: "black", price: 8_500 },
      { brand: "corsair", name: "Corsair 5000D Airflow", form: "mid-tower", colour: "white", price: 14_900 },
      { brand: "fractal_design", name: "Fractal Design North", form: "mid-tower", colour: "wood", price: 14_900 },
      { brand: "fractal_design", name: "Fractal Design Meshify C", form: "mid-tower", colour: "black", price: 9_900 },
      { brand: "lian_li", name: "Lian Li O11 Dynamic EVO", form: "mid-tower", colour: "black", price: 15_900 },
      { brand: "lian_li", name: "Lian Li A4-H2O", form: "small_form_factor", colour: "silver", price: 17_900 },
      { brand: "montech", name: "Montech AIR 903 Max", form: "mid-tower", colour: "white", price: 6_900 },
      { brand: "be_quiet", name: "be quiet! Pure Base 500DX", form: "mid-tower", colour: "black", price: 9_500 },
      { brand: "cooler_master", name: "Cooler Master NR200P", form: "small_form_factor", colour: "white", price: 9_900 },
      { brand: "hyte", name: "HYTE Y60", form: "mid-tower", colour: "black_and_white", price: 19_900 },
      { brand: "phanteks", name: "Phanteks NV5", form: "mid-tower", colour: "white", price: 12_900 },
      { brand: "thermaltake", name: "Thermaltake View 270", form: "mid-tower", colour: "black", price: 7_900 }
    ].freeze

    POWER_SUPPLIES = [
      { brand: "corsair", name: "Corsair RM750e 750W 80+ Gold", wattage: "750", form: "atx", efficiency: "gold", price: 9_900 },
      { brand: "corsair", name: "Corsair RM850x 850W 80+ Gold", wattage: "850", form: "atx", efficiency: "gold", price: 13_900 },
      { brand: "seasonic", name: "Seasonic Focus GX-750 750W 80+ Gold", wattage: "750", form: "atx", efficiency: "gold", price: 11_900 },
      { brand: "be_quiet", name: "be quiet! Pure Power 12 M 850W 80+ Gold", wattage: "850", form: "atx", efficiency: "gold", price: 12_900 },
      { brand: "cooler_master", name: "Cooler Master MWE 650 Bronze V2", wattage: "650", form: "atx", efficiency: "bronze", price: 5_900 },
      { brand: "msi", name: "MSI MAG A650BN 650W 80+ Bronze", wattage: "650", form: "atx", efficiency: "bronze", price: 5_500 },
      { brand: "nzxt", name: "NZXT C750 Gold", wattage: "750", form: "atx", efficiency: "gold", price: 10_900 },
      { brand: "super_flower", name: "Super Flower Leadex III 850W Gold", wattage: "850", form: "atx", efficiency: "gold", price: 12_500 },
      { brand: "evga", name: "EVGA 600 BR 600W 80+ Bronze", wattage: "600", form: "atx", efficiency: "bronze", price: 4_900 },
      { brand: "gigabyte", name: "Gigabyte UD750GM 750W 80+ Gold", wattage: "750", form: "atx", efficiency: "gold", price: 8_900 },
      { brand: "corsair", name: "Corsair SF750 750W 80+ Platinum SFX", wattage: "750", form: "sfx", efficiency: "platinum", price: 17_900 },
      { brand: "seasonic", name: "Seasonic Focus SGX-850 850W 80+ Gold SFX", wattage: "850", form: "sfx", efficiency: "gold", price: 15_900 }
    ].freeze

    COOLERS = [
      { brand: "noctua", name: "Noctua NH-D15", type: "air", socket: "multiple_intel_and_amd", price: 10_900 },
      { brand: "noctua", name: "Noctua NH-U12S redux", type: "air", socket: "multiple_intel_and_amd", price: 5_900 },
      { brand: "be_quiet", name: "be quiet! Dark Rock Pro 4", type: "air", socket: "multiple_intel_and_amd", price: 8_900 },
      { brand: "thermalright", name: "Thermalright Peerless Assassin 120 SE", type: "air", socket: "multiple_intel_and_amd", price: 3_900 },
      { brand: "cooler_master", name: "Cooler Master Hyper 212 Black", type: "air", socket: "multiple_intel_and_amd", price: 3_500 },
      { brand: "deepcool", name: "DeepCool AK620", type: "air", socket: "multiple_intel_and_amd", price: 6_900 },
      { brand: "arctic", name: "Arctic Liquid Freezer III 360", type: "aio", socket: "multiple_intel_and_amd", price: 9_900 },
      { brand: "nzxt", name: "NZXT Kraken 240", type: "aio", socket: "multiple_intel_and_amd", price: 13_900 },
      { brand: "corsair", name: "Corsair iCUE H150i Elite", type: "aio", socket: "multiple_intel_and_amd", price: 17_900 },
      { brand: "lian_li", name: "Lian Li Galahad II Trinity 360", type: "aio", socket: "multiple_intel_and_amd", price: 15_900 },
      { brand: "arctic", name: "Arctic P12 PWM 120mm", type: "air", socket: "other", price: 900 }
    ].freeze

    MOTHERBOARDS = [
      { brand: "asus", name: "ASUS ROG Strix B650E-F Gaming WiFi", form: "atx", socket: "am5", memory: "ddr5", networking: "ethernet_and_wi-fi", price: 25_900 },
      { brand: "msi", name: "MSI MAG B550 Tomahawk", form: "atx", socket: "am4", memory: "ddr4", networking: "ethernet_only", price: 12_900 },
      { brand: "gigabyte", name: "Gigabyte B760M DS3H DDR4", form: "micro-atx", socket: "lga_1700", memory: "ddr4", networking: "ethernet_only", price: 10_900 },
      { brand: "asrock", name: "ASRock B650M Pro RS", form: "micro-atx", socket: "am5", memory: "ddr5", networking: "ethernet_only", price: 13_900 },
      { brand: "nzxt", name: "NZXT N7 Z790 White", form: "atx", socket: "lga_1700", memory: "ddr5", networking: "ethernet_and_wi-fi", price: 28_900 },
      { brand: "asus", name: "ASUS TUF Gaming Z790-Plus WiFi", form: "atx", socket: "lga_1700", memory: "ddr5", networking: "ethernet_and_wi-fi", price: 22_900 },
      { brand: "msi", name: "MSI MPG X670E Carbon WiFi", form: "atx", socket: "am5", memory: "ddr5", networking: "ethernet_and_wi-fi", price: 39_900 },
      { brand: "gigabyte", name: "Gigabyte X570 Aorus Elite", form: "atx", socket: "am4", memory: "ddr4", networking: "ethernet_only", price: 14_900 },
      { brand: "asrock", name: "ASRock B760M-ITX/D4 WiFi", form: "mini-itx", socket: "lga_1700", memory: "ddr4", networking: "ethernet_and_wi-fi", price: 15_900 },
      { brand: "msi", name: "MSI MAG B650 Tomahawk WiFi", form: "atx", socket: "am5", memory: "ddr5", networking: "ethernet_and_wi-fi", price: 18_900 },
      { brand: "asus", name: "ASUS Prime Z890-P WiFi", form: "atx", socket: "lga_1851", memory: "ddr5", networking: "ethernet_and_wi-fi", price: 27_900 }
    ].freeze

    # Curated full builds keep prices and component pairings sensible.
    BUILDS = [
      { cpu: "Ryzen 5 3600", cpu_brand: "amd", socket: "am4", cores: "6", gpu: "GeForce RTX 2060", chipset: "nvidia", memory: "16", memory_type: "ddr4", modules: "2", storage: "512gb", storage_name: "NVMe", price: 64_900 },
      { cpu: "Ryzen 5 5600", cpu_brand: "amd", socket: "am4", cores: "6", gpu: "GeForce RTX 3060", chipset: "nvidia", memory: "16", memory_type: "ddr4", modules: "2", storage: "1tb", storage_name: "NVMe", price: 84_900 },
      { cpu: "Ryzen 7 5700X", cpu_brand: "amd", socket: "am4", cores: "8", gpu: "Radeon RX 6700 XT", chipset: "amd", memory: "32", memory_type: "ddr4", modules: "2", storage: "1tb", storage_name: "NVMe", price: 109_900 },
      { cpu: "Core i5-12400F", cpu_brand: "intel", socket: "lga_1700", cores: "6", gpu: "GeForce RTX 3060 Ti", chipset: "nvidia", memory: "16", memory_type: "ddr4", modules: "2", storage: "1tb", storage_name: "NVMe", price: 94_900 },
      { cpu: "Core i5-13600K", cpu_brand: "intel", socket: "lga_1700", cores: "14", gpu: "GeForce RTX 4070", chipset: "nvidia", memory: "32", memory_type: "ddr5", modules: "2", storage: "1tb", storage_name: "NVMe", price: 159_900 },
      { cpu: "Ryzen 5 7600", cpu_brand: "amd", socket: "am5", cores: "6", gpu: "GeForce RTX 4060", chipset: "nvidia", memory: "32", memory_type: "ddr5", modules: "2", storage: "1tb", storage_name: "NVMe", price: 119_900 },
      { cpu: "Ryzen 7 7700X", cpu_brand: "amd", socket: "am5", cores: "8", gpu: "Radeon RX 7800 XT", chipset: "amd", memory: "32", memory_type: "ddr5", modules: "2", storage: "2tb", storage_name: "NVMe", price: 169_900 },
      { cpu: "Ryzen 7 7800X3D", cpu_brand: "amd", socket: "am5", cores: "8", gpu: "GeForce RTX 4070 Super", chipset: "nvidia", memory: "32", memory_type: "ddr5", modules: "2", storage: "2tb", storage_name: "NVMe", price: 199_900 },
      { cpu: "Core i7-13700K", cpu_brand: "intel", socket: "lga_1700", cores: "16", gpu: "GeForce RTX 4080 Super", chipset: "nvidia", memory: "32", memory_type: "ddr5", modules: "2", storage: "2tb", storage_name: "NVMe", price: 249_900 },
      { cpu: "Core Ultra 7 265K", cpu_brand: "intel", socket: "lga_1851", cores: "20", gpu: "GeForce RTX 5070 Ti", chipset: "nvidia", memory: "32", memory_type: "ddr5", modules: "2", storage: "2tb", storage_name: "NVMe", price: 229_900 },
      { cpu: "Ryzen 9 7950X", cpu_brand: "amd", socket: "am5", cores: "16", gpu: "GeForce RTX 4080", chipset: "nvidia", memory: "64", memory_type: "ddr5", modules: "2", storage: "4tb", storage_name: "NVMe", price: 329_900 },
      { cpu: "Core i9-14900K", cpu_brand: "intel", socket: "lga_1700", cores: "24", gpu: "GeForce RTX 4090", chipset: "nvidia", memory: "64", memory_type: "ddr5", modules: "2", storage: "4tb", storage_name: "NVMe", price: 399_900 },
      { cpu: "Ryzen 7 9800X3D", cpu_brand: "amd", socket: "am5", cores: "8", gpu: "GeForce RTX 5080", chipset: "nvidia", memory: "32", memory_type: "ddr5", modules: "2", storage: "2tb", storage_name: "NVMe", price: 349_900 },
      { cpu: "Core i3-12100F", cpu_brand: "intel", socket: "lga_1700", cores: "4", gpu: "Arc A580", chipset: "intel", memory: "16", memory_type: "ddr4", modules: "2", storage: "512gb", storage_name: "NVMe", price: 59_900 }
    ].freeze

    LAPTOPS = [
      { brand: "asus", name: "ASUS ROG Zephyrus G14", cpu_brand: "amd", cpu: "Ryzen 9 8945HS", gpu_chipset: "nvidia", gpu: "GeForce RTX 4060", memory: "16", storage: "1tb", screen: "14", refresh: "120", os: "windows_11", price: 149_900, battery: 92 },
      { brand: "asus", name: "ASUS TUF Gaming A15", cpu_brand: "amd", cpu: "Ryzen 7 7735HS", gpu_chipset: "nvidia", gpu: "GeForce RTX 4050", memory: "16", storage: "512gb", screen: "15", refresh: "144", os: "windows_11", price: 89_900, battery: 88 },
      { brand: "lenovo", name: "Lenovo Legion 5 Pro 16", cpu_brand: "intel", cpu: "Core i7-13700HX", gpu_chipset: "nvidia", gpu: "GeForce RTX 4060", memory: "32", storage: "1tb", screen: "16", refresh: "165", os: "windows_11", price: 139_900, battery: 90 },
      { brand: "lenovo", name: "Lenovo IdeaPad Slim 3", cpu_brand: "intel", cpu: "Core i5-12450H", gpu_chipset: "integrated", gpu: "Intel UHD Graphics", memory: "8", storage: "512gb", screen: "15", refresh: "60", os: "windows_11", price: 44_900, battery: 85 },
      { brand: "acer", name: "Acer Nitro V 15", cpu_brand: "intel", cpu: "Core i5-13420H", gpu_chipset: "nvidia", gpu: "GeForce RTX 3050", memory: "16", storage: "512gb", screen: "15", refresh: "144", os: "windows_11", price: 69_900, battery: 82 },
      { brand: "msi", name: "MSI Katana 15 B13V", cpu_brand: "intel", cpu: "Core i7-13620H", gpu_chipset: "nvidia", gpu: "GeForce RTX 4060", memory: "16", storage: "1tb", screen: "15", refresh: "144", os: "windows_11", price: 99_900, battery: 80 },
      { brand: "razer", name: "Razer Blade 15 Advanced", cpu_brand: "intel", cpu: "Core i7-12800H", gpu_chipset: "nvidia", gpu: "GeForce RTX 3070 Ti", memory: "16", storage: "1tb", screen: "15", refresh: "240", os: "windows_11", price: 169_900, battery: 78 },
      { brand: "hp", name: "HP Victus 16", cpu_brand: "amd", cpu: "Ryzen 5 7640HS", gpu_chipset: "nvidia", gpu: "GeForce RTX 4050", memory: "16", storage: "512gb", screen: "16", refresh: "144", os: "windows_11", price: 79_900, battery: 86 },
      { brand: "dell", name: "Dell XPS 13 Plus", cpu_brand: "intel", cpu: "Core i7-1360P", gpu_chipset: "integrated", gpu: "Intel Iris Xe", memory: "16", storage: "512gb", screen: "13", refresh: "60", os: "windows_11", price: 109_900, battery: 89 },
      { brand: "apple", name: "MacBook Air M3 13", cpu_brand: "apple", cpu: "Apple M3", gpu_chipset: "apple", gpu: "Apple M3 GPU", memory: "16", storage: "512gb", screen: "13", refresh: "60", os: "macos", price: 129_900, battery: 94 },
      { brand: "apple", name: "MacBook Pro 14 M3 Pro", cpu_brand: "apple", cpu: "Apple M3 Pro", gpu_chipset: "apple", gpu: "Apple M3 Pro GPU", memory: "32", storage: "1tb", screen: "14", refresh: "120", os: "macos", price: 219_900, battery: 96 },
      { brand: "asus", name: "ASUS Zenbook 14 OLED", cpu_brand: "intel", cpu: "Core Ultra 7 155H", gpu_chipset: "integrated", gpu: "Intel Arc Graphics", memory: "32", storage: "1tb", screen: "14", refresh: "120", os: "windows_11", price: 119_900, battery: 91 },
      { brand: "microsoft", name: "Microsoft Surface Laptop 6", cpu_brand: "intel", cpu: "Core Ultra 5 135H", gpu_chipset: "integrated", gpu: "Intel Arc Graphics", memory: "16", storage: "512gb", screen: "13", refresh: "60", os: "windows_11", price: 104_900, battery: 87 },
      { brand: "hp", name: "HP Pavilion 15", cpu_brand: "intel", cpu: "Core i5-1235U", gpu_chipset: "integrated", gpu: "Intel Iris Xe", memory: "16", storage: "512gb", screen: "15", refresh: "60", os: "windows_11", price: 54_900, battery: 83 }
    ].freeze

    PHONES = [
      { brand: "apple", name: "iPhone 15 Pro Max", storage: "256gb", screen: "17", os: "ios_ipados", price: 109_900, battery: 91 },
      { brand: "apple", name: "iPhone 15", storage: "128gb", screen: "17", os: "ios_ipados", price: 74_900, battery: 94 },
      { brand: "apple", name: "iPhone 14", storage: "128gb", screen: "17", os: "ios_ipados", price: 54_900, battery: 87 },
      { brand: "apple", name: "iPhone 13", storage: "128gb", screen: "17", os: "ios_ipados", price: 39_900, battery: 84 },
      { brand: "apple", name: "iPhone 12", storage: "64gb", screen: "17", os: "ios_ipados", price: 27_900, battery: 79 },
      { brand: "samsung", name: "Samsung Galaxy S24 Ultra", storage: "256gb", screen: "17", os: "android", price: 99_900, battery: 93 },
      { brand: "samsung", name: "Samsung Galaxy S23", storage: "256gb", screen: "17", os: "android", price: 54_900, battery: 89 },
      { brand: "samsung", name: "Samsung Galaxy S22", storage: "128gb", screen: "17", os: "android", price: 34_900, battery: 82 },
      { brand: "samsung", name: "Samsung Galaxy S21 FE", storage: "128gb", screen: "17", os: "android", price: 24_900, battery: 80 },
      { brand: "google", name: "Google Pixel 8 Pro", storage: "256gb", screen: "17", os: "android", price: 64_900, battery: 90 },
      { brand: "google", name: "Google Pixel 8", storage: "128gb", screen: "17", os: "android", price: 47_900, battery: 91 },
      { brand: "google", name: "Google Pixel 7a", storage: "128gb", screen: "17", os: "android", price: 28_900, battery: 86 },
      { brand: "xiaomi", name: "Xiaomi 14", storage: "256gb", screen: "17", os: "android", price: 69_900, battery: 92 },
      { brand: "xiaomi", name: "Xiaomi Redmi Note 13 Pro", storage: "256gb", screen: "17", os: "android", price: 24_900, battery: 95 },
      { brand: "oneplus", name: "OnePlus 12", storage: "256gb", screen: "17", os: "android", price: 64_900, battery: 93 },
      { brand: "oneplus", name: "OnePlus 11", storage: "128gb", screen: "17", os: "android", price: 42_900, battery: 88 },
      { brand: "huawei", name: "Huawei P60 Pro", storage: "256gb", screen: "17", os: "android", price: 49_900, battery: 87 },
      { brand: "motorola", name: "Motorola Edge 50 Pro", storage: "256gb", screen: "17", os: "android", price: 39_900, battery: 90 }
    ].freeze

    TABLETS = [
      { brand: "apple", name: "iPad Pro 11 M4", storage: "256gb", screen: "11", os: "ios_ipados", price: 109_900, battery: 95 },
      { brand: "apple", name: "iPad Air 5", storage: "64gb", screen: "11", os: "ios_ipados", price: 49_900, battery: 89 },
      { brand: "apple", name: "iPad 10th generation", storage: "64gb", screen: "11", os: "ios_ipados", price: 34_900, battery: 92 },
      { brand: "apple", name: "iPad mini 6", storage: "64gb", screen: "11", os: "ios_ipados", price: 39_900, battery: 90 },
      { brand: "samsung", name: "Samsung Galaxy Tab S9", storage: "256gb", screen: "11", os: "android", price: 64_900, battery: 91 },
      { brand: "samsung", name: "Samsung Galaxy Tab S8", storage: "128gb", screen: "11", os: "android", price: 42_900, battery: 86 },
      { brand: "samsung", name: "Samsung Galaxy Tab A9+", storage: "128gb", screen: "11", os: "android", price: 19_900, battery: 94 },
      { brand: "lenovo", name: "Lenovo Tab P12", storage: "128gb", screen: "13", os: "android", price: 27_900, battery: 90 },
      { brand: "xiaomi", name: "Xiaomi Pad 6", storage: "256gb", screen: "11", os: "android", price: 26_900, battery: 93 },
      { brand: "microsoft", name: "Microsoft Surface Pro 9", storage: "256gb", screen: "13", os: "windows_11", price: 89_900, battery: 84 }
    ].freeze

    CONSOLES = [
      { platform: "playstation_5", name: "PlayStation 5 Slim", storage: "1tb", price: 49_900 },
      { platform: "playstation_5", name: "PlayStation 5 Digital Edition", storage: "1tb", price: 42_900 },
      { platform: "playstation_5", name: "PlayStation 5 con lector de discos", storage: "1tb", price: 45_900 },
      { platform: "playstation_4", name: "PlayStation 4 Pro", storage: "1tb", price: 22_900 },
      { platform: "playstation_4", name: "PlayStation 4 Slim", storage: "512gb", price: 16_900 },
      { platform: "xbox_series_x_s", name: "Xbox Series X", storage: "1tb", price: 44_900 },
      { platform: "xbox_series_x_s", name: "Xbox Series S", storage: "512gb", price: 24_900 },
      { platform: "xbox_one", name: "Xbox One X", storage: "1tb", price: 19_900 },
      { platform: "nintendo_switch_2", name: "Nintendo Switch 2", storage: "256gb", price: 46_900 },
      { platform: "nintendo_switch", name: "Nintendo Switch OLED", storage: "64gb", price: 27_900 },
      { platform: "nintendo_switch", name: "Nintendo Switch", storage: "64gb", price: 21_900 },
      { platform: "nintendo_switch", name: "Nintendo Switch Lite", storage: "64gb", price: 15_900 },
      { platform: "steam_deck", name: "Steam Deck OLED 512 GB", storage: "512gb", price: 44_900 },
      { platform: "rog_ally", name: "ASUS ROG Ally Z1 Extreme", storage: "512gb", price: 44_900 },
      { platform: "legion_go", name: "Lenovo Legion Go", storage: "512gb", price: 49_900 }
    ].freeze

    RETRO_CONSOLES = [
      { platform: "retro_other", name: "PlayStation 2 Slim", storage: "other", price: 7_900 },
      { platform: "retro_other", name: "PlayStation One", storage: "other", price: 4_900 },
      { platform: "retro_other", name: "Nintendo 64", storage: "other", price: 8_900 },
      { platform: "retro_other", name: "Super Nintendo SNES", storage: "other", price: 9_900 },
      { platform: "retro_other", name: "Sega Mega Drive II", storage: "other", price: 6_900 },
      { platform: "retro_other", name: "Sega Dreamcast", storage: "other", price: 10_900 },
      { platform: "retro_other", name: "Nintendo GameCube", storage: "other", price: 8_900 },
      { platform: "retro_other", name: "Sony PSP 3000", storage: "other", price: 7_900 }
    ].freeze

    RETRO_HANDHELDS = [
      { platform: "retro_other", name: "Game Boy Color", storage: "other", price: 6_900 },
      { platform: "retro_other", name: "Game Boy Advance SP", storage: "other", price: 9_900 },
      { platform: "retro_other", name: "Nintendo DS Lite", storage: "other", price: 5_900 },
      { platform: "retro_other", name: "Nintendo 3DS XL", storage: "other", price: 12_900 },
      { platform: "retro_other", name: "Sony PSP Street", storage: "other", price: 5_900 },
      { platform: "retro_other", name: "Atari Lynx II", storage: "other", price: 14_900 }
    ].freeze

    MONITORS = [
      { name: "LG UltraGear 27GP850", size: "27", resolution: "1440p_qhd", refresh: "165", panel: "ips", price: 27_900 },
      { name: "Samsung Odyssey G5 27", size: "27", resolution: "1440p_qhd", refresh: "144", panel: "va", price: 21_900 },
      { name: "Dell UltraSharp U2723QE", size: "27", resolution: "2160p_4k_uhd", refresh: "60", panel: "ips", price: 42_900 },
      { name: "ASUS TUF VG27AQ", size: "27", resolution: "1440p_qhd", refresh: "165", panel: "ips", price: 24_900 },
      { name: "AOC 24G2SPU", size: "24", resolution: "1080p_full_hd", refresh: "165", panel: "ips", price: 14_900 },
      { name: "MSI Optix MAG274QRF-QD", size: "27", resolution: "1440p_qhd", refresh: "165", panel: "ips", price: 29_900 },
      { name: "Gigabyte M27Q X", size: "27", resolution: "1440p_qhd", refresh: "240", panel: "ips", price: 39_900 },
      { name: "Alienware AW3423DWF", size: "34", resolution: "ultrawide_1440p", refresh: "165", panel: "oled", price: 89_900 },
      { name: "LG UltraGear 45GR95QE", size: "45", resolution: "ultrawide_1440p", refresh: "240", panel: "oled", price: 129_900 },
      { name: "Samsung Odyssey Neo G9", size: "49", resolution: "ultrawide_1440p", refresh: "240", panel: "mini-led", price: 149_900 },
      { name: "BenQ Zowie XL2546K", size: "24", resolution: "1080p_full_hd", refresh: "240", panel: "tn", price: 39_900 }
    ].freeze

    KEYBOARDS = [
      { name: "Keychron K2 Pro", layout: "us", size: "75", switch: "tactile", connectivity: %w[wireless_2_4_ghz bluetooth], price: 9_900 },
      { name: "Keychron K8 Pro ISO", layout: "spanish_es", size: "tkl", switch: "tactile", connectivity: %w[wireless_2_4_ghz bluetooth], price: 10_900 },
      { name: "Logitech MX Keys S", layout: "spanish_es", size: "full_size", switch: "membrane", connectivity: %w[wireless_2_4_ghz bluetooth], price: 9_900 },
      { name: "Glorious GMMK Pro", layout: "us", size: "75", switch: "linear", connectivity: %w[wired], price: 14_900 },
      { name: "Razer Huntsman V2", layout: "spanish_es", size: "full_size", switch: "optical", connectivity: %w[wired], price: 15_900 },
      { name: "Corsair K70 RGB Pro", layout: "spanish_es", size: "full_size", switch: "linear", connectivity: %w[wired], price: 12_900 },
      { name: "Ducky One 3 TKL", layout: "us", size: "tkl", switch: "clicky", connectivity: %w[wired], price: 11_900 },
      { name: "Akko 5075B Plus", layout: "us", size: "75", switch: "linear", connectivity: %w[wireless_2_4_ghz bluetooth], price: 7_900 },
      { name: "SteelSeries Apex Pro TKL", layout: "spanish_es", size: "tkl", switch: "linear", connectivity: %w[wired], price: 16_900 },
      { name: "Wooting 60HE", layout: "us", size: "60", switch: "linear", connectivity: %w[wired], price: 17_900 }
    ].freeze

    MICE = [
      { name: "Logitech G502 Hero", connectivity: %w[wired], price: 3_900 },
      { name: "Logitech G Pro X Superlight 2", connectivity: %w[wireless_2_4_ghz], price: 12_900 },
      { name: "Razer DeathAdder V3 Pro", connectivity: %w[wireless_2_4_ghz], price: 12_900 },
      { name: "Razer Viper V2 Pro", connectivity: %w[wireless_2_4_ghz], price: 11_900 },
      { name: "SteelSeries Rival 3 Wireless", connectivity: %w[wireless_2_4_ghz bluetooth], price: 4_900 },
      { name: "Zowie EC2-C", connectivity: %w[wired], price: 6_900 },
      { name: "Logitech MX Master 3S", connectivity: %w[wireless_2_4_ghz bluetooth], price: 8_900 },
      { name: "Razer Basilisk V3", connectivity: %w[wired], price: 4_900 }
    ].freeze

    HEADPHONES = [
      { name: "Sony WH-1000XM5", connectivity: %w[wireless_2_4_ghz bluetooth], price: 24_900 },
      { name: "HyperX Cloud II", connectivity: %w[wired], price: 6_900 },
      { name: "SteelSeries Arctis Nova 7", connectivity: %w[wireless_2_4_ghz bluetooth], price: 14_900 },
      { name: "Razer BlackShark V2 Pro", connectivity: %w[wireless_2_4_ghz], price: 13_900 },
      { name: "Sennheiser HD 599", connectivity: %w[wired], price: 12_900 },
      { name: "Logitech G335", connectivity: %w[wired], price: 4_900 },
      { name: "Apple AirPods Max", connectivity: %w[bluetooth], price: 39_900 },
      { name: "Bose QuietComfort Ultra", connectivity: %w[bluetooth], price: 32_900 }
    ].freeze

    SPEAKERS = [
      { name: "Logitech Z407", connectivity: %w[bluetooth], price: 6_900 },
      { name: "Creative Pebble V3", connectivity: %w[bluetooth], price: 3_900 },
      { name: "Edifier R1280T", connectivity: %w[wired], price: 8_900 },
      { name: "Audioengine A2+", connectivity: %w[wired bluetooth], price: 19_900 },
      { name: "Bose Companion 2 Series III", connectivity: %w[wired], price: 8_900 }
    ].freeze

    WEBCAMS = [
      { name: "Logitech C920 HD Pro", price: 5_900 },
      { name: "Logitech Brio 4K", price: 14_900 },
      { name: "Razer Kiyo Pro", price: 12_900 },
      { name: "Elgato Facecam MK.2", price: 14_900 },
      { name: "OBSBOT Tiny 2", price: 24_900 }
    ].freeze

    MICROPHONES = [
      { name: "Blue Yeti", connectivity: %w[wired], price: 9_900 },
      { name: "HyperX QuadCast S", connectivity: %w[wired], price: 12_900 },
      { name: "Elgato Wave:3", connectivity: %w[wired], price: 13_900 },
      { name: "Shure MV7", connectivity: %w[wired], price: 22_900 },
      { name: "Rode NT-USB Mini", connectivity: %w[wired], price: 8_900 }
    ].freeze

    CONTROLLERS = [
      { name: "Xbox Wireless Controller", connectivity: %w[wireless_2_4_ghz bluetooth], price: 4_900 },
      { name: "DualSense PS5 Controller", connectivity: %w[wireless_2_4_ghz bluetooth], price: 5_900 },
      { name: "Nintendo Switch Pro Controller", connectivity: %w[wireless_2_4_ghz bluetooth], price: 5_900 },
      { name: "8BitDo Ultimate Bluetooth", connectivity: %w[wireless_2_4_ghz bluetooth], price: 4_900 },
      { name: "Razer Wolverine V2 Chroma", connectivity: %w[wired], price: 8_900 },
      { name: "Scuf Reflex Pro", connectivity: %w[wireless_2_4_ghz], price: 19_900 }
    ].freeze

    RETRO_CONTROLLERS = [
      { name: "Mando original Nintendo 64", connectivity: %w[wired], price: 2_900 },
      { name: "Mando original Super Nintendo", connectivity: %w[wired], price: 2_490 },
      { name: "Mando Sega Mega Drive 6 botones", connectivity: %w[wired], price: 1_990 },
      { name: "Arcade Stick Hori Real Arcade Pro", connectivity: %w[wired], price: 8_900 }
    ].freeze

    SIM_RACING = [
      { name: "Logitech G29 Driving Force", price: 19_900 },
      { name: "Logitech G923 Trueforce", price: 29_900 },
      { name: "Thrustmaster T300RS GT", price: 34_900 },
      { name: "Fanatec CSL DD 8Nm", price: 49_900 },
      { name: "Moza R5 Bundle", price: 44_900 }
    ].freeze

    VR = [
      { name: "Meta Quest 3 128 GB", price: 39_900 },
      { name: "Meta Quest 2 256 GB", price: 21_900 },
      { name: "Valve Index Full Kit", price: 79_900 },
      { name: "PlayStation VR2", price: 42_900 },
      { name: "Pico 4 Ultra", price: 39_900 }
    ].freeze

    CASE_FANS = [
      { name: "Noctua NF-A12x25 PWM", price: 2_990 },
      { name: "Arctic P12 PWM PST", price: 690 },
      { name: "Lian Li UNI Fan SL120 V2", price: 2_490 },
      { name: "Corsair QL120 RGB", price: 2_790 },
      { name: "be quiet! Silent Wings 4", price: 2_190 }
    ].freeze

    EXPANSION_CARDS = [
      { name: "Elgato 4K60 Pro MK.2", price: 19_900 },
      { name: "ASUS Xonar AE 7.1", price: 6_900 },
      { name: "TP-Link Archer TXE75E WiFi 6E", price: 4_900 },
      { name: "StarTech 4-Port USB 3.2 PCIe", price: 3_900 }
    ].freeze

    NETWORK_ADAPTERS = [
      { name: "TP-Link Archer TX50E WiFi 6", price: 3_490 },
      { name: "ASUS PCE-AX58BT WiFi 6", price: 4_490 },
      { name: "Intel AX200 PCIe", price: 1_990 },
      { name: "TP-Link TG-3468 Gigabit Ethernet", price: 1_290 }
    ].freeze

    THERMAL_PASTE = [
      { name: "Arctic MX-6 4g", price: 790 },
      { name: "Thermal Grizzly Kryonaut 1g", price: 990 },
      { name: "Noctua NT-H1 3.5g", price: 890 },
      { name: "Cooler Master MasterGel Pro V2", price: 790 }
    ].freeze

    GAMES = [
      { name: "Elden Ring", platform: "PS5", price: 3_490 },
      { name: "The Legend of Zelda: Tears of the Kingdom", platform: "Nintendo Switch", price: 4_290 },
      { name: "Cyberpunk 2077: Ultimate Edition", platform: "PC", price: 4_990 },
      { name: "Baldur's Gate 3", platform: "PC", price: 4_990 },
      { name: "God of War Ragnarök", platform: "PS5", price: 3_990 },
      { name: "Forza Horizon 5", platform: "Xbox Series X", price: 2_990 },
      { name: "Super Mario Odyssey", platform: "Nintendo Switch", price: 3_990 },
      { name: "Red Dead Redemption 2", platform: "PS4", price: 1_990 },
      { name: "Hogwarts Legacy", platform: "PS5", price: 2_990 },
      { name: "Gran Turismo 7", platform: "PS5", price: 2_490 },
      { name: "Resident Evil 4 Remake", platform: "PS5", price: 2_990 },
      { name: "Hades II", platform: "PC", price: 2_490 }
    ].freeze

    SOFTWARE = [
      { name: "Windows 11 Pro", price: 9_900 },
      { name: "Microsoft Office 2021 Home & Business", price: 12_900 },
      { name: "Adobe Creative Cloud 1 año", price: 29_900 },
      { name: "Norton 360 Deluxe 1 año", price: 3_990 },
      { name: "DaVinci Resolve Studio", price: 24_900 },
      { name: "Microsoft 365 Family 1 año", price: 6_990 }
    ].freeze

    OTHER_COMPONENTS = [
      { name: "Kit de cables personalizados para PSU", price: 3_900 },
      { name: "Soporte vertical para GPU", price: 2_490 },
      { name: "Hub PWM para ventiladores", price: 1_490 },
      { name: "Adaptador M.2 a PCIe", price: 1_990 }
    ].freeze

    OTHER_PERIPHERALS = [
      { name: "Elgato Stream Deck MK.2", price: 12_900 },
      { name: "Stream Deck XL", price: 22_900 },
      { name: "Soporte para monitor de doble brazo", price: 6_900 },
      { name: "Hub USB-C 8 en 1", price: 3_990 },
      { name: "Alfombrilla XXL RGB", price: 2_490 }
    ].freeze

    ACCESSORIES = {
      "art-decor" => [
        { name: "Póster enmarcado Cyberpunk 2077", price: 3_900 },
        { name: "Cuadro minimalista de hardware vintage", price: 4_900 },
        { name: "Neón LED \"Game On\"", price: 2_990 },
        { name: "Set de 3 láminas de arquitectura PC", price: 2_490 }
      ],
      "collectibles" => [
        { name: "Figura coleccionista Zelda: Tears of the Kingdom", price: 7_900 },
        { name: "Funko Pop! Master Chief", price: 1_990 },
        { name: "Estatua de Geralt de Rivia 25 cm", price: 12_900 },
        { name: "Amibo de Mario edición limitada", price: 2_490 },
        { name: "Figura articulada de Samus Aran", price: 8_900 }
      ],
      "desk-accessories" => [
        { name: "Alfombrilla de escritorio de cuero", price: 2_990 },
        { name: "Organizador de cables de madera", price: 1_990 },
        { name: "Soporte para auriculares de aluminio", price: 2_490 },
        { name: "Reposamuñecas de gel", price: 1_490 }
      ],
      "clothing-gear" => [
        { name: "Camiseta PCMarket edición limitada", price: 1_990 },
        { name: "Sudadera con capucha gaming", price: 4_490 },
        { name: "Gorra esports negra", price: 1_790 },
        { name: "Camiseta retro arcade", price: 2_190 }
      ],
      "other-accessories" => [
        { name: "Llavero de GPU de goma", price: 790 },
        { name: "Pegatinas de hardware", price: 590 },
        { name: "Funda para teclado 75%", price: 1_990 },
        { name: "Botella térmica PCMarket", price: 1_990 }
      ]
    }.freeze

    def initialize(rng: Random.new)
      @rng = rng
    end

    def product_for(category)
      case category.slug
      when "gaming-pcs" then gaming_pc
      when "creator-rigs", "streaming-rigs", "local-ai-rigs" then workstation(category.slug)
      when "laptops" then laptop
      when "phones" then phone
      when "tablets" then tablet
      when "home-consoles", "handheld-consoles" then console
      when "retro-consoles" then retro_console
      when "retro-handhelds" then retro_handheld
      when "gpus" then gpu
      when "cpus" then cpu
      when "memory" then memory
      when "storage" then storage
      when "external-storage" then external_storage
      when "cases" then pc_case
      when "case-fans" then case_fan
      when "power-supplies" then power_supply
      when "cpu-coolers" then cooler
      when "motherboards" then motherboard
      when "motherboard-bundles" then motherboard_bundle
      when "thermal-paste" then thermal_paste
      when "expansion-cards" then expansion_card
      when "network-adapters" then network_adapter
      when "other-components" then other_component
      when "monitors" then monitor
      when "keyboards" then keyboard
      when "mice" then mouse
      when "headphones" then headphone
      when "speakers" then speaker
      when "webcams" then webcam
      when "microphones" then microphone
      when "controllers" then controller
      when "retro-controllers" then retro_controller
      when "sim-racing" then sim_racing
      when "vr" then vr_headset
      when "other-peripherals" then other_peripheral
      when "games" then game
      when "software" then software
      else accessory(category.slug)
      end
    end

    private

    attr_reader :rng

    def sample(list)
      list[rng.rand(list.length)]
    end

    def vary(cents, spread: 0.08)
      (cents * (1 + ((rng.rand * 2 - 1) * spread))).round
    end

    def gaming_pc
      build = sample(BUILDS)
      memory_type = build[:memory_type]
      gpu_spec = GPUS.find { |gpu| gpu[:model] == build[:gpu] } || { memory: "12" }
      storage_label = build[:storage].sub("tb", " TB").sub("gb", " GB")
      title = "#{build[:cpu]} · #{build[:gpu]} · #{build[:memory]} GB #{memory_type.upcase} · " \
              "#{storage_label} #{build[:storage_name]}"

      product(
        title: title,
        description: "Torre gaming montada y probada. #{build[:cpu]} junto a #{build[:gpu]}, " \
                     "#{build[:memory]} GB de RAM #{memory_type.upcase} y SSD #{build[:storage_name]} de " \
                     "#{storage_label}. Incluye Windows instalado, " \
                     "cableado ordenado y todas las cajas de los componentes. Se entrega limpia y con " \
                     "pruebas de estrés pasadas.",
        specs: {
          "cpu_brand" => build[:cpu_brand],
          "cpu_model" => build[:cpu],
          "cpu_cores" => build[:cores],
          "cpu_socket" => build[:socket],
          "cpu_cooler_brand" => "cooler_master",
          "cpu_cooler_type" => "air",
          "gpu_chipset" => build[:chipset],
          "gpu_model" => build[:gpu],
          "gpu_memory" => gpu_spec[:memory],
          "memory_capacity" => build[:memory],
          "memory_type" => memory_type,
          "memory_modules" => build[:modules],
          "memory_form_factor" => "dimm_desktop",
          "storage_capacity" => build[:storage],
          "storage_interface" => "nvme_ssd",
          "storage_form_factor" => "m_2",
          "storage_brand" => "samsung",
          "motherboard_brand" => "msi",
          "motherboard_form_factor" => "atx",
          "motherboard_networking" => "ethernet_and_wi-fi",
          "case_brand" => "corsair",
          "case_form_factor" => "mid-tower",
          "case_colour" => "black",
          "psu_brand" => "corsair",
          "psu_wattage" => build[:price] > 200_000 ? "850" : "750",
          "psu_form_factor" => "atx",
          "psu_efficiency" => "gold",
          "rgb_lighting" => rng.rand < 0.5 ? "addressable_argb" : "none",
          "os" => "windows_11",
          "includes_original_box" => rng.rand < 0.75,
          "warranty_months" => 12
        },
        price_cents: build[:price],
        tier: tier_for_price(build[:price], 90_000, 200_000)
      )
    end

    def workstation(slug)
      base = gaming_pc
      prefix = { "creator-rigs" => "Creator", "streaming-rigs" => "Streaming", "local-ai-rigs" => "Local AI" }.fetch(slug)
      base.title = "#{prefix} · #{base.title}"
      base.description = "Equipo #{prefix.downcase} montado con componentes de gama alta y refrigeración " \
                         "silenciosa. Configuración estable para jornadas largas de trabajo, renderizado, " \
                         "directos o modelos de IA locales. #{base.description}"
      base.base_price_cents = (base.base_price_cents * (1.15 + rng.rand * 0.35)).round
      base.tier = "pro-gamer-pcs" if slug == "streaming-rigs"
      base
    end

    def laptop
      item = sample(LAPTOPS)
      product(
        title: "#{item[:name]} · #{item[:cpu]} · #{item[:memory]} GB · #{capacity_label(item[:storage])}",
        description: "Portátil #{item[:name]} en perfecto estado de funcionamiento. Pantalla de " \
                     "#{item[:screen].sub('_', ',')}\" a #{item[:refresh]} Hz, #{item[:cpu]}, " \
                     "#{item[:memory]} GB de RAM y #{capacity_label(item[:storage])} de almacenamiento. " \
                     "Batería con salud del #{item[:battery]}%. Incluye cargador original.",
        specs: {
          "device_brand" => item[:brand],
          "cpu_brand" => item[:cpu_brand],
          "cpu_model" => item[:cpu],
          "gpu_chipset" => item[:gpu_chipset],
          "gpu_model" => item[:gpu],
          "memory_capacity" => item[:memory],
          "storage_capacity" => item[:storage],
          "screen_size" => item[:screen],
          "refresh_rate" => item[:refresh],
          "os" => item[:os],
          "battery_health" => item[:battery],
          "keyboard_layout" => "spanish_es",
          "warranty_months" => rng.rand < 0.5 ? 0 : 12,
          "includes_original_box" => rng.rand < 0.7
        },
        price_cents: item[:price],
        tier: tier_for_price(item[:price], 80_000, 150_000)
      )
    end

    def phone
      item = sample(PHONES)
      product(
        title: "#{item[:name]} #{capacity_label(item[:storage])} · #{item[:battery]}% batería",
        description: "Smartphone #{item[:name]} libre de operador. Batería al #{item[:battery]}%, " \
                     "pantalla sin arañazos y funcionamiento perfecto. Se entrega con funda y " \
                     "protector de pantalla. Ideal como segundo móvil o para renovar el tuyo.",
        specs: {
          "device_brand" => item[:brand],
          "device_storage" => item[:storage],
          "screen_size" => item[:screen],
          "os" => item[:os],
          "battery_health" => item[:battery],
          "warranty_months" => rng.rand < 0.4 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.6
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def tablet
      item = sample(TABLETS)
      product(
        title: "#{item[:name]} #{capacity_label(item[:storage])}",
        description: "Tablet #{item[:name]} con #{capacity_label(item[:storage])} de almacenamiento. " \
                     "Ideal para estudiar, dibujar o ver series. Pantalla impecable y batería al " \
                     "#{item[:battery]}%. Incluye cable de carga original.",
        specs: {
          "device_brand" => item[:brand],
          "device_storage" => item[:storage],
          "screen_size" => item[:screen],
          "os" => item[:os],
          "battery_health" => item[:battery],
          "warranty_months" => rng.rand < 0.4 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.65
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def console
      item = sample(CONSOLES)
      product(
        title: "#{item[:name]} · #{capacity_label(item[:storage])}",
        description: "Consola #{item[:name]} en buen estado, probada y sin sobrecalentamiento. " \
                     "Incluye mando original, cables HDMI y de corriente. Almacenamiento de " \
                     "#{capacity_label(item[:storage])}. Se puede probar antes de comprar en mano.",
        specs: {
          "console_platform" => item[:platform],
          "device_storage" => item[:storage],
          "warranty_months" => rng.rand < 0.4 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.75
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def retro_console
      item = sample(RETRO_CONSOLES)
      product(
        title: "#{item[:name]} · consola retro probada",
        description: "Consola retro #{item[:name]}. Funciona correctamente, lector limpio y " \
                     "todos los puertos probados. Se entrega con cables y un mando compatible. " \
                     "Perfecta para coleccionistas y amantes de los clásicos.",
        specs: {
          "console_platform" => item[:platform],
          "device_storage" => item[:storage],
          "warranty_months" => 0,
          "includes_original_box" => rng.rand < 0.4
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def retro_handheld
      item = sample(RETRO_HANDHELDS)
      product(
        title: "#{item[:name]} · pantalla y botones revisados",
        description: "Portátil retro #{item[:name]} restaurada. Pantalla sin píxeles muertos, " \
                     "botones con buen tacto y batería sustituida. Incluye cargador compatible. " \
                     "Una pieza ideal para tu colección.",
        specs: {
          "console_platform" => item[:platform],
          "device_storage" => item[:storage],
          "warranty_months" => 0,
          "includes_original_box" => rng.rand < 0.25
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def gpu
      item = sample(GPUS)
      product(
        title: "#{item[:model]} #{item[:memory]} GB",
        description: "Tarjeta gráfica #{item[:model]} de #{item[:memory]} GB. Sin coil whine, " \
                     "temperaturas controladas y sin uso intensivo de minería. Se entrega con " \
                     "adaptador de alimentación y caja original cuando se indica. Ideal para " \
                     "jugar en 1080p o 1440p con ajustes altos.",
        specs: {
          "gpu_chipset" => item[:chipset],
          "gpu_model" => item[:model],
          "gpu_memory" => item[:memory],
          "rgb_lighting" => rng.rand < 0.35 ? "static_rgb" : "none",
          "warranty_months" => rng.rand < 0.5 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.65
        },
        price_cents: item[:price],
        tier: label_tier(item[:price], 25_000, 60_000, "gpus")
      )
    end

    def cpu
      item = sample(CPUS)
      product(
        title: "#{item[:model]} · socket #{item[:socket].upcase.tr('_', ' ')}",
        description: "Procesador #{item[:model]} de #{item[:cores]} núcleos. Extraído de un equipo " \
                     "funcional, sin pines doblados y con pasta térmica limpia. Incluye el disipador " \
                     "original cuando corresponde. Perfecto para actualizar tu plataforma.",
        specs: {
          "cpu_brand" => item[:brand],
          "cpu_model" => item[:model],
          "cpu_cores" => item[:cores],
          "cpu_socket" => item[:socket],
          "includes_original_box" => rng.rand < 0.55,
          "warranty_months" => rng.rand < 0.4 ? 12 : 0
        },
        price_cents: item[:price],
        tier: label_tier(item[:price], 12_000, 30_000, "cpus")
      )
    end

    def memory
      item = sample(MEMORY)
      product(
        title: "#{item[:name]}",
        description: "Kit de memoria RAM #{item[:name]}. Probado con MemTest86 sin errores. " \
                     "Compatible con placas #{item[:type].upcase}. Se entrega en su blister o " \
                     "caja original. Amplía tu equipo con un kit fiable.",
        specs: {
          "memory_brand" => item[:brand],
          "memory_capacity" => item[:capacity],
          "memory_type" => item[:type],
          "memory_modules" => item[:modules],
          "memory_form_factor" => item[:form],
          "rgb_lighting" => item[:name].include?("RGB") ? "addressable_argb" : "none",
          "warranty_months" => rng.rand < 0.5 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.7
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def storage
      item = sample(STORAGE)
      product(
        title: "#{item[:name]}",
        description: "Unidad de almacenamiento #{item[:name]}. Con horas de uso bajas y salud " \
                     "verificada con CrystalDiskInfo. Se entrega formateada y lista para usar. " \
                     "Ideal para ampliar tu PC o montar un equipo nuevo.",
        specs: {
          "storage_brand" => item[:brand],
          "storage_capacity" => item[:capacity],
          "storage_interface" => item[:interface],
          "storage_form_factor" => item[:form],
          "warranty_months" => rng.rand < 0.5 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.5
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def external_storage
      item = sample(EXTERNAL_STORAGE)
      product(
        title: "#{item[:name]}",
        description: "Disco externo #{item[:name]}. Funciona perfectamente, sin sectores defectuosos " \
                     "y con todos los cables originales. Ideal para copias de seguridad, fotografía " \
                     "o llevar tus juegos contigo.",
        specs: {
          "storage_brand" => item[:brand],
          "storage_capacity" => item[:capacity],
          "storage_interface" => item[:interface],
          "storage_form_factor" => item[:form],
          "warranty_months" => rng.rand < 0.4 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.55
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def pc_case
      item = sample(CASES)
      product(
        title: "#{item[:name]} · #{item[:form].tr('-', ' ')} #{item[:colour].tr('_', ' ')}",
        description: "Caja #{item[:name]} con laterales de cristal templado y buen flujo de aire. " \
                     "Sin golpes ni arañazos visibles. Incluye los ventiladores originales y todos " \
                     "los tornillos. Compatible con placas ATX y refrigeración líquida.",
        specs: {
          "case_brand" => item[:brand],
          "case_form_factor" => item[:form],
          "case_colour" => item[:colour],
          "rgb_lighting" => rng.rand < 0.4 ? "addressable_argb" : "none",
          "warranty_months" => rng.rand < 0.3 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.4
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def case_fan
      item = sample(CASE_FANS)
      product(
        title: "#{item[:name]} 120 mm",
        description: "Ventilador para caja #{item[:name]}. Funciona en silencio y sin rodamientos " \
                     "ruidosos. Incluye tornillos y cable de conexión. Se pueden combinar varias " \
                     "unidades para completar tu configuración.",
        specs: { "rgb_lighting" => item[:name].include?("RGB") ? "addressable_argb" : "none" },
        price_cents: item[:price],
        tier: nil
      )
    end

    def power_supply
      item = sample(POWER_SUPPLIES)
      product(
        title: "#{item[:name]}",
        description: "Fuente de alimentación #{item[:name]}. Probada bajo carga y con protecciones " \
                     "funcionando. Incluye todos los cables modulares originales y bolsa. " \
                     "Suficiente para gráficas de gama alta y configuraciones con RGB.",
        specs: {
          "psu_brand" => item[:brand],
          "psu_wattage" => item[:wattage],
          "psu_form_factor" => item[:form],
          "psu_efficiency" => item[:efficiency],
          "warranty_months" => rng.rand < 0.5 ? 24 : 0,
          "includes_original_box" => rng.rand < 0.65
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def cooler
      item = sample(COOLERS)
      product(
        title: "#{item[:name]} · refrigeración #{item[:type] == 'aio' ? 'líquida' : 'por aire'}",
        description: "Refrigeración #{item[:name]}. Mantiene temperaturas bajas incluso con CPUs " \
                     "de gama alta. Incluye anclajes para Intel y AMD, pasta térmica y ventiladores " \
                     "originales. Sin fugas ni ruidos extraños.",
        specs: {
          "cpu_cooler_brand" => item[:brand],
          "cpu_cooler_type" => item[:type],
          "cpu_socket" => item[:socket],
          "rgb_lighting" => rng.rand < 0.45 ? "addressable_argb" : "none",
          "warranty_months" => rng.rand < 0.4 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.6
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def motherboard
      item = sample(MOTHERBOARDS)
      product(
        title: "#{item[:name]} · socket #{item[:socket].upcase.tr('_', ' ')}",
        description: "Placa base #{item[:name]}. Funciona perfectamente, sin pines doblados ni " \
                     "condensadores dañados. Incluye chapita trasera, cables SATA y caja original. " \
                     "Compatible con memorias #{item[:memory].upcase} y procesadores de su socket.",
        specs: {
          "motherboard_brand" => item[:brand],
          "motherboard_form_factor" => item[:form],
          "cpu_socket" => item[:socket],
          "memory_type" => item[:memory],
          "motherboard_networking" => item[:networking],
          "warranty_months" => rng.rand < 0.45 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.65
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def motherboard_bundle
      cpu_item = sample(CPUS.select { |c| c[:socket] != "lga_1200" })
      board = MOTHERBOARDS.find { |m| m[:socket] == cpu_item[:socket] } || sample(MOTHERBOARDS)
      memory = MEMORY.select { |m| m[:form] == "dimm_desktop" && m[:type] == board[:memory] }.then { |list| sample(list.presence || MEMORY) }

      product(
        title: "#{cpu_item[:model]} + #{board[:name]} + #{memory[:capacity]} GB #{memory[:type].upcase}",
        description: "Pack de actualización con procesador #{cpu_item[:model]}, placa base " \
                     "#{board[:name]} y #{memory[:capacity]} GB de RAM #{memory[:type].upcase}. " \
                     "Todos los componentes han sido probados juntos. Ideal para renovar tu equipo " \
                     "sin buscar compatibilidades.",
        specs: {
          "motherboard_brand" => board[:brand],
          "motherboard_form_factor" => board[:form],
          "cpu_socket" => board[:socket],
          "memory_type" => board[:memory],
          "motherboard_networking" => board[:networking],
          "cpu_brand" => cpu_item[:brand],
          "cpu_model" => cpu_item[:model],
          "memory_capacity" => memory[:capacity],
          "warranty_months" => 12,
          "includes_original_box" => rng.rand < 0.5
        },
        price_cents: (cpu_item[:price] + board[:price] + memory[:price]) * 0.92,
        tier: nil
      )
    end

    def thermal_paste
      item = sample(THERMAL_PASTE)
      product(
        title: "#{item[:name]} · pasta térmica",
        description: "Pasta térmica #{item[:name]}, sin abrir o con un uso mínimo. Mejora las " \
                     "temperaturas de tu CPU o GPU. Se entrega en su jeringa original.",
        specs: { "warranty_months" => 0, "includes_original_box" => false },
        price_cents: item[:price],
        tier: nil
      )
    end

    def expansion_card
      item = sample(EXPANSION_CARDS)
      product(
        title: item[:name],
        description: "#{item[:name]} para ranura PCIe. Funciona correctamente y viene con sus " \
                     "cables y CD de drivers cuando corresponde. Amplía tu PC con captura de vídeo, " \
                     "sonido o puertos extra.",
        specs: { "warranty_months" => rng.rand < 0.3 ? 12 : 0, "includes_original_box" => rng.rand < 0.6 },
        price_cents: item[:price],
        tier: nil
      )
    end

    def network_adapter
      item = sample(NETWORK_ADAPTERS)
      product(
        title: item[:name],
        description: "Adaptador de red #{item[:name]}. Mejora la conexión de tu equipo con WiFi " \
                     "rápido o Ethernet estable. Incluye antenas y chapita de perfil bajo.",
        specs: { "warranty_months" => 12, "includes_original_box" => rng.rand < 0.7 },
        price_cents: item[:price],
        tier: nil
      )
    end

    def other_component
      item = sample(OTHER_COMPONENTS)
      product(
        title: item[:name],
        description: "#{item[:name]} en buen estado. Una pieza útil para terminar tu montaje o " \
                     "mantener tu equipo ordenado. Se entrega con todos los accesorios mostrados.",
        specs: { "warranty_months" => 0, "includes_original_box" => rng.rand < 0.3 },
        price_cents: item[:price],
        tier: nil
      )
    end

    def monitor
      item = sample(MONITORS)
      product(
        title: "#{item[:name]} · #{item[:size]}\" #{item[:resolution].split('_').first} #{item[:refresh]} Hz",
        description: "Monitor #{item[:name]} de #{item[:size]} pulgadas y #{item[:refresh]} Hz. " \
                     "Panel #{item[:panel].upcase}, sin píxeles muertos ni manchas. Incluye base, " \
                     "cable DisplayPort/HDMI y fuente. Ideal para gaming o productividad.",
        specs: {
          "monitor_size" => item[:size],
          "monitor_resolution" => item[:resolution],
          "refresh_rate" => item[:refresh],
          "panel_type" => item[:panel],
          "warranty_months" => rng.rand < 0.4 ? 24 : 0,
          "includes_original_box" => rng.rand < 0.6
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def keyboard
      item = sample(KEYBOARDS)
      product(
        title: "#{item[:name]} · #{item[:switch]} · #{item[:layout].upcase.tr('_', '-')}",
        description: "Teclado mecánico #{item[:name]} con switches #{item[:switch]} y distribución " \
                     "#{item[:layout].tr('_', ' ')}. Todas las teclas funcionan, sin doble pulsación. " \
                     "Incluye cable trenzado y keycaps originales.",
        specs: {
          "connectivity" => item[:connectivity],
          "keyboard_layout" => item[:layout],
          "keyboard_size" => item[:size],
          "switch_type" => item[:switch],
          "rgb_lighting" => item[:name].include?("RGB") ? "addressable_argb" : (rng.rand < 0.3 ? "static_rgb" : "none"),
          "warranty_months" => rng.rand < 0.3 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.5
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def mouse
      item = sample(MICE)
      product(
        title: "#{item[:name]} · ratón gaming",
        description: "Ratón #{item[:name]}. Sin doble clic ni desgaste en los deslizadores. " \
                     "Incluye receptor inalámbrico o cable según modelo. Sensor preciso y " \
                     "botones configurables.",
        specs: {
          "connectivity" => item[:connectivity],
          "rgb_lighting" => rng.rand < 0.5 ? "static_rgb" : "none",
          "warranty_months" => rng.rand < 0.3 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.45
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def headphone
      item = sample(HEADPHONES)
      product(
        title: "#{item[:name]} · auriculares",
        description: "Auriculares #{item[:name]}. Sonido limpio, almohadillas en buen estado y " \
                     "micrófono probado. Incluye estuche y cables originales cuando corresponde.",
        specs: {
          "connectivity" => item[:connectivity],
          "rgb_lighting" => "none",
          "warranty_months" => rng.rand < 0.3 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.55
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def speaker
      item = sample(SPEAKERS)
      product(
        title: "#{item[:name]} · altavoces de escritorio",
        description: "Altavoces #{item[:name]} con sonido equilibrado y buenos graves. Sin ruidos " \
                     "ni distorsión. Incluye cables y mando cuando corresponde.",
        specs: {
          "connectivity" => item[:connectivity],
          "warranty_months" => rng.rand < 0.2 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.5
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def webcam
      item = sample(WEBCAMS)
      product(
        title: "#{item[:name]} · webcam",
        description: "Webcam #{item[:name]} para streaming y videollamadas. Imagen nítida, " \
                     "micrófono integrado y montaje funcional. Incluye cable USB original.",
        specs: { "warranty_months" => rng.rand < 0.3 ? 12 : 0, "includes_original_box" => rng.rand < 0.5 },
        price_cents: item[:price],
        tier: nil
      )
    end

    def microphone
      item = sample(MICROPHONES)
      product(
        title: "#{item[:name]} · micrófono USB",
        description: "Micrófono #{item[:name]} con patrón de captación nítido. Ideal para " \
                     "podcast, streaming o reuniones. Incluye soporte, cable y filtro cuando " \
                     "corresponde.",
        specs: {
          "connectivity" => item[:connectivity],
          "warranty_months" => rng.rand < 0.3 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.55
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def controller
      item = sample(CONTROLLERS)
      product(
        title: "#{item[:name]} · mando",
        description: "Mando #{item[:name]} con sticks y gatillos en buen estado. Sin drift. " \
                     "Incluye cable de carga o pilas según modelo. Compatible con PC y consola.",
        specs: {
          "connectivity" => item[:connectivity],
          "warranty_months" => rng.rand < 0.25 ? 12 : 0,
          "includes_original_box" => rng.rand < 0.4
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def retro_controller
      item = sample(RETRO_CONTROLLERS)
      product(
        title: "#{item[:name]} · mando retro",
        description: "Mando retro #{item[:name]} con botones y cable revisados. Funciona " \
                     "perfectamente con la consola correspondiente. Se entrega limpio y probado.",
        specs: {
          "connectivity" => item[:connectivity],
          "warranty_months" => 0,
          "includes_original_box" => false
        },
        price_cents: item[:price],
        tier: nil
      )
    end

    def sim_racing
      item = sample(SIM_RACING)
      product(
        title: "#{item[:name]} · volante sim racing",
        description: "Volante #{item[:name]} con force feedback y pedales. Funciona perfectamente, " \
                     "sin holguras. Incluye cables, abrazaderas y software descargable. Ideal para " \
                     "Assetto Corsa, iRacing o Gran Turismo.",
        specs: { "warranty_months" => rng.rand < 0.3 ? 12 : 0, "includes_original_box" => rng.rand < 0.5 },
        price_cents: item[:price],
        tier: nil
      )
    end

    def vr_headset
      item = sample(VR)
      product(
        title: "#{item[:name]} · VR",
        description: "Visor VR #{item[:name]} con lentes sin arañazos. Incluye mandos, correas y " \
                     "cable de carga. Perfecto para jugar y ver contenido inmersivo.",
        specs: { "warranty_months" => rng.rand < 0.25 ? 12 : 0, "includes_original_box" => rng.rand < 0.6 },
        price_cents: item[:price],
        tier: nil
      )
    end

    def other_peripheral
      item = sample(OTHER_PERIPHERALS)
      product(
        title: item[:name],
        description: "#{item[:name]} en perfecto estado. Un accesorio muy útil para completar tu " \
                     "escritorio gaming o de trabajo. Incluye cables y accesorios originales.",
        specs: { "warranty_months" => rng.rand < 0.2 ? 12 : 0, "includes_original_box" => rng.rand < 0.4 },
        price_cents: item[:price],
        tier: nil
      )
    end

    def game
      item = sample(GAMES)
      product(
        title: "#{item[:name]} · #{item[:platform]}",
        description: "Juego #{item[:name]} para #{item[:platform]}. Disco/cartucho en perfecto " \
                     "estado, sin arañazos y probado. Incluye caja y manual cuando corresponde.",
        specs: { "warranty_months" => 0, "includes_original_box" => rng.rand < 0.8 },
        price_cents: item[:price],
        tier: nil
      )
    end

    def software
      item = sample(SOFTWARE)
      product(
        title: item[:name],
        description: "Licencia #{item[:name]} sin usar o con activación restante. Se entrega la " \
                     "clave y la documentación original. Ideal para equipos nuevos o pequeñas " \
                     "empresas.",
        specs: { "warranty_months" => 0, "includes_original_box" => false },
        price_cents: item[:price],
        tier: nil
      )
    end

    def accessory(slug)
      item = sample(ACCESSORIES.fetch(slug, ACCESSORIES["other-accessories"]))
      product(
        title: item[:name],
        description: "#{item[:name]} en buen estado, ideal para regalar o completar tu colección. " \
                     "Se entrega limpio y bien embalado. Consulta disponibilidad para envío o " \
                     "recogida en mano.",
        specs: { "warranty_months" => 0, "includes_original_box" => rng.rand < 0.5 },
        price_cents: item[:price],
        tier: nil
      )
    end

    def product(title:, description:, specs:, price_cents:, tier:)
      Product.new(
        title: title,
        description: description,
        specs: specs,
        base_price_cents: price_cents,
        tier: tier
      )
    end

    def capacity_label(value)
      value.to_s.sub(/(\d+)tb/, '\1 TB').sub(/(\d+)gb/, '\1 GB')
    end

    def tier_for_price(cents, mid_threshold, pro_threshold)
      return "pro-gamer-pcs" if cents >= pro_threshold
      return "mid-range-pcs" if cents >= mid_threshold

      "value-pcs"
    end

    def label_tier(cents, mid_threshold, pro_threshold, kind)
      suffix = kind == "gpus" ? "gpus" : "cpus"
      return "pro-gamer-#{suffix}" if cents >= pro_threshold
      return "mid-range-#{suffix}" if cents >= mid_threshold

      "value-#{suffix}"
    end
  end
end
