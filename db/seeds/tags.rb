# frozen_string_literal: true

# Phase 1c catalogue: product labels and seller tags. Aesthetic loanwords that
# are used as-is in every locale (Anime, Lo-fi, Noctua, RGB, Sakura, Steampunk)
# keep an identical name, while generic words are translated.
product_labels = [
  {
    slug: "value-pcs",
    name: {
      es: "PCs económicos",
      en: "Value PCs",
      fr: "PC au meilleur prix",
      de: "Preiswerte PCs",
      it: "PC convenienti",
      pt: "PCs económicos"
    }
  },
  {
    slug: "mid-range-pcs",
    name: {
      es: "PCs de gama media",
      en: "Mid-range PCs",
      fr: "PC de milieu de gamme",
      de: "Mittelklasse-PCs",
      it: "PC di fascia media",
      pt: "PCs de gama média"
    }
  },
  {
    slug: "pro-gamer-pcs",
    name: {
      es: "PCs para gamers profesionales",
      en: "Pro gamer PCs",
      fr: "PC pour joueurs pro",
      de: "Pro-Gamer-PCs",
      it: "PC per gamer professionisti",
      pt: "PCs para gamers profissionais"
    }
  },
  {
    slug: "value-gpus",
    name: {
      es: "GPUs económicas",
      en: "Value GPUs",
      fr: "Cartes graphiques au meilleur prix",
      de: "Preiswerte GPUs",
      it: "GPU convenienti",
      pt: "GPUs económicas"
    }
  },
  {
    slug: "mid-range-gpus",
    name: {
      es: "GPUs de gama media",
      en: "Mid-range GPUs",
      fr: "Cartes graphiques de milieu de gamme",
      de: "Mittelklasse-GPUs",
      it: "GPU di fascia media",
      pt: "GPUs de gama média"
    }
  },
  {
    slug: "pro-gamer-gpus",
    name: {
      es: "GPUs para gamers profesionales",
      en: "Pro gamer GPUs",
      fr: "Cartes graphiques pour joueurs pro",
      de: "Pro-Gamer-GPUs",
      it: "GPU per gamer professionisti",
      pt: "GPUs para gamers profissionais"
    }
  },
  {
    slug: "value-cpus",
    name: {
      es: "CPUs económicas",
      en: "Value CPUs",
      fr: "Processeurs au meilleur prix",
      de: "Preiswerte CPUs",
      it: "CPU convenienti",
      pt: "CPUs económicas"
    }
  },
  {
    slug: "mid-range-cpus",
    name: {
      es: "CPUs de gama media",
      en: "Mid-range CPUs",
      fr: "Processeurs de milieu de gamme",
      de: "Mittelklasse-CPUs",
      it: "CPU di fascia media",
      pt: "CPUs de gama média"
    }
  },
  {
    slug: "pro-gamer-cpus",
    name: {
      es: "CPUs para gamers profesionales",
      en: "Pro gamer CPUs",
      fr: "Processeurs pour joueurs pro",
      de: "Pro-Gamer-CPUs",
      it: "CPU per gamer professionisti",
      pt: "CPUs para gamers profissionais"
    }
  },
  {
    slug: "featured",
    name: {
      es: "Destacado",
      en: "Featured",
      fr: "En vedette",
      de: "Hervorgehoben",
      it: "In evidenza",
      pt: "Em destaque"
    }
  },
  {
    slug: "rare",
    name: {
      es: "Raro", en: "Rare", fr: "Rare", de: "Selten", it: "Raro", pt: "Raro"
    }
  },
  {
    slug: "free-shipping",
    name: {
      es: "Envío gratis",
      en: "Free shipping",
      fr: "Livraison gratuite",
      de: "Kostenloser Versand",
      it: "Spedizione gratuita",
      pt: "Envio grátis"
    }
  },
  {
    slug: "ready-to-ship",
    name: {
      es: "Listo para enviar",
      en: "Ready to ship",
      fr: "Prêt à expédier",
      de: "Versandbereit",
      it: "Pronto per la spedizione",
      pt: "Pronto a enviar"
    }
  }
]

seller_tags = [
  {
    slug: "anime",
    name: {
      es: "Anime", en: "Anime", fr: "Anime", de: "Anime", it: "Anime", pt: "Anime"
    }
  },
  {
    slug: "basic",
    name: {
      es: "Básico", en: "Basic", fr: "Basique", de: "Schlicht", it: "Base", pt: "Básico"
    }
  },
  {
    slug: "blackout",
    name: {
      es: "Blackout", en: "Blackout", fr: "Blackout", de: "Blackout", it: "Blackout", pt: "Blackout"
    }
  },
  {
    slug: "compact",
    name: {
      es: "Compacto", en: "Compact", fr: "Compact", de: "Kompakt", it: "Compatto", pt: "Compacto"
    }
  },
  {
    slug: "cosy",
    name: {
      es: "Acogedor", en: "Cosy", fr: "Cosy", de: "Gemütlich", it: "Accogliente", pt: "Aconchegante"
    }
  },
  {
    slug: "glass",
    name: {
      es: "Cristal", en: "Glass", fr: "Verre", de: "Glas", it: "Vetro", pt: "Vidro"
    }
  },
  {
    slug: "lo-fi",
    name: {
      es: "Lo-fi", en: "Lo-fi", fr: "Lo-fi", de: "Lo-fi", it: "Lo-fi", pt: "Lo-fi"
    }
  },
  {
    slug: "luxe",
    name: {
      es: "Lujo", en: "Luxe", fr: "Luxe", de: "Luxus", it: "Lusso", pt: "Luxo"
    }
  },
  {
    slug: "maximum-performance",
    name: {
      es: "Máximo rendimiento",
      en: "Maximum performance",
      fr: "Performance maximale",
      de: "Maximale Leistung",
      it: "Massime prestazioni",
      pt: "Máximo desempenho"
    }
  },
  {
    slug: "minimalist",
    name: {
      es: "Minimalista",
      en: "Minimalist",
      fr: "Minimaliste",
      de: "Minimalistisch",
      it: "Minimalista",
      pt: "Minimalista"
    }
  },
  {
    slug: "noctua",
    name: {
      es: "Noctua", en: "Noctua", fr: "Noctua", de: "Noctua", it: "Noctua", pt: "Noctua"
    }
  },
  {
    slug: "rainbow",
    name: {
      es: "Arcoíris",
      en: "Rainbow",
      fr: "Arc-en-ciel",
      de: "Regenbogen",
      it: "Arcobaleno",
      pt: "Arco-íris"
    }
  },
  {
    slug: "retro",
    name: {
      es: "Retro", en: "Retro", fr: "Retro", de: "Retro", it: "Retro", pt: "Retro"
    }
  },
  {
    slug: "rgb",
    name: {
      es: "RGB", en: "RGB", fr: "RGB", de: "RGB", it: "RGB", pt: "RGB"
    }
  },
  {
    slug: "sakura",
    name: {
      es: "Sakura", en: "Sakura", fr: "Sakura", de: "Sakura", it: "Sakura", pt: "Sakura"
    }
  },
  {
    slug: "sci-fi",
    name: {
      es: "Ciencia ficción",
      en: "Sci-fi",
      fr: "Science-fiction",
      de: "Sci-Fi",
      it: "Fantascienza",
      pt: "Ficção científica"
    }
  },
  {
    slug: "space",
    name: {
      es: "Espacio", en: "Space", fr: "Espace", de: "Weltraum", it: "Spazio", pt: "Espaço"
    }
  },
  {
    slug: "steampunk",
    name: {
      es: "Steampunk", en: "Steampunk", fr: "Steampunk", de: "Steampunk", it: "Steampunk", pt: "Steampunk"
    }
  },
  {
    slug: "superhero",
    name: {
      es: "Superhéroes",
      en: "Superhero",
      fr: "Super-héros",
      de: "Superhelden",
      it: "Supereroi",
      pt: "Super-heróis"
    }
  },
  {
    slug: "whiteout",
    name: {
      es: "Todo blanco",
      en: "Whiteout",
      fr: "Tout en blanc",
      de: "Ganz in Weiß",
      it: "Tutto bianco",
      pt: "Tudo branco"
    }
  },
  {
    slug: "wood",
    name: {
      es: "Madera", en: "Wood", fr: "Bois", de: "Holz", it: "Legno", pt: "Madeira"
    }
  }
]

seed_tag = lambda do |kind, position, data|
  tag = Tag.find_or_initialize_by(kind: kind, slug: data[:slug])
  tag.assign_attributes(position: position, active: true)
  data[:name].each { |locale, value| tag.public_send(:"name_#{locale}=", value) }
  tag.save!
end

product_labels.each_with_index { |data, index| seed_tag.call(:product_label, index + 1, data) }
seller_tags.each_with_index { |data, index| seed_tag.call(:seller_tag, index + 1, data) }
