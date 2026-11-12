# frozen_string_literal: true

# Phase 1c catalogue: the category tree. Names are translated with Mobility and
# the English name drives the FriendlyId slug (`name_en.parameterize`).
category_tree = [
  {
    icon: "desktop",
    name: {
      es: "PCs gaming",
      en: "Gaming PCs",
      fr: "PC gaming",
      de: "Gaming-PCs",
      it: "PC da gaming",
      pt: "PCs gaming"
    },
    description: {
      es: "Equipos listos para jugar con componentes equilibrados y margen para futuras mejoras.",
      en: "Ready-to-play machines with balanced components and room for future upgrades.",
      fr: "Des machines prêtes à jouer, avec des composants équilibrés et de la marge pour évoluer.",
      de: "Spielfertige Rechner mit ausgewogenen Komponenten und Spielraum für spätere Upgrades.",
      it: "Macchine pronte all'uso con componenti equilibrati e spazio per futuri aggiornamenti.",
      pt: "Máquinas prontas a jogar, com componentes equilibrados e margem para futuras atualizações."
    }
  },
  {
    icon: "laptop",
    name: {
      es: "Portátiles",
      en: "Laptops",
      fr: "Ordinateurs portables",
      de: "Laptops",
      it: "Portatili",
      pt: "Portáteis"
    },
    description: {
      es: "Ordenadores portátiles para estudiar, trabajar o jugar allá donde vayas.",
      en: "Portable computers for studying, working or gaming wherever you go.",
      fr: "Des ordinateurs portables pour étudier, travailler ou jouer où que vous soyez.",
      de: "Tragbare Rechner zum Lernen, Arbeiten oder Spielen – überall.",
      it: "Computer portatili per studiare, lavorare o giocare ovunque.",
      pt: "Computadores portáteis para estudar, trabalhar ou jogar onde estiver."
    }
  },
  {
    icon: "smartphone",
    name: {
      es: "Teléfonos",
      en: "Phones",
      fr: "Téléphones",
      de: "Smartphones",
      it: "Telefoni",
      pt: "Telemóveis"
    },
    description: {
      es: "Smartphones nuevos y de segunda mano con batería y estado comprobados.",
      en: "New and pre-owned smartphones with checked battery health and condition.",
      fr: "Smartphones neufs et d'occasion, avec batterie et état vérifiés.",
      de: "Neue und gebrauchte Smartphones mit geprüftem Akku und Zustand.",
      it: "Smartphone nuovi e usati con batteria e condizioni verificate.",
      pt: "Smartphones novos e usados com bateria e estado verificados."
    }
  },
  {
    icon: "tablet",
    name: {
      es: "Tabletas",
      en: "Tablets",
      fr: "Tablettes",
      de: "Tablets",
      it: "Tablet",
      pt: "Tablets"
    },
    description: {
      es: "Tabletas para leer, dibujar, ver series o trabajar con lápiz digital.",
      en: "Tablets for reading, drawing, streaming or working with a stylus.",
      fr: "Des tablettes pour lire, dessiner, regarder des séries ou travailler au stylet.",
      de: "Tablets zum Lesen, Zeichnen, Streamen oder Arbeiten mit Stift.",
      it: "Tablet per leggere, disegnare, guardare serie o lavorare con lo stilo.",
      pt: "Tablets para ler, desenhar, ver séries ou trabalhar com caneta."
    }
  },
  {
    icon: "gamepad",
    name: {
      es: "Consolas",
      en: "Consoles",
      fr: "Consoles",
      de: "Konsolen",
      it: "Console",
      pt: "Consolas"
    },
    description: {
      es: "Consolas de sobremesa, portátiles y clásicas, con sus mandos y accesorios.",
      en: "Home, handheld and classic consoles, with their controllers and accessories.",
      fr: "Consoles de salon, portables et rétro, avec leurs manettes et accessoires.",
      de: "Heim-, Handheld- und Retro-Konsolen samt Controllern und Zubehör.",
      it: "Console da tavolo, portatili e retrò, con controller e accessori.",
      pt: "Consolas de sala, portáteis e clássicas, com os respetivos comandos e acessórios."
    },
    children: [
      {
        icon: "tv",
        name: {
          es: "Consolas de sobremesa",
          en: "Home consoles",
          fr: "Consoles de salon",
          de: "Heimkonsolen",
          it: "Console da tavolo",
          pt: "Consolas de sala"
        },
        description: {
          es: "PlayStation, Xbox y Nintendo Switch para jugar en el salón.",
          en: "PlayStation, Xbox and Nintendo Switch for the living room.",
          fr: "PlayStation, Xbox et Nintendo Switch pour jouer au salon.",
          de: "PlayStation, Xbox und Nintendo Switch für das Wohnzimmer.",
          it: "PlayStation, Xbox e Nintendo Switch per il salotto.",
          pt: "PlayStation, Xbox e Nintendo Switch para a sala."
        }
      },
      {
        icon: "handheld",
        name: {
          es: "Consolas portátiles",
          en: "Handheld consoles",
          fr: "Consoles portables",
          de: "Handheld-Konsolen",
          it: "Console portatili",
          pt: "Consolas portáteis"
        },
        description: {
          es: "Consolas híbridas y portátiles para jugar en cualquier parte.",
          en: "Hybrid and handheld consoles for gaming on the move.",
          fr: "Consoles hybrides et portables pour jouer partout.",
          de: "Hybrid- und Handheld-Konsolen für unterwegs.",
          it: "Console ibride e portatili per giocare in movimento.",
          pt: "Consolas híbridas e portáteis para jogar em qualquer lugar."
        }
      },
      {
        icon: "history",
        name: {
          es: "Consolas retro",
          en: "Retro consoles",
          fr: "Consoles rétro",
          de: "Retro-Konsolen",
          it: "Console retro",
          pt: "Consolas retro"
        },
        description: {
          es: "Clásicos de los 80 y 90 restaurados o en perfecto estado de funcionamiento.",
          en: "Eighties and nineties classics, restored or in full working order.",
          fr: "Des classiques des années 80 et 90, restaurés ou en parfait état de marche.",
          de: "Klassiker der 80er und 90er, restauriert oder voll funktionsfähig.",
          it: "Classici degli anni 80 e 90, restaurati o perfettamente funzionanti.",
          pt: "Clássicos dos anos 80 e 90, restaurados ou em pleno funcionamento."
        }
      },
      {
        icon: "retro-handheld",
        name: {
          es: "Portátiles retro",
          en: "Retro handhelds",
          fr: "Portables rétro",
          de: "Retro-Handhelds",
          it: "Portatili retro",
          pt: "Portáteis retro"
        },
        description: {
          es: "Game Boy, Game Gear y otras portátiles míticas para coleccionistas.",
          en: "Game Boy, Game Gear and other iconic portables for collectors.",
          fr: "Game Boy, Game Gear et d'autres portables mythiques pour collectionneurs.",
          de: "Game Boy, Game Gear und andere Kult-Handhelds für Sammler.",
          it: "Game Boy, Game Gear e altre portatili storiche per collezionisti.",
          pt: "Game Boy, Game Gear e outras portáteis icónicas para colecionadores."
        }
      }
    ]
  },
  {
    icon: "workstation",
    name: {
      es: "Estaciones de trabajo",
      en: "Workstations",
      fr: "Stations de travail",
      de: "Workstations",
      it: "Workstation",
      pt: "Workstations"
    },
    description: {
      es: "Equipos de alto rendimiento para creación, emisión y cargas de trabajo exigentes.",
      en: "High-performance machines for creation, streaming and demanding workloads.",
      fr: "Des machines hautes performances pour la création, le streaming et les charges lourdes.",
      de: "Hochleistungsrechner für Kreation, Streaming und anspruchsvolle Aufgaben.",
      it: "Macchine ad alte prestazioni per creazione, streaming e carichi di lavoro intensi.",
      pt: "Máquinas de alto desempenho para criação, streaming e cargas de trabalho exigentes."
    },
    children: [
      {
        icon: "creator",
        name: {
          es: "Equipos para creadores",
          en: "Creator rigs",
          fr: "Configurations créatives",
          de: "Creator-PCs",
          it: "Configurazioni per creator",
          pt: "Configurações para criadores"
        },
        description: {
          es: "Configuraciones para edición de vídeo, diseño 3D y fotografía.",
          en: "Builds for video editing, 3D design and photography.",
          fr: "Des configurations pour le montage vidéo, la 3D et la photo.",
          de: "Konfigurationen für Videoschnitt, 3D-Design und Fotografie.",
          it: "Configurazioni per montaggio video, design 3D e fotografia.",
          pt: "Configurações para edição de vídeo, design 3D e fotografia."
        }
      },
      {
        icon: "stream",
        name: {
          es: "Equipos para streaming",
          en: "Streaming rigs",
          fr: "Configurations streaming",
          de: "Streaming-PCs",
          it: "Configurazioni per streaming",
          pt: "Configurações para streaming"
        },
        description: {
          es: "Equipos pensados para emitir con varias cámaras y capturadoras.",
          en: "Builds designed for broadcasting with multiple cameras and capture cards.",
          fr: "Des configurations conçues pour diffuser avec plusieurs caméras et cartes de capture.",
          de: "Konfigurationen für Übertragungen mit mehreren Kameras und Capture-Karten.",
          it: "Configurazioni pensate per trasmettere con più camere e schede di acquisizione.",
          pt: "Configurações pensadas para transmitir com várias câmaras e placas de captura."
        }
      },
      {
        icon: "ai",
        name: {
          es: "Equipos para IA local",
          en: "Local AI rigs",
          fr: "Configurations IA locale",
          de: "Lokale KI-PCs",
          it: "Configurazioni per IA locale",
          pt: "Configurações para IA local"
        },
        description: {
          es: "Equipos con GPU de gran memoria para ejecutar modelos de IA en local.",
          en: "High-memory GPU builds for running AI models locally.",
          fr: "Des configurations à grande mémoire GPU pour exécuter des modèles d'IA en local.",
          de: "Rechner mit viel GPU-Speicher für lokal ausgeführte KI-Modelle.",
          it: "Configurazioni con GPU ad alta memoria per eseguire modelli di IA in locale.",
          pt: "Configurações com GPU de grande memória para modelos de IA locais."
        }
      }
    ]
  },
  {
    icon: "cpu",
    name: {
      es: "Componentes",
      en: "Components",
      fr: "Composants",
      de: "Komponenten",
      it: "Componenti",
      pt: "Componentes"
    },
    description: {
      es: "Piezas sueltas para montar, ampliar o reparar tu equipo.",
      en: "Individual parts to build, upgrade or repair your machine.",
      fr: "Des pièces détachées pour monter, améliorer ou réparer votre machine.",
      de: "Einzelteile zum Bauen, Aufrüsten oder Reparieren.",
      it: "Componenti sfusi per assemblare, potenziare o riparare il tuo PC.",
      pt: "Peças avulso para montar, melhorar ou reparar o seu equipamento."
    },
    children: [
      {
        icon: "gpu",
        name: {
          es: "Tarjetas gráficas",
          en: "GPUs",
          fr: "Cartes graphiques",
          de: "Grafikkarten",
          it: "Schede video",
          pt: "Placas gráficas"
        },
        description: {
          es: "GPUs para jugar, crear contenido o acelerar cargas de trabajo.",
          en: "Graphics cards for gaming, content creation or accelerating workloads.",
          fr: "Des cartes graphiques pour jouer, créer ou accélérer vos charges de travail.",
          de: "Grafikkarten zum Spielen, für Content-Erstellung oder beschleunigte Workloads.",
          it: "Schede grafiche per giocare, creare contenuti o accelerare i carichi di lavoro.",
          pt: "Placas gráficas para jogar, criar conteúdos ou acelerar cargas de trabalho."
        }
      },
      {
        icon: "processor",
        name: {
          es: "Procesadores",
          en: "CPUs",
          fr: "Processeurs",
          de: "Prozessoren",
          it: "Processori",
          pt: "Processadores"
        },
        description: {
          es: "CPUs de escritorio y portátiles de todas las generaciones recientes.",
          en: "Desktop and laptop processors across recent generations.",
          fr: "Des processeurs de bureau et portables, toutes générations récentes.",
          de: "Desktop- und Laptop-Prozessoren aus den letzten Generationen.",
          it: "Processori desktop e portatili delle generazioni recenti.",
          pt: "Processadores de secretária e portáteis de gerações recentes."
        }
      },
      {
        icon: "cooler",
        name: {
          es: "Refrigeración de CPU",
          en: "CPU coolers",
          fr: "Refroidissement CPU",
          de: "CPU-Kühler",
          it: "Dissipatori CPU",
          pt: "Coolers de CPU"
        },
        description: {
          es: "Disipadores de aire, líquida y bloques para mantener la temperatura a raya.",
          en: "Air coolers, liquid coolers and blocks to keep temperatures in check.",
          fr: "Ventilateurs, watercoolings et blocs pour garder des températures maîtrisées.",
          de: "Luftkühler, Wasserkühlungen und Kühlerblöcke für niedrige Temperaturen.",
          it: "Dissipatori ad aria, a liquido e water block per tenere le temperature sotto controllo.",
          pt: "Dissipadores a ar, líquidos e blocos para controlar as temperaturas."
        }
      },
      {
        icon: "motherboard",
        name: {
          es: "Placas base",
          en: "Motherboards",
          fr: "Cartes mères",
          de: "Mainboards",
          it: "Schede madri",
          pt: "Placas-mãe"
        },
        description: {
          es: "Placas base para Intel y AMD, en todos los formatos habituales.",
          en: "Intel and AMD boards in every common form factor.",
          fr: "Cartes mères Intel et AMD dans tous les formats courants.",
          de: "Mainboards für Intel und AMD in allen gängigen Formaten.",
          it: "Schede madri Intel e AMD in tutti i formati più comuni.",
          pt: "Placas-mãe Intel e AMD em todos os formatos habituais."
        }
      },
      {
        icon: "bundle",
        name: {
          es: "Packs de placa base",
          en: "Motherboard bundles",
          fr: "Packs carte mère",
          de: "Mainboard-Bundles",
          it: "Bundle scheda madre",
          pt: "Kits de placa-mãe"
        },
        description: {
          es: "Placa, CPU y memoria combinados y verificados para montar sin complicaciones.",
          en: "Matched board, CPU and memory kits, checked and ready to install.",
          fr: "Des ensembles carte mère, processeur et mémoire vérifiés, prêts à installer.",
          de: "Abgestimmte Sets aus Mainboard, CPU und Speicher, geprüft und einbaufertig.",
          it: "Kit abbinati di scheda madre, CPU e memoria, verificati e pronti da installare.",
          pt: "Conjuntos combinados de placa-mãe, CPU e memória, verificados e prontos a instalar."
        }
      },
      {
        icon: "memory",
        name: {
          es: "Memoria RAM",
          en: "Memory",
          fr: "Mémoire",
          de: "Arbeitsspeicher",
          it: "Memoria",
          pt: "Memória"
        },
        description: {
          es: "Módulos DDR4 y DDR5 para equipos de escritorio y portátiles.",
          en: "DDR4 and DDR5 modules for desktop and laptop builds.",
          fr: "Des modules DDR4 et DDR5 pour ordinateurs de bureau et portables.",
          de: "DDR4- und DDR5-Module für Desktop und Laptop.",
          it: "Moduli DDR4 e DDR5 per desktop e portatili.",
          pt: "Módulos DDR4 e DDR5 para secretária e portáteis."
        }
      },
      {
        icon: "storage",
        name: {
          es: "Almacenamiento",
          en: "Storage",
          fr: "Stockage",
          de: "Speicher",
          it: "Archiviazione",
          pt: "Armazenamento"
        },
        description: {
          es: "SSD, NVMe y discos duros para ampliar espacio o acelerar el sistema.",
          en: "SSDs, NVMe drives and hard disks to add space or speed up your system.",
          fr: "SSD, NVMe et disques durs pour gagner de l'espace ou accélérer le système.",
          de: "SSDs, NVMe-Laufwerke und Festplatten für mehr Platz oder mehr Tempo.",
          it: "SSD, unità NVMe e dischi rigidi per più spazio o più velocità.",
          pt: "SSDs, unidades NVMe e discos rígidos para mais espaço ou velocidade."
        }
      },
      {
        icon: "case",
        name: {
          es: "Cajas",
          en: "Cases",
          fr: "Boîtiers",
          de: "Gehäuse",
          it: "Case",
          pt: "Caixas"
        },
        description: {
          es: "Torres y chasis para todos los tamaños y estilos de montaje.",
          en: "Towers and chassis for every size and build style.",
          fr: "Des tours et châssis pour toutes les tailles et tous les styles.",
          de: "Tower und Gehäuse für jede Größe und jeden Build-Stil.",
          it: "Case e chassis per ogni dimensione e stile di configurazione.",
          pt: "Caixas e chassis para todos os tamanhos e estilos de montagem."
        }
      },
      {
        icon: "fan",
        name: {
          es: "Ventiladores de caja",
          en: "Case fans",
          fr: "Ventilateurs de boîtier",
          de: "Gehäuselüfter",
          it: "Ventole per case",
          pt: "Ventoinhas de caixa"
        },
        description: {
          es: "Ventiladores con y sin RGB para mejorar el flujo de aire.",
          en: "Fans with and without RGB to improve airflow.",
          fr: "Des ventilateurs avec ou sans RGB pour améliorer le flux d'air.",
          de: "Lüfter mit und ohne RGB für einen besseren Luftstrom.",
          it: "Ventole con e senza RGB per migliorare il flusso d'aria.",
          pt: "Ventoinhas com e sem RGB para melhorar o fluxo de ar."
        }
      },
      {
        icon: "power",
        name: {
          es: "Fuentes de alimentación",
          en: "Power supplies",
          fr: "Alimentations",
          de: "Netzteile",
          it: "Alimentatori",
          pt: "Fontes de alimentação"
        },
        description: {
          es: "Fuentes modulares y eficientes desde 400 W hasta 1600 W.",
          en: "Modular, efficient units from 400 W up to 1600 W.",
          fr: "Des blocs modulaires et efficaces de 400 W à 1600 W.",
          de: "Modulare, effiziente Netzteile von 400 W bis 1600 W.",
          it: "Alimentatori modulari ed efficienti da 400 W a 1600 W.",
          pt: "Fontes modulares e eficientes de 400 W a 1600 W."
        }
      },
      {
        icon: "expansion-card",
        name: {
          es: "Tarjetas de expansión",
          en: "Expansion cards",
          fr: "Cartes d'extension",
          de: "Erweiterungskarten",
          it: "Schede di espansione",
          pt: "Placas de expansão"
        },
        description: {
          es: "Capturadoras, tarjetas de sonido y controladoras para ampliar tu PC.",
          en: "Capture cards, sound cards and controllers to extend your PC.",
          fr: "Cartes de capture, cartes son et contrôleurs pour étendre votre PC.",
          de: "Capture-Karten, Soundkarten und Controller zur PC-Erweiterung.",
          it: "Schede di acquisizione, audio e controller per ampliare il PC.",
          pt: "Placas de captura, som e controladores para expandir o PC."
        }
      },
      {
        icon: "network",
        name: {
          es: "Adaptadores de red",
          en: "Network adapters",
          fr: "Cartes réseau",
          de: "Netzwerkadapter",
          it: "Adattatori di rete",
          pt: "Adaptadores de rede"
        },
        description: {
          es: "Tarjetas Wi-Fi y Ethernet para conexiones más rápidas y estables.",
          en: "Wi-Fi and Ethernet cards for faster, more stable connections.",
          fr: "Cartes Wi-Fi et Ethernet pour des connexions plus rapides et stables.",
          de: "WLAN- und Ethernet-Karten für schnellere, stabilere Verbindungen.",
          it: "Schede Wi-Fi ed Ethernet per connessioni più rapide e stabili.",
          pt: "Placas Wi-Fi e Ethernet para ligações mais rápidas e estáveis."
        }
      },
      {
        icon: "box",
        name: {
          es: "Otros componentes",
          en: "Other components",
          fr: "Autres composants",
          de: "Weitere Komponenten",
          it: "Altri componenti",
          pt: "Outros componentes"
        },
        description: {
          es: "Piezas difíciles de clasificar que completan cualquier montaje.",
          en: "Hard-to-classify parts that finish off any build.",
          fr: "Des pièces inclassables qui complètent n'importe quelle configuration.",
          de: "Schwer einzuordnende Teile, die jeden Build vervollständigen.",
          it: "Componenti difficili da classificare che completano ogni configurazione.",
          pt: "Peças difíceis de classificar que completam qualquer montagem."
        }
      },
      {
        icon: "thermal-paste",
        name: {
          es: "Pasta térmica",
          en: "Thermal paste",
          fr: "Pâte thermique",
          de: "Wärmeleitpaste",
          it: "Pasta termica",
          pt: "Pasta térmica"
        },
        description: {
          es: "Compuestos térmicos para mejorar la transferencia de calor del procesador.",
          en: "Thermal compounds that improve heat transfer from the processor.",
          fr: "Des composés thermiques pour améliorer le transfert de chaleur du processeur.",
          de: "Wärmeleitmittel für einen besseren Wärmeübergang vom Prozessor.",
          it: "Composti termici per migliorare lo scambio di calore dal processore.",
          pt: "Compostos térmicos para melhorar a transferência de calor do processador."
        }
      }
    ]
  },
  {
    icon: "monitor",
    name: {
      es: "Periféricos",
      en: "Peripherals",
      fr: "Périphériques",
      de: "Peripherie",
      it: "Periferiche",
      pt: "Periféricos"
    },
    description: {
      es: "Teclados, ratones, pantallas y todo lo que rodea tu equipo.",
      en: "Keyboards, mice, screens and everything around your machine.",
      fr: "Claviers, souris, écrans et tout ce qui entoure votre machine.",
      de: "Tastaturen, Mäuse, Bildschirme und alles rund um den Rechner.",
      it: "Tastiere, mouse, schermi e tutto ciò che circonda il tuo PC.",
      pt: "Teclados, ratos, ecrãs e tudo o que rodeia o seu equipamento."
    },
    children: [
      {
        icon: "monitor",
        name: {
          es: "Monitores",
          en: "Monitors",
          fr: "Moniteurs",
          de: "Monitore",
          it: "Monitor",
          pt: "Monitores"
        },
        description: {
          es: "Pantallas de 24 a 49 pulgadas para jugar y trabajar.",
          en: "Screens from 24 to 49 inches for gaming and work.",
          fr: "Des écrans de 24 à 49 pouces pour jouer et travailler.",
          de: "Bildschirme von 24 bis 49 Zoll zum Spielen und Arbeiten.",
          it: "Schermi da 24 a 49 pollici per giocare e lavorare.",
          pt: "Ecrãs de 24 a 49 polegadas para jogar e trabalhar."
        }
      },
      {
        icon: "headphones",
        name: {
          es: "Auriculares",
          en: "Headphones",
          fr: "Casques",
          de: "Kopfhörer",
          it: "Cuffie",
          pt: "Auscultadores"
        },
        description: {
          es: "Auriculares con y sin micrófono para jugar, escuchar o emitir.",
          en: "Headsets and headphones for gaming, listening or streaming.",
          fr: "Casques avec ou sans micro pour jouer, écouter ou diffuser.",
          de: "Headsets und Kopfhörer zum Spielen, Hören oder Streamen.",
          it: "Cuffie con e senza microfono per giocare, ascoltare o trasmettere.",
          pt: "Auscultadores com e sem microfone para jogar, ouvir ou transmitir."
        }
      },
      {
        icon: "keyboard",
        name: {
          es: "Teclados",
          en: "Keyboards",
          fr: "Claviers",
          de: "Tastaturen",
          it: "Tastiere",
          pt: "Teclados"
        },
        description: {
          es: "Teclados mecánicos y de membrana en todos los formatos.",
          en: "Mechanical and membrane keyboards in every layout and size.",
          fr: "Des claviers mécaniques et à membrane, tous formats et dispositions.",
          de: "Mechanische und Membran-Tastaturen in allen Layouts und Größen.",
          it: "Tastiere meccaniche e a membrana in ogni formato e layout.",
          pt: "Teclados mecânicos e de membrana em todos os formatos."
        }
      },
      {
        icon: "mouse",
        name: {
          es: "Ratones",
          en: "Mice",
          fr: "Souris",
          de: "Mäuse",
          it: "Mouse",
          pt: "Ratos"
        },
        description: {
          es: "Ratones ligeros, ergonómicos y para juegos competitivos.",
          en: "Lightweight, ergonomic and competitive gaming mice.",
          fr: "Des souris légères, ergonomiques et pensées pour la compétition.",
          de: "Leichte, ergonomische und kompetitive Gaming-Mäuse.",
          it: "Mouse leggeri, ergonomici e per il gaming competitivo.",
          pt: "Ratos leves, ergonómicos e para gaming competitivo."
        }
      },
      {
        icon: "speaker",
        name: {
          es: "Altavoces",
          en: "Speakers",
          fr: "Enceintes",
          de: "Lautsprecher",
          it: "Diffusori",
          pt: "Altifalantes"
        },
        description: {
          es: "Altavoces de escritorio, monitores de estudio y barras de sonido.",
          en: "Desktop speakers, studio monitors and soundbars.",
          fr: "Des enceintes de bureau, moniteurs de studio et barres de son.",
          de: "Desktop-Lautsprecher, Studiomonitore und Soundbars.",
          it: "Diffusori da scrivania, monitor da studio e soundbar.",
          pt: "Altifalantes de secretária, monitores de estúdio e barras de som."
        }
      },
      {
        icon: "controller",
        name: {
          es: "Mandos",
          en: "Controllers",
          fr: "Manettes",
          de: "Controller",
          it: "Controller",
          pt: "Comandos"
        },
        description: {
          es: "Mandos con y sin cable para PC y consola.",
          en: "Wired and wireless controllers for PC and console.",
          fr: "Des manettes filaires et sans fil pour PC et console.",
          de: "Kabelgebundene und kabellose Controller für PC und Konsole.",
          it: "Controller con e senza filo per PC e console.",
          pt: "Comandos com e sem fios para PC e consola."
        }
      },
      {
        icon: "retro-controller",
        name: {
          es: "Mandos retro",
          en: "Retro controllers",
          fr: "Manettes rétro",
          de: "Retro-Controller",
          it: "Controller retro",
          pt: "Comandos retro"
        },
        description: {
          es: "Mandos originales y réplicas para consolas clásicas.",
          en: "Original and replica pads for classic consoles.",
          fr: "Des manettes d'origine et des répliques pour consoles classiques.",
          de: "Originale und Nachbauten für klassische Konsolen.",
          it: "Controller originali e repliche per console classiche.",
          pt: "Comandos originais e réplicas para consolas clássicas."
        }
      },
      {
        icon: "racing",
        name: {
          es: "Sim racing",
          en: "Sim racing",
          fr: "Sim racing",
          de: "Sim-Racing",
          it: "Sim racing",
          pt: "Sim racing"
        },
        description: {
          es: "Volantes, pedales y bases para simulación de conducción.",
          en: "Wheels, pedals and bases for driving simulation.",
          fr: "Des volants, pédaliers et bases pour la simulation automobile.",
          de: "Lenkräder, Pedale und Bases für die Fahrzeugsimulation.",
          it: "Volanti, pedali e basi per la simulazione di guida.",
          pt: "Volantes, pedais e bases para simulação de condução."
        }
      },
      {
        icon: "webcam",
        name: {
          es: "Webcams",
          en: "Webcams",
          fr: "Webcams",
          de: "Webcams",
          it: "Webcam",
          pt: "Webcams"
        },
        description: {
          es: "Cámaras para videollamadas, directos y reuniones.",
          en: "Cameras for video calls, live streams and meetings.",
          fr: "Des caméras pour les appels vidéo, les directs et les réunions.",
          de: "Kameras für Videoanrufe, Livestreams und Meetings.",
          it: "Webcam per videochiamate, dirette e riunioni.",
          pt: "Câmaras para videochamadas, diretos e reuniões."
        }
      },
      {
        icon: "vr",
        name: {
          es: "Realidad virtual",
          en: "VR",
          fr: "Réalité virtuelle",
          de: "VR",
          it: "Realtà virtuale",
          pt: "Realidade virtual"
        },
        description: {
          es: "Cascos y accesorios de realidad virtual para PC y consola.",
          en: "Virtual reality headsets and accessories for PC and console.",
          fr: "Des casques et accessoires de réalité virtuelle pour PC et console.",
          de: "VR-Brillen und Zubehör für PC und Konsole.",
          it: "Visori e accessori di realtà virtuale per PC e console.",
          pt: "Óculos e acessórios de realidade virtual para PC e consola."
        }
      },
      {
        icon: "external-drive",
        name: {
          es: "Almacenamiento externo",
          en: "External storage",
          fr: "Stockage externe",
          de: "Externer Speicher",
          it: "Archiviazione esterna",
          pt: "Armazenamento externo"
        },
        description: {
          es: "Discos y SSD portátiles para copias de seguridad y traslados.",
          en: "Portable drives and SSDs for backups and moving files.",
          fr: "Des disques et SSD portables pour les sauvegardes et les transferts.",
          de: "Tragbare Festplatten und SSDs für Backups und Datentransfer.",
          it: "Dischi e SSD portatili per backup e trasferimenti.",
          pt: "Discos e SSDs portáteis para cópias de segurança e transferências."
        }
      },
      {
        icon: "box",
        name: {
          es: "Otros periféricos",
          en: "Other peripherals",
          fr: "Autres périphériques",
          de: "Weitere Peripherie",
          it: "Altre periferiche",
          pt: "Outros periféricos"
        },
        description: {
          es: "Accesorios de entrada y salida que no encajan en otra categoría.",
          en: "Input and output accessories that do not fit elsewhere.",
          fr: "Des accessoires d'entrée et de sortie qui ne rentrent nulle part ailleurs.",
          de: "Ein- und Ausgabezubehör, das anderswo keinen Platz findet.",
          it: "Accessori di input e output che non rientrano altrove.",
          pt: "Acessórios de entrada e saída que não encaixam noutras categorias."
        }
      },
      {
        icon: "microphone",
        name: {
          es: "Micrófonos",
          en: "Microphones",
          fr: "Microphones",
          de: "Mikrofone",
          it: "Microfoni",
          pt: "Microfones"
        },
        description: {
          es: "Micrófonos USB y XLR para directos, pódcast y grabación.",
          en: "USB and XLR microphones for streaming, podcasts and recording.",
          fr: "Des microphones USB et XLR pour le streaming, les podcasts et l'enregistrement.",
          de: "USB- und XLR-Mikrofone für Streaming, Podcasts und Aufnahmen.",
          it: "Microfoni USB e XLR per dirette, podcast e registrazioni.",
          pt: "Microfones USB e XLR para diretos, podcasts e gravação."
        }
      }
    ]
  },
  {
    icon: "accessory",
    name: {
      es: "Accesorios",
      en: "Accessories",
      fr: "Accessoires",
      de: "Zubehör",
      it: "Accessori",
      pt: "Acessórios"
    },
    description: {
      es: "Detalles que personalizan tu escritorio y tu equipo.",
      en: "Details that personalise your desk and your setup.",
      fr: "Des détails pour personnaliser votre bureau et votre installation.",
      de: "Details, die Schreibtisch und Setup persönlich machen.",
      it: "Dettagli che personalizzano la scrivania e la postazione.",
      pt: "Detalhes que personalizam a sua secretária e o seu espaço."
    },
    children: [
      {
        icon: "art",
        name: {
          es: "Arte y decoración",
          en: "Art & decor",
          fr: "Art et décoration",
          de: "Kunst & Deko",
          it: "Arte e decorazione",
          pt: "Arte e decoração"
        },
        description: {
          es: "Láminas, figuras y objetos para dar carácter a tu rincón.",
          en: "Prints, figures and objects that give your corner some character.",
          fr: "Des affiches, figurines et objets pour donner du caractère à votre coin.",
          de: "Prints, Figuren und Objekte, die deinem Platz Charakter geben.",
          it: "Stampe, figure e oggetti per dare carattere al tuo angolo.",
          pt: "Posters, figuras e objetos que dão carácter ao seu espaço."
        }
      },
      {
        icon: "desk",
        name: {
          es: "Accesorios de escritorio",
          en: "Desk accessories",
          fr: "Accessoires de bureau",
          de: "Schreibtischzubehör",
          it: "Accessori da scrivania",
          pt: "Acessórios de secretária"
        },
        description: {
          es: "Reposamuñecas, organizadores y soportes para trabajar mejor.",
          en: "Wrist rests, organisers and stands for a better workspace.",
          fr: "Des repose-poignets, organisateurs et supports pour mieux travailler.",
          de: "Handballenauflagen, Organizer und Halterungen für besseres Arbeiten.",
          it: "Poggiapolsi, organizer e supporti per lavorare meglio.",
          pt: "Descansos de pulso, organizadores e suportes para trabalhar melhor."
        }
      },
      {
        icon: "collectible",
        name: {
          es: "Coleccionables",
          en: "Collectibles",
          fr: "Objets de collection",
          de: "Sammlerstücke",
          it: "Oggetti da collezione",
          pt: "Colecionáveis"
        },
        description: {
          es: "Figuras, ediciones limitadas y objetos de culto para vitrina.",
          en: "Figures, limited editions and cult objects for the display shelf.",
          fr: "Des figurines, éditions limitées et objets cultes pour la vitrine.",
          de: "Figuren, limitierte Editionen und Kultobjekte für die Vitrine.",
          it: "Action figure, edizioni limitate e oggetti di culto per la vetrina.",
          pt: "Figuras, edições limitadas e objetos de culto para a estante."
        }
      },
      {
        icon: "clothing",
        name: {
          es: "Ropa y equipación",
          en: "Clothing & gear",
          fr: "Vêtements et équipement",
          de: "Kleidung & Ausrüstung",
          it: "Abbigliamento e accessori",
          pt: "Roupa e equipamento"
        },
        description: {
          es: "Camisetas, sudaderas y bolsas para llevar tu afición contigo.",
          en: "T-shirts, hoodies and bags to carry your hobby with you.",
          fr: "Des t-shirts, sweats et sacs pour emporter votre passion partout.",
          de: "T-Shirts, Hoodies und Taschen für unterwegs.",
          it: "T-shirt, felpe e borse per portare la passione con te.",
          pt: "T-shirts, sweats e sacos para levar o seu hobby consigo."
        }
      },
      {
        icon: "box",
        name: {
          es: "Otros accesorios",
          en: "Other accessories",
          fr: "Autres accessoires",
          de: "Weiteres Zubehör",
          it: "Altri accessori",
          pt: "Outros acessórios"
        },
        description: {
          es: "Todo lo que no encaja en el resto de accesorios.",
          en: "Everything that does not fit the other accessory groups.",
          fr: "Tout ce qui ne rentre pas dans les autres groupes d'accessoires.",
          de: "Alles, was in keine andere Zubehörgruppe passt.",
          it: "Tutto ciò che non rientra negli altri gruppi di accessori.",
          pt: "Tudo o que não encaixa nos outros grupos de acessórios."
        }
      }
    ]
  },
  {
    icon: "software",
    name: {
      es: "Juegos y software",
      en: "Games & software",
      fr: "Jeux et logiciels",
      de: "Spiele & Software",
      it: "Giochi e software",
      pt: "Jogos e software"
    },
    description: {
      es: "Juegos físicos y digitales, y licencias de software.",
      en: "Physical and digital games, plus software licences.",
      fr: "Des jeux physiques et numériques, et des licences logicielles.",
      de: "Physische und digitale Spiele sowie Softwarelizenzen.",
      it: "Giochi fisici e digitali, oltre a licenze software.",
      pt: "Jogos físicos e digitais, e licenças de software."
    },
    children: [
      {
        icon: "game",
        name: {
          es: "Juegos",
          en: "Games",
          fr: "Jeux",
          de: "Spiele",
          it: "Giochi",
          pt: "Jogos"
        },
        description: {
          es: "Juegos para PC y consola, nuevos y de segunda mano.",
          en: "PC and console games, new and pre-owned.",
          fr: "Des jeux PC et console, neufs et d'occasion.",
          de: "PC- und Konsolenspiele, neu und gebraucht.",
          it: "Giochi per PC e console, nuovi e usati.",
          pt: "Jogos para PC e consola, novos e usados."
        }
      },
      {
        icon: "software",
        name: {
          es: "Software",
          en: "Software",
          fr: "Logiciels",
          de: "Software",
          it: "Software",
          pt: "Software"
        },
        description: {
          es: "Sistemas operativos, suites de productividad y herramientas de creación.",
          en: "Operating systems, productivity suites and creative tools.",
          fr: "Des systèmes d'exploitation, suites bureautiques et outils créatifs.",
          de: "Betriebssysteme, Produktivitätssuiten und Kreativwerkzeuge.",
          it: "Sistemi operativi, suite di produttività e strumenti creativi.",
          pt: "Sistemas operativos, suites de produtividade e ferramentas criativas."
        }
      }
    ]
  }
]

assign_translations = lambda do |record, field, values|
  values.each { |locale, value| record.public_send(:"#{field}_#{locale}=", value) }
end

seed_category = lambda do |data, parent, position|
  name = data[:name]
  description = data[:description]

  category = Category.find_or_initialize_by(slug: name[:en].parameterize)
  category.assign_attributes(
    parent: parent,
    position: position,
    active: true,
    icon: data[:icon]
  )
  assign_translations.call(category, :name, name)
  assign_translations.call(category, :description, description)
  assign_translations.call(category, :seo_title,
                           name.transform_values { |label| "#{label} | PCMarket" })
  assign_translations.call(category, :seo_description, description)
  category.save!
  category
end

category_tree.each_with_index do |node, index|
  parent = seed_category.call(node, nil, index + 1)

  Array(node[:children]).each_with_index do |child, child_index|
    seed_category.call(child, parent, child_index + 1)
  end
end
