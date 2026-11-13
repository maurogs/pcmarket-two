# frozen_string_literal: true

require "bcrypt"
require "securerandom"
require "open3"
require "fileutils"

module Demo
  # Builds a realistic, self-contained demo marketplace: users, stores, listings,
  # photos, orders, reviews, conversations and rollups. Heavy work uses bulk
  # inserts; denormalised counters are recomputed with aggregate SQL at the end.
  class Seed
    DEFAULT_PASSWORD = "Demo1234!"
    LOCALES = %w[es es es es es es es es en fr de it pt].freeze
    CONDITIONS = {
      used_like_new: 28,
      used_good: 34,
      new_sealed: 12,
      new_open_box: 8,
      used_fair: 13,
      for_parts: 5
    }.freeze
    DEPRECIATION = {
      new_sealed: 1.00,
      new_open_box: 0.88,
      used_like_new: 0.78,
      used_good: 0.65,
      used_fair: 0.50,
      for_parts: 0.30
    }.freeze
    STATUSES = {
      published: 80,
      pending_review: 5,
      rejected: 3,
      sold: 7,
      draft: 2.5,
      archived: 2.5
    }.freeze
    CATEGORY_WEIGHTS = {
      "gpus" => 15,
      "gaming-pcs" => 12,
      "cpus" => 10,
      "laptops" => 8,
      "phones" => 7,
      "home-consoles" => 6,
      "memory" => 5,
      "storage" => 5,
      "motherboards" => 4,
      "cases" => 3,
      "power-supplies" => 3,
      "cpu-coolers" => 3,
      "monitors" => 3,
      "keyboards" => 2.5,
      "mice" => 2,
      "headphones" => 2,
      "tablets" => 2,
      "controllers" => 2,
      "vr" => 1.5,
      "webcams" => 1.5,
      "microphones" => 1.5,
      "sim-racing" => 1,
      "retro-consoles" => 1,
      "retro-handhelds" => 1
    }.freeze

    BUSINESS_NAMES = [
      "Nexus Informática S.L.", "TecnoMadrid S.L.", "PixelShop S.L.U.", "HardwarePro S.L.",
      "GamerZone S.L.", "CompuMundo S.L.", "ElectroPC S.L.", "ByteStore S.L.",
      "Overclock Labs S.L.", "PC Adictos S.L.", "InfoTecno S.L.", "SmartParts S.L.",
      "TecnoVenta S.L.", "DigitalNest S.L.", "ProGaming Store S.L.", "Nordic Hardware S.L."
    ].freeze

    INDIVIDUAL_NAMES = [
      "TecnoLucía", "El Taller de Javi", "GamerNando", "PC Vintage Madrid", "Norte Gamer",
      "Laura Builds", "Carlos Rig", "Andrés Componentes", "Marta Gaming", "Sergio Overclock",
      "Casa del Pixel", "Rincón del Hardware", "David PC Lab", "Elena Tech", "Vintage Consolas",
      "Pablo Simracing", "Nuria Gamer", "El Desván Retro", "Iván Workstation", "Rafa Periféricos",
      "Alba Custom PCs", "Hugo Game Store", "Clara Tech Shop", "Manu Hardware", "Lucas Gaming",
      "Sara Componentes", "Diego Retro", "Mario Builds", "Ana Periféricos", "Jorge PC",
      "Raúl Módulos", "Vega Informática", "Bruno Tech", "Irene Consolas", "Óscar Gaming",
      "Nerea Componentes", "Adrián Rigs", "Silvia Hardware", "Rubén Retro", "Teresa PC",
      "Guille Gamer", "Marina Tech", "Álvaro Sets", "Paula Consolas", "Emilio Overclock"
    ].freeze

    STORE_DESCRIPTIONS = [
      "Vendedor particular de componentes de segunda mano. Todo probado antes de enviar.",
      "Tienda especializada en hardware gaming, periféricos y equipos montados a medida.",
      "Compramos, reacondicionamos y vendemos PC y consolas con garantía.",
      "Apasionado del hardware desde 2005. Envíos rápidos y embalaje cuidado.",
      "Especialistas en componentes de gama alta, workstations y equipos para creadores.",
      "Tienda de barrio con atención personalizada y recogida en mano disponible."
    ].freeze

    RETURN_POLICIES = [
      "Acepto devoluciones durante 14 días si el producto no coincide con la descripción.",
      "Devolución en 14 días con el artículo en el mismo estado. Gastos de envío a cargo del comprador.",
      "Garantía de 12 meses en componentes nuevos; 3 meses en producto reacondicionado."
    ].freeze

    SHIPPING_POLICIES = [
      "Envío en 24/48 h por mensajería con seguimiento. Embalaje reforzado.",
      "Envío por Correos o SEUR según destino. Recogida en mano en Madrid centro.",
      "Envíos de lunes a viernes. Los pedidos se preparan el mismo día si se compran antes de las 14:00."
    ].freeze

    MESSAGE_TEXTS = {
      "es" => [
        "Hola, ¿sigue disponible?",
        "¡Buenas! Sí, todavía lo tengo. ¿Te interesa?",
        "Sí, ¿aceptarías un poco menos?",
        "Puedo ajustar el precio si lo recoges en mano.",
        "¿Tiene algún arañazo o detalle que deba saber?",
        "Está impecable, solo tiene el uso normal. Te puedo enviar más fotos.",
        "¿Cuánto tarda el envío a Barcelona?",
        "Sale mañana por mensajería, en 24/48 h lo tendrías en casa.",
        "Perfecto, muchas gracias. Lo pienso y te digo.",
        "Sin problema, quedo atento. ¡Gracias!",
        "¿Incluye todos los cables originales?",
        "Sí, incluye caja, cables y documentación. Todo completo.",
        "¿Sería posible probarlo antes de comprar?",
        "Claro, sin compromiso. Estoy disponible por las tardes.",
        "Me lo quedo. ¿Me pasas los datos para el pago?",
        "Genial, te preparo el paquete esta tarde."
      ],
      "en" => [
        "Hi, is this still available?",
        "Hello! Yes, it is still available. Are you interested?",
        "Would you take a slightly lower offer?",
        "I can lower the price if you collect it in person.",
        "Does it have any scratches I should know about?",
        "It is in great shape, just normal use. I can send more photos.",
        "How long does shipping to Barcelona take?",
        "It ships tomorrow and should arrive in 24/48 hours.",
        "Thanks, I will think about it and let you know.",
        "No problem, I will be here. Thanks!",
        "Are all the original cables included?",
        "Yes, box, cables and documentation are all included.",
        "Could I test it before buying?",
        "Of course, no obligation. I am available in the evenings.",
        "I will take it. How do I pay?",
        "Great, I will get the parcel ready this afternoon."
      ],
      "fr" => [
        "Bonjour, est-ce toujours disponible ?",
        "Oui, toujours disponible. Cela vous intéresse ?",
        "Accepteriez-vous un prix un peu plus bas ?",
        "Je peux baisser le prix si vous venez le chercher.",
        "Est-ce qu'il y a des rayures ?",
        "Il est en très bon état, je peux envoyer d'autres photos."
      ],
      "de" => [
        "Hallo, ist das noch verfügbar?",
        "Ja, es ist noch da. Interesse?",
        "Würden Sie etwas mit dem Preis runtergehen?",
        "Bei Abholung kann ich den Preis anpassen.",
        "Gibt es Kratzer, die ich wissen sollte?",
        "Er ist in sehr gutem Zustand, ich kann weitere Fotos schicken."
      ],
      "it" => [
        "Ciao, è ancora disponibile?",
        "Sì, è ancora disponibile. Ti interessa?",
        "Accetteresti un prezzo leggermente più basso?",
        "Posso abbassare il prezzo se vieni a ritirarlo.",
        "Ci sono graffi che dovrei sapere?",
        "È in ottime condizioni, posso inviare altre foto."
      ],
      "pt" => [
        "Olá, ainda está disponível?",
        "Sim, ainda está disponível. Tem interesse?",
        "Aceitaria um preço um pouco mais baixo?",
        "Posso baixar o preço se vier buscar.",
        "Tem algum risco que deva saber?",
        "Está em muito bom estado, posso enviar mais fotos."
      ]
    }.freeze

    REVIEW_TEXTS = {
      "es" => [
        "Todo perfecto. El artículo llegó muy bien embalado y tal como se describía.",
        "Vendedor muy atento y rápido. Repetiría sin dudarlo.",
        "El producto funciona de maravilla. Envío en 24 horas.",
        "Buena comunicación y embalaje impecable. Muy recomendable.",
        "Llegó un día más tarde de lo previsto, pero el estado era excelente.",
        "Tal cual las fotos. Se nota que cuida el material.",
        "Precio justo y trato cercano. Gracias por todo.",
        "Muy buena experiencia, el PC llegó montado y funcionando a la primera."
      ],
      "en" => [
        "Everything was perfect. Well packed and exactly as described.",
        "Great seller, fast replies and quick shipping. Would buy again.",
        "Item works flawlessly and arrived in 24 hours.",
        "Good communication and spotless packaging. Highly recommended.",
        "Arrived a day later than expected but in excellent condition.",
        "Exactly like the photos. You can tell they take care of their gear.",
        "Fair price and friendly service. Thanks!",
        "Great experience, the PC arrived assembled and booted first time."
      ],
      "fr" => [
        "Parfait, emballage soigné et conforme à la description.",
        "Vendeur réactif, envoi rapide. Je recommande.",
        "Le produit fonctionne parfaitement, merci !"
      ],
      "de" => [
        "Alles bestens, gut verpackt und wie beschrieben.",
        "Schneller Versand und freundlicher Kontakt. Gerne wieder.",
        "Das Gerät funktioniert einwandfrei, danke!"
      ],
      "it" => [
        "Tutto perfetto, imballaggio curato e come descritto.",
        "Venditore disponibile e spedizione veloce. Consigliato.",
        "Il prodotto funziona benissimo, grazie!"
      ],
      "pt" => [
        "Tudo perfeito, bem embalado e conforme a descrição.",
        "Vendedor atencioso e envio rápido. Recomendo.",
        "O produto funciona muito bem, obrigado!"
      ]
    }.freeze

    SELLER_REPLIES = [
      "¡Gracias por la compra! Un placer tratar contigo.",
      "Muchas gracias por tu valoración. ¡Disfrútalo!",
      "Gracias por confiar. Cualquier duda, aquí estoy.",
      "Thanks for the purchase! Enjoy it.",
      "Merci pour votre achat et pour cette évaluation !"
    ].freeze

    REJECTION_REASONS = [
      "La descripción no incluye información suficiente sobre el estado del producto.",
      "Las fotos no permiten verificar el artículo. Añade imágenes reales y vuelve a enviarlo.",
      "El precio no es coherente con el estado declarado. Revisa la publicación.",
      "La categoría elegida no corresponde al producto publicado."
    ].freeze

    REPORT_DETAILS = [
      "El anuncio parece una estafa: pide pago por transferencia fuera de la plataforma.",
      "Las fotos parecen copiadas de otra web y el precio es sospechosamente bajo.",
      "El vendedor no responde y el anuncio lleva semanas duplicado.",
      "El producto anunciado podría ser falsificado. Adjunto capturas.",
      "El texto incluye datos de contacto para cerrar la venta fuera de PCMarket."
    ].freeze

    def self.scaled(value, scale)
      return 0 if value.zero?

      [ (value * scale).round, 1 ].max
    end

    attr_reader :scale, :counts, :summary

    def initialize(scale: nil, password: nil, logger: Rails.logger, image_library: nil, rng: nil)
      @scale = (scale || ENV["DEMO_SCALE"] || 1.0).to_f
      @scale = 1.0 if @scale <= 0
      @password = password.presence || ENV["DEMO_PASSWORD"].presence || DEFAULT_PASSWORD
      @logger = logger
      @library = image_library || Demo::ImageLibrary.new(logger: logger)
      @rng = rng || Random.new(20261112)
      @catalog = Demo::Catalog.new(rng: @rng)
      @counts = build_counts
      @summary = { counts: {}, timings: {}, images: {} }
    end

    def call
      guard_environment!
      ensure_catalogue!

      if Listing.where(demo: true).exists? || Store.where(demo: true).exists? || User.where(demo: true).exists?
        @logger&.info("[demo:seed] existing demo data found, resetting demo rows first")
        Demo::Reset.new(logger: @logger).call
      end

      started = monotonic
      @users = create_users
      @stores = create_stores
      @listings = create_listings
      attach_store_images
      attach_listing_photos
      create_listing_tags
      create_activity
      create_orders_and_reviews
      create_views_reports_and_notifications
      recompute_counters
      @summary[:timings][:total] = monotonic - started
      @summary[:counts] = database_counts
      @summary[:images] = @library.provider_counts
      Rails.cache.delete(Demo::ImageCredits::CACHE_KEY)
      print_summary
      @summary
    end

    def print_summary
      puts "[demo:seed] Demo data ready in #{format('%.1f', @summary[:timings][:total])}s"
      @summary[:counts].each { |key, value| puts format("[demo:seed]   %-20s %s", key, value) }
      if @summary[:images].any?
        puts "[demo:seed]   #{format('%-20s', 'images')} #{@summary[:images].sort.map { |k, v| "#{k}=#{v}" }.join(', ')}"
      end
      @summary[:timings].each do |key, value|
        next if key == :total

        puts format("[demo:seed]   %-20s %.2fs", key, value)
      end
    end

    private

    attr_reader :rng, :logger, :library, :catalog

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def timed(key)
      started = monotonic
      result = yield
      @summary[:timings][key] = monotonic - started
      result
    end

    def build_counts
      {
        users: self.class.scaled(250, scale),
        stores: self.class.scaled(60, scale),
        businesses: self.class.scaled(15, scale),
        listings: self.class.scaled(1_500, scale),
        favourites: self.class.scaled(4_000, scale),
        follows: self.class.scaled(800, scale),
        saved_searches: self.class.scaled(150, scale),
        conversations: self.class.scaled(300, scale),
        offers: self.class.scaled(100, scale),
        orders: self.class.scaled(400, scale),
        reviews: self.class.scaled(300, scale),
        view_days: 30,
        reports: [ self.class.scaled(8, scale), 1 ].max,
        notifications: self.class.scaled(600, scale)
      }
    end

    def guard_environment!
      return unless Rails.env.production?
      return if ENV["DEMO"] == "1"

      raise "Refusing to seed demo data in production. Set DEMO=1 to override."
    end

    def ensure_catalogue!
      missing = library.categories.reject { |slug| Category.exists?(slug: slug) }
      raise "Demo categories are missing. Run bin/rails db:seed first." if missing.size > 10
      raise "No launched country. Run bin/rails db:seed first." unless Country.launched_codes.include?("ES")
    end

    def es_regions
      @es_regions ||= Region.where(country_code: "ES").order(:position, :id).to_a
    end

    def create_users
      timed(:users) do
        password_digest = BCrypt::Password.create(@password)
        now = Time.current
        previous_locale = Faker::Config.locale
        Faker::Config.locale = :es

        rows = counts[:users].times.map do |index|
          first_name = Faker::Name.first_name
          last_name = Faker::Name.last_name
          username = unique_username(first_name, last_name, index)
          confirmed_at = now - rng.rand(5..400).days
          last_sign_in = now - rng.rand(0..45).days

          {
            email: "demo-#{index + 1}-#{username}@pcmarket.test",
            encrypted_password: password_digest,
            username: username,
            first_name: first_name,
            last_name: last_name,
            phone: "6#{format('%08d', rng.rand(100_000_000))}",
            role: 0,
            locale: LOCALES.sample(random: rng),
            country_code: "ES",
            marketing_opt_in: rng.rand < 0.25,
            terms_accepted_at: confirmed_at,
            confirmed_at: confirmed_at,
            sign_in_count: rng.rand(0..40),
            last_sign_in_at: last_sign_in,
            current_sign_in_at: last_sign_in,
            created_at: confirmed_at,
            updated_at: now,
            demo: true
          }
        end

        result = User.insert_all!(rows, returning: %w[id username locale first_name last_name email])
        result.rows.map do |id, username, locale, first_name, last_name, email|
          { id: id, username: username, locale: locale, first_name: first_name,
            last_name: last_name, email: email }
        end
      ensure
        Faker::Config.locale = previous_locale
      end
    end

    def unique_username(first_name, last_name, index)
      base = I18n.transliterate("#{first_name}#{last_name}".downcase).gsub(/[^a-z0-9]/, "")
      base = "demo" if base.blank?
      "#{base.first(22)}#{index + 1}"[0, 30]
    end

    def create_stores
      timed(:stores) do
        now = Time.current
        rows = counts[:stores].times.map do |index|
          user = @users[index % @users.length]
          business = index < counts[:businesses]
          region = es_regions.sample(random: rng)
          name = store_name(index, business)
          postal = postal_code_for(region)

          {
            user_id: user[:id],
            name: name,
            slug: "#{name.parameterize}-#{index + 1}",
            description: STORE_DESCRIPTIONS.sample(random: rng),
            kind: business ? Store.kinds[:business] : Store.kinds[:individual],
            legal_name: business ? "#{name.sub(/ S\.L\.U?\.?\z/, '')} S.L." : nil,
            tax_id: business ? cif_for(index) : nil,
            address_line: business ? "Calle #{Faker::Address.street_name}, #{rng.rand(1..90)}" : nil,
            city: region.name,
            province: region.name,
            postal_code: postal,
            country_code: "ES",
            phone: "9#{format('%08d', rng.rand(100_000_000))}",
            website: business && rng.rand < 0.6 ? "https://www.#{name.parameterize.first(20)}.example" : nil,
            verified_at: rng.rand < 0.22 ? now - rng.rand(10..300).days : nil,
            vacation_mode: false,
            allow_offers_default: true,
            status: Store.statuses[:active],
            handling_days: rng.rand(1..5),
            region_id: region.id,
            return_policy: RETURN_POLICIES.sample(random: rng),
            shipping_policy: SHIPPING_POLICIES.sample(random: rng),
            payouts_enabled: true,
            charges_enabled: true,
            details_submitted: true,
            requirements: {},
            rating_average: 0,
            ratings_count: 0,
            listings_count: 0,
            followers_count: 0,
            sales_count: 0,
            created_at: now - rng.rand(30..700).days,
            updated_at: now,
            demo: true
          }
        end

        existing_slugs = Store.where(slug: rows.map { |row| row[:slug] }).pluck(:slug)
        rows.each { |row| row[:slug] = "#{row[:slug]}-#{SecureRandom.hex(3)}" if existing_slugs.include?(row[:slug]) }

        result = Store.insert_all!(rows, returning: %w[id user_id slug kind])
        result.rows.each_with_index.map do |(id, user_id, slug, kind), index|
          { id: id, user_id: user_id, slug: slug, kind: kind, row: rows[index] }
        end
      end
    end

    def store_name(index, business)
      list = business ? BUSINESS_NAMES : INDIVIDUAL_NAMES
      name = list[index % list.length]
      return name if index < list.length

      "#{name} #{index / list.length + 1}"
    end

    def cif_for(index)
      letter = %w[A B C D E F G H J N P Q R S U V W][index % 18]
      digits = format("%07d", (1_000_000 + (index * 97_531) % 8_999_999))
      even_sum = digits[1].to_i + digits[3].to_i + digits[5].to_i
      odd_sum = [ digits[0], digits[2], digits[4], digits[6] ].sum do |digit|
        doubled = digit.to_i * 2
        doubled > 9 ? doubled - 9 : doubled
      end
      control_digit = (10 - ((even_sum + odd_sum) % 10)) % 10
      control = %w[A B E H].include?(letter) ? control_digit.to_s : "JABCDEFGHI"[control_digit]
      "#{letter}#{digits}#{control}"
    end

    def postal_code_for(region)
      prefix = Address::PROVINCE_PREFIXES[region.code.to_s.sub("ES-", "")]
      "#{prefix || format('%02d', rng.rand(1..52))}#{format('%03d', rng.rand(0..999))}"
    end

    def create_listings
      timed(:listings) do
        categories = Category.where(slug: library.categories, active: true).order(:position, :id).to_a
        raise "No demo categories available" if categories.empty?

        assignments = category_assignments(categories, counts[:listings])
        rows = []
        metadata = []
        now = Time.current
        @gpu_patterns = GpuTier.active.pluck(:pattern, :tier)
        @cpu_patterns = CpuTier.active.pluck(:pattern, :tier)

        assignments.each do |category|
          store = weighted_store
          user_id = store[:user_id]
          product = catalog.product_for(category)
          specs = normalize_specs(category, product)
          condition = weighted_condition
          price = listing_price(product.base_price_cents, condition)
          status = weighted_status
          timestamps = listing_timestamps(status, now)
          region = es_regions.sample(random: rng)
          quantity = store[:kind] == Store.kinds[:business] && rng.rand < 0.3 ? rng.rand(2..5) : 1
          shipping_mode = weighted_shipping_mode
          free_shipping = shipping_mode != Listing.shipping_modes[:local_pickup] && rng.rand < 0.35
          shipping_price = if shipping_mode == Listing.shipping_modes[:local_pickup] || free_shipping
                             0
          else
                             rng.rand(3..12) * 100 - 1
          end
          compare_at = rng.rand < 0.25 ? (price * (1.15 + rng.rand * 0.2)).round : nil
          compare_at = nil if compare_at && compare_at <= price
          title = product.title.first(140)

          rows << {
            store_id: store[:id],
            user_id: user_id,
            category_id: category.id,
            title: title,
            description: product.description,
            slug: "#{title.parameterize.first(90)}-#{SecureRandom.hex(3)}",
            condition: Listing.conditions[condition],
            price_cents: price,
            compare_at_price_cents: compare_at,
            currency: "EUR",
            quantity: quantity,
            specs: specs,
            status: status,
            rejection_reason: status == "rejected" ? REJECTION_REASONS.sample(random: rng) : nil,
            submitted_at: timestamps[:submitted_at],
            published_at: timestamps[:published_at],
            sold_at: timestamps[:sold_at],
            archived_at: timestamps[:archived_at],
            country_code: "ES",
            region_id: region.id,
            city: region.name,
            postal_code: postal_code_for(region),
            shipping_mode: shipping_mode,
            shipping_price_cents: shipping_price,
            free_shipping: free_shipping,
            handling_days: rng.rand(1..5),
            allow_offers: rng.rand < 0.75,
            featured_until: rng.rand < 0.06 ? now + rng.rand(2..14).days : nil,
            views_count: 0,
            favorites_count: 0,
            gpu_tier: tier_for(@gpu_patterns, specs["gpu_model"]),
            cpu_tier: tier_for(@cpu_patterns, specs["cpu_model"]),
            created_at: timestamps[:created_at],
            updated_at: now,
            demo: true
          }
          metadata << { category: category, product: product, condition: condition }
        end

        rows.each_slice(500).with_index do |slice, batch|
          result = Listing.insert_all!(slice, returning: %w[id slug])
          result.rows.each_with_index do |(id, slug), index|
            meta = metadata[batch * 500 + index]
            meta[:id] = id
            meta[:row] = slice[index]
          end
        end

        metadata
      end
    end

    def category_assignments(categories, total)
      return [] if total.zero?

      assignments = categories.first([ categories.size, total ].min).dup
      weighted = categories.select { |category| CATEGORY_WEIGHTS.key?(category.slug) }
      weighted = categories if weighted.empty?

      (total - assignments.size).times do
        assignments << weighted_category(weighted)
      end
      assignments.shuffle!(random: rng)
      assignments
    end

    def weighted_category(categories)
      total = categories.sum { |category| CATEGORY_WEIGHTS.fetch(category.slug, 1) }
      threshold = rng.rand * total
      cumulative = 0
      categories.each do |category|
        cumulative += CATEGORY_WEIGHTS.fetch(category.slug, 1)
        return category if cumulative >= threshold
      end
      categories.last
    end

    def weighted_store
      @stores.sample(random: rng)
    end

    def weighted_condition
      weighted_pick(CONDITIONS)
    end

    def weighted_status
      weighted_pick(STATUSES).to_s
    end

    def weighted_shipping_mode
      roll = rng.rand
      return "local_pickup" if roll < 0.15
      return "shipping_and_pickup" if roll < 0.5

      "shipping"
    end

    def weighted_pick(weights)
      total = weights.values.sum
      threshold = rng.rand * total
      cumulative = 0
      weights.each do |key, weight|
        cumulative += weight
        return key if cumulative >= threshold
      end
      weights.keys.last
    end

    def listing_price(base_cents, condition)
      price = (base_cents * DEPRECIATION.fetch(condition) * (0.9 + rng.rand * 0.2)).round
      [ [ price, 100 ].max, 5_000_000 ].min
    end

    def listing_timestamps(status, now)
      case status
      when "published"
        published = now - rng.rand(0..90).days - rng.rand(0..23).hours
        { created_at: published - rng.rand(1..48).hours, submitted_at: published - 2.hours,
          published_at: published, sold_at: nil, archived_at: nil }
      when "sold"
        published = now - rng.rand(15..90).days
        { created_at: published - 5.hours, submitted_at: published - 2.hours,
          published_at: published, sold_at: now - rng.rand(1..20).days, archived_at: nil }
      when "pending_review"
        submitted = now - rng.rand(0..8).days
        { created_at: submitted - 2.hours, submitted_at: submitted,
          published_at: nil, sold_at: nil, archived_at: nil }
      when "rejected"
        submitted = now - rng.rand(2..40).days
        { created_at: submitted - 3.hours, submitted_at: submitted,
          published_at: nil, sold_at: nil, archived_at: nil }
      when "archived"
        { created_at: now - rng.rand(20..120).days, submitted_at: nil,
          published_at: nil, sold_at: nil, archived_at: now - rng.rand(1..15).days }
      else
        { created_at: now - rng.rand(0..10).days, submitted_at: nil,
          published_at: nil, sold_at: nil, archived_at: nil }
      end
    end

    def normalize_specs(category, product)
      definitions = category.effective_attribute_definitions.index_by(&:key)
      specs = product.specs.stringify_keys.slice(*definitions.keys)

      definitions.each do |key, definition|
        next unless specs.key?(key)

        specs[key] = coerce_spec(definition, specs[key])
        specs.delete(key) unless valid_spec_value?(definition, specs[key])
      end

      category.effective_category_attributes.each do |category_attribute|
        next unless category_attribute.required?

        definition = category_attribute.attribute_definition
        next if spec_present?(specs[definition.key])

        specs[definition.key] = fallback_spec(definition)
      end

      specs
    end

    def spec_present?(value)
      value.is_a?(Array) ? value.any?(&:present?) : value.present?
    end

    def fallback_spec(definition)
      case definition.input_type
      when "single_select"
        option = definition.attribute_options.active.find_by(value: "other") ||
                 definition.attribute_options.active.first
        option&.value
      when "multi_select"
        option = definition.attribute_options.active.first
        option ? [ option.value ] : []
      when "number"
        definition.key == "battery_health" ? 90 : 12
      when "boolean"
        true
      else
        "Modelo estándar"
      end
    end

    def coerce_spec(definition, value)
      case definition.input_type
      when "number" then value.to_i
      when "boolean" then ActiveModel::Type::Boolean.new.cast(value)
      when "multi_select" then Array(value).map(&:to_s)
      else value.to_s
      end
    end

    def valid_spec_value?(definition, value)
      return true unless definition.select_type?

      allowed = definition.attribute_options.select(&:active?).map(&:value)
      values = Array(value).map(&:to_s)
      values.any? && values.all? { |candidate| allowed.include?(candidate) }
    end

    def tier_for(patterns, text)
      return 0 if text.blank? || patterns.empty?

      normal = text.to_s.downcase.gsub("-", " ")
      matches = patterns.select { |pattern, _tier| normal.include?(pattern.gsub("-", " ")) }
      match = matches.max_by { |pattern, tier| [ pattern.length, -tier ] }
      match ? match.last : 0
    end

    def attach_store_images
      timed(:store_images) do
        return if @stores.empty?

        banner_entries = library.entries_for("gaming-pcs")
        banner_entries = library.ensure_placeholders("gaming-pcs", count: 4) if banner_entries.empty?
        banner_blobs = banner_entries.map { |entry| blob_for("gaming-pcs", entry) }.compact

        @stores.each_with_index do |store, index|
          logo_blob = monogram_blob(store[:row][:name], index)
          attach_blob(logo_blob, "Store", store[:id], "logo") if logo_blob

          banner = banner_blobs[index % banner_blobs.length] if banner_blobs.any?
          attach_blob(banner, "Store", store[:id], "banner") if banner
        end
      end
    end

    def attach_listing_photos
      timed(:photos) do
        photo_rows = []
        blob_ids = []
        @listings.each do |listing|
          entries = library.entries_for(listing[:category].slug)
          entries = library.ensure_placeholders(listing[:category].slug, count: 4) if entries.empty?
          next if entries.empty?

          blobs = entries.map { |entry| blob_for(listing[:category].slug, entry) }.compact
          next if blobs.empty?

          rng.rand(2..6).times do |position|
            photo_rows << {
              listing_id: listing[:id],
              position: position,
              created_at: Time.current,
              updated_at: Time.current
            }
            blob_ids << blobs[(position + rng.rand(blobs.length)) % blobs.length].id
          end
        end

        result_rows = []
        photo_rows.each_slice(500) do |slice|
          result = ListingPhoto.insert_all!(slice, returning: %w[id])
          result_rows.concat(result.rows.map(&:first))
        end

        attach_rows = result_rows.each_with_index.map do |photo_id, index|
          {
            name: "image",
            record_type: "ListingPhoto",
            record_id: photo_id,
            blob_id: blob_ids[index],
            created_at: Time.current
          }
        end

        ActiveStorage::Attachment.insert_all!(attach_rows) if attach_rows.any?
        preprocess_pending_variants
      end
    end

    # Variants are generated once per blob (never per listing photo). ImageMagick
    # releases the GVL, so a few worker threads cut the wall-clock time roughly
    # linearly in development. Tests stay single-threaded inside the fixture
    # transaction.
    def preprocess_pending_variants
      blobs = Array(@pending_variants).uniq(&:id)
      @pending_variants = []
      return if blobs.empty?

      if Rails.env.test? || blobs.size < 4
        blobs.each { |blob| pregenerate_variants(blob) }
        return
      end

      queue = Queue.new
      blobs.each { |blob| queue << blob }
      workers = [ 4, blobs.size ].min
      threads = workers.times.map do
        Thread.new do
          loop do
            blob = begin
              queue.pop(true)
            rescue ThreadError
              break
            end
            pregenerate_variants(blob)
          end
        ensure
          ActiveRecord::Base.connection_handler.clear_active_connections!
        end
      end
      threads.each(&:join)
    end

    def blob_for(category_slug, entry)
      @blob_cache ||= {}
      path = File.join(library.category_dir(category_slug), entry["file"].to_s)
      return @blob_cache[path] if @blob_cache.key?(path)
      return @blob_cache[path] = nil unless File.file?(path)

      metadata = {
        demo_provider: entry["provider"],
        demo_source_url: entry["source_url"],
        demo_author: entry["author"],
        demo_author_url: entry["author_url"],
        demo_license: entry["license"],
        demo_license_url: entry["license_url"],
        demo_title: entry["title"]
      }.compact

      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(path, "rb"),
        filename: "demo-#{category_slug}-#{entry['provider']}-#{entry['external_id']}.jpg".gsub(/[^\w.-]/, "-"),
        content_type: "image/jpeg",
        metadata: metadata
      )
      @pending_variants ||= []
      @pending_variants << blob
      @blob_cache[path] = blob
    rescue StandardError => e
      logger&.warn("[demo:seed] could not attach #{path}: #{e.message}")
      @blob_cache[path] = nil
    end

    def pregenerate_variants(blob)
      # The named variants are declared on ListingPhoto (`thumb` 320 and `card`
      # 640). Blobs do not know about named variants, so we process the exact
      # same transformations here; the resulting variation digest is shared with
      # the attachment's named variant and the view reuses the cached file.
      {
        thumb: [ 320, 320 ],
        card: [ 640, 640 ]
      }.each do |_name, size|
        blob.variant(resize_to_limit: size, format: :webp).processed
      rescue StandardError => e
        logger&.warn("[demo:seed] variant #{size.inspect} failed for blob #{blob.id}: #{e.message}")
      end
    end

    def monogram_blob(name, index)
      initials = name.to_s.split.map { |word| word[0] }.join.first(2).upcase
      initials = "PC" if initials.blank?
      colour = %w[#4338ca #0e7490 #be123c #047857 #7e22ce #c2410c][index % 6]
      path = Rails.root.join("tmp/demo_logos", "logo-#{index + 1}.png").to_s
      return @logo_cache[path] if @logo_cache&.key?(path)

      @logo_cache ||= {}
      FileUtils.mkdir_p(File.dirname(path))
      font = Demo::Fonts.path
      command = [ "magick", "-size", "512x512", "xc:#{colour}", "-gravity", "center" ]
      command.concat([ "-font", font, "-fill", "white", "-pointsize", "230", "-annotate", "0", initials ]) if font
      command << path

      _out, _err, status = Open3.capture3(*command)
      return @logo_cache[path] = nil unless status.success? && File.file?(path)

      blob = ActiveStorage::Blob.create_and_upload!(
        io: File.open(path, "rb"),
        filename: "demo-store-logo-#{index + 1}.png",
        content_type: "image/png"
      )
      @logo_cache[path] = blob
    rescue StandardError => e
      logger&.warn("[demo:seed] logo generation failed: #{e.message}")
      @logo_cache[path] = nil
    end

    def attach_blob(blob, record_type, record_id, name)
      return unless blob

      ActiveStorage::Attachment.insert_all!([ {
        name: name,
        record_type: record_type,
        record_id: record_id,
        blob_id: blob.id,
        created_at: Time.current
      } ])
    end

    def create_listing_tags
      timed(:tags) do
        seller_tags = Tag.seller_tags.active.to_a
        seller_by_slug = seller_tags.index_by(&:slug)
        labels = Tag.product_labels.active.index_by(&:slug)
        return if seller_tags.empty?

        rows = []
        @listings.each do |listing|
          tag_ids = []
          if listing[:row][:status] == "published" || listing[:row][:status] == "sold"
            tag_ids.concat(seller_tags.sample(rng.rand(1..2), random: rng).map(&:id))

            specs = listing[:row][:specs] || {}
            category = listing[:category].slug
            tag_ids << seller_by_slug["retro"]&.id if category.start_with?("retro")
            tag_ids << seller_by_slug["rgb"]&.id if specs["rgb_lighting"].present? && specs["rgb_lighting"] != "none"
            tag_ids << seller_by_slug["whiteout"]&.id if specs["case_colour"] == "white"

            tier_slug = listing[:product].tier
            tag_ids << labels[tier_slug]&.id if tier_slug && labels[tier_slug]

            if rng.rand < 0.15
              extra = %w[featured free-shipping ready-to-ship rare].sample(random: rng)
              tag_ids << labels[extra]&.id
            end
          end

          tag_ids.compact.uniq.first(5).each do |tag_id|
            rows << { listing_id: listing[:id], tag_id: tag_id,
                      created_at: Time.current, updated_at: Time.current }
          end
        end

        rows.each_slice(1_000) { |slice| ListingTag.insert_all!(slice) } if rows.any?
      end
    end

    def create_activity
      create_favourites
      create_follows
      create_saved_searches
      create_conversations
      create_offers
    end

    def published_listings
      @published_listings ||= @listings.select do |listing|
        %w[published sold].include?(listing[:row][:status])
      end
    end

    def create_favourites
      timed(:favourites) do
        pairs = Set.new
        attempts = 0
        while pairs.size < counts[:favourites] && attempts < counts[:favourites] * 40
          attempts += 1
          user = @users.sample(random: rng)
          listing = published_listings.sample(random: rng)
          next if listing.blank? || listing[:row][:user_id] == user[:id]

          pairs << [ user[:id], listing[:id] ]
        end

        rows = pairs.map do |user_id, listing_id|
          timestamp = Time.current - rng.rand(0..60).days
          { user_id: user_id, listing_id: listing_id, created_at: timestamp, updated_at: timestamp }
        end
        rows.each_slice(1_000) { |slice| Favourite.insert_all!(slice) } if rows.any?
      end
    end

    def create_follows
      timed(:follows) do
        pairs = Set.new
        attempts = 0
        while pairs.size < counts[:follows] && attempts < counts[:follows] * 40
          attempts += 1
          user = @users.sample(random: rng)
          store = @stores.sample(random: rng)
          next if store[:user_id] == user[:id]

          pairs << [ user[:id], store[:id] ]
        end

        rows = pairs.map do |follower_id, store_id|
          timestamp = Time.current - rng.rand(0..90).days
          { follower_id: follower_id, store_id: store_id, created_at: timestamp, updated_at: timestamp }
        end
        rows.each_slice(1_000) { |slice| Follow.insert_all!(slice) } if rows.any?
      end
    end

    def create_saved_searches
      timed(:saved_searches) do
        rows = counts[:saved_searches].times.map do
          user = @users.sample(random: rng)
          category = Category.where(slug: CATEGORY_WEIGHTS.keys).sample(random: rng) ||
                     Category.where(slug: library.categories).sample(random: rng)
          min_price = rng.rand(1..10) * 50
          query_params = ListingSearch.normalize_params(
            {
              "condition" => [ Listing.conditions.keys.sample(random: rng) ],
              "min_price" => min_price,
              "max_price" => min_price + rng.rand(3..30) * 50,
              "free_shipping" => rng.rand < 0.3
            },
            category: category
          )
          name = saved_search_name(category)
          timestamp = Time.current - rng.rand(1..60).days

          {
            user_id: user[:id],
            name: name,
            query_params: query_params,
            category_id: category&.id,
            email_alerts: rng.rand < 0.7,
            frequency: %w[instant daily weekly].sample(random: rng),
            created_at: timestamp,
            updated_at: timestamp
          }
        end

        SavedSearch.insert_all!(rows) if rows.any?
      end
    end

    def saved_search_name(category)
      [
        "#{category&.name_en || 'Hardware'} hasta #{rng.rand(5..40) * 50} €",
        "Ofertas en #{category&.name_en || 'componentes'}",
        "#{category&.name_en || 'Equipo'} en buen estado"
      ].sample(random: rng).first(80)
    end

    def create_conversations
      timed(:conversations) do
        rows = []
        pairs = Set.new
        attempts = 0
        while rows.size < counts[:conversations] && attempts < counts[:conversations] * 30
          attempts += 1
          listing = published_listings.sample(random: rng)
          next if listing.blank?

          buyer = @users.sample(random: rng)
          next if buyer[:id] == listing[:row][:user_id]

          pair = [ listing[:id], buyer[:id] ]
          next if pairs.include?(pair)

          pairs << pair
          started = Time.current - rng.rand(5..70).days
          rows << {
            listing_id: listing[:id],
            buyer_id: buyer[:id],
            seller_id: listing[:row][:user_id],
            store_id: listing[:row][:store_id],
            last_message_at: started,
            buyer_unread_count: 0,
            seller_unread_count: rng.rand < 0.3 ? 1 : 0,
            buyer_archived: rng.rand < 0.05,
            seller_archived: rng.rand < 0.05,
            created_at: started,
            updated_at: started
          }
        end

        result = Conversation.insert_all!(rows, returning: %w[id listing_id buyer_id seller_id])
        @conversations = result.rows.each_with_index.map do |(id, listing_id, buyer_id, seller_id), index|
          { id: id, listing_id: listing_id, buyer_id: buyer_id, seller_id: seller_id,
            row: rows[index] }
        end

        message_rows = []
        @conversations.each do |conversation|
          listing = @listings.find { |candidate| candidate[:id] == conversation[:listing_id] }
          next if listing.blank?

          buyer = @users.find { |candidate| candidate[:id] == conversation[:buyer_id] }
          seller = @users.find { |candidate| candidate[:id] == conversation[:seller_id] }
          next if buyer.blank? || seller.blank?

          count = rng.rand(2..10)
          timestamp = conversation[:row][:created_at]
          count.times do |index|
            sender = index.even? ? buyer : seller
            text = message_text(sender[:locale])
            timestamp += rng.rand(5..180).minutes
            message_rows << {
              conversation_id: conversation[:id],
              sender_id: sender[:id],
              body: text,
              kind: Message.kinds[:text],
              read_at: index == count - 1 && sender[:id] == seller[:id] && conversation[:row][:buyer_unread_count].to_i.positive? ? nil : timestamp + 10.minutes,
              safety_flagged: false,
              safety_reasons: [],
              metadata: {},
              created_at: timestamp,
              updated_at: timestamp
            }
          end
          @conversation_updates ||= []
          @conversation_updates << [ conversation[:id], timestamp ]
        end

        message_rows.each_slice(1_000) { |slice| Message.insert_all!(slice) } if message_rows.any?

        @conversation_updates&.each do |conversation_id, last_message_at|
          Conversation.where(id: conversation_id).update_all(last_message_at: last_message_at, updated_at: last_message_at)
        end
      end
    end

    def message_text(locale)
      texts = MESSAGE_TEXTS[locale.to_s] || MESSAGE_TEXTS["es"]
      texts.sample(random: rng)
    end

    def create_offers
      timed(:offers) do
        return if counts[:offers].zero?

        rows = []
        pairs = Set.new
        attempts = 0

        while rows.size < counts[:offers] && attempts < counts[:offers] * 60
          attempts += 1
          listing = published_listings.sample(random: rng)
          next if listing.blank? || listing[:row][:status] != "published"
          next unless listing[:row][:allow_offers]

          buyer = @users.sample(random: rng)
          next if buyer[:id] == listing[:row][:user_id]

          pair = [ listing[:id], buyer[:id] ]
          next if pairs.include?(pair)

          conversation = @conversations.find do |candidate|
            candidate[:listing_id] == listing[:id] && candidate[:buyer_id] == buyer[:id]
          end
          if conversation.blank?
            created = Time.current - rng.rand(1..20).days
            result = Conversation.insert_all!([ {
              listing_id: listing[:id],
              buyer_id: buyer[:id],
              seller_id: listing[:row][:user_id],
              store_id: listing[:row][:store_id],
              last_message_at: created,
              buyer_unread_count: 0,
              seller_unread_count: 0,
              buyer_archived: false,
              seller_archived: false,
              created_at: created,
              updated_at: created
            } ], returning: %w[id])
            conversation = { id: result.rows.first.first, listing_id: listing[:id], buyer_id: buyer[:id] }
            @conversations << conversation
          end

          price = listing[:row][:price_cents]
          amount = (price * (0.55 + rng.rand * 0.35)).round
          next if amount >= price

          pairs << pair
          status = weighted_pick("pending" => 45, "accepted" => 20, "declined" => 15,
                                 "expired" => 12, "countered" => 8).to_s
          created = Time.current - rng.rand(1..45).days
          expires_at =
            if %w[pending countered].include?(status)
              Time.current + rng.rand(1..5).days
            else
              created + 2.days
            end
          rows << {
            listing_id: listing[:id],
            buyer_id: buyer[:id],
            conversation_id: conversation[:id],
            offerer_id: buyer[:id],
            amount_cents: amount,
            status: status,
            expires_at: expires_at,
            message: rng.rand < 0.6 ? "¿Aceptarías #{amount / 100} €? Puedo cerrar hoy." : nil,
            created_at: created,
            updated_at: created
          }
        end

        Offer.insert_all!(rows) if rows.any?
        unless Flipper.enabled?(:offers)
          logger&.info("[demo:seed] offers were seeded but the :offers flag is off; enable it to browse them")
        end
      end
    end

    def create_orders_and_reviews
      timed(:orders) do
        rows = counts[:orders].times.map do |index|
          listing = published_listings.sample(random: rng)
          next if listing.blank?

          buyer = @users.reject { |candidate| candidate[:id] == listing[:row][:user_id] }.sample(random: rng)
          next if buyer.blank?

          created = Time.current - rng.rand(1..55).days
          delivered = created + rng.rand(2..7).days
          price = listing[:row][:price_cents]
          shipping = listing[:row][:shipping_price_cents].to_i

          { index: index, listing: listing, buyer: buyer, created_at: created,
            delivered_at: delivered, price: price, shipping: shipping }
        end.compact

        checkouts = rows.map do |order|
          {
            buyer_id: order[:buyer][:id],
            status: "paid",
            subtotal_cents: order[:price],
            shipping_cents: order[:shipping],
            total_cents: order[:price] + order[:shipping],
            payment_intent_id: "demo_pi_#{SecureRandom.hex(6)}",
            expires_at: order[:created_at] + 15.minutes,
            shipping_address: shipping_address(order[:buyer]),
            email: order[:buyer].fetch(:email, "demo-#{order[:buyer][:id]}@pcmarket.test"),
            created_at: order[:created_at],
            updated_at: order[:created_at]
          }
        end

        result = Checkout.insert_all!(checkouts, returning: %w[id payment_intent_id])
        checkout_ids = result.rows.to_h { |id, intent| [ intent, id ] }
        rows.each_with_index { |order, index| order[:checkout_id] = checkout_ids[checkouts[index][:payment_intent_id]] }

        order_rows = rows.each_with_index.map do |order, index|
          {
            checkout_id: order[:checkout_id],
            buyer_id: order[:buyer][:id],
            store_id: order[:listing][:row][:store_id],
            number: "PCM-#{order[:created_at].year}-D#{format('%06d', index + 1)}",
            status: "completed",
            fulfilment: order[:shipping].positive? ? Order.fulfilments[:shipping] : Order.fulfilments[:local_pickup],
            subtotal_cents: order[:price],
            shipping_cents: order[:shipping],
            commission_cents: 0,
            total_cents: order[:price] + order[:shipping],
            currency: "EUR",
            paid_at: order[:created_at] + 5.minutes,
            shipped_at: order[:created_at] + 1.day,
            delivered_at: order[:delivered_at],
            completed_at: order[:delivered_at] + 2.days,
            buyer_protection_ends_at: order[:delivered_at] + 2.days,
            created_at: order[:created_at],
            updated_at: order[:delivered_at] + 2.days
          }
        end

        order_result = Order.insert_all!(order_rows, returning: %w[id number])
        generated_numbers = order_rows.map { |row| row[:number] }
        order_ids = order_result.rows.to_h { |id, number| [ number, id ] }
        rows.each_with_index { |order, index| order[:order_id] = order_ids[generated_numbers[index]] }

        item_rows = rows.map do |order|
          {
            order_id: order[:order_id],
            listing_id: order[:listing][:id],
            quantity: 1,
            unit_price_cents: order[:price],
            shipping_cents: order[:shipping],
            title: order[:listing][:row][:title],
            seller_name: store_name_for(order[:listing][:row][:store_id]),
            photo_url: nil,
            specs: order[:listing][:row][:specs],
            created_at: order[:created_at],
            updated_at: order[:created_at]
          }
        end
        OrderItem.insert_all!(item_rows) if item_rows.any?

        create_reviews(rows)
      end
    end

    def create_views_reports_and_notifications
      create_listing_views
      create_reports
      create_notifications
    end

    def create_reviews(orders)
      reviewable = orders.sample([ [ counts[:reviews], orders.size ].min, orders.size ].min, random: rng)
      rows = reviewable.filter_map do |order|
        next unless order[:buyer][:id]

        rating = weighted_pick("5" => 70, "4" => 15, "3" => 8, "2" => 4, "1" => 3).to_i
        locale = order[:buyer][:locale].to_s
        body = REVIEW_TEXTS.fetch(locale, REVIEW_TEXTS["es"]).sample(random: rng)
        created = order[:delivered_at] + rng.rand(0..3).days
        reply = rng.rand < 0.35 ? SELLER_REPLIES.sample(random: rng) : nil

        {
          order_id: order[:order_id],
          reviewer_id: order[:buyer][:id],
          store_id: order[:listing][:row][:store_id],
          rating: rating,
          body: body,
          seller_reply: reply,
          seller_replied_at: reply ? created + rng.rand(1..3).days : nil,
          status: Review.statuses[:visible],
          created_at: created,
          updated_at: created
        }
      end

      Review.insert_all!(rows) if rows.any?
    end

    def shipping_address(user)
      region = es_regions.sample(random: rng)
      {
        "full_name" => "#{user[:first_name]} #{user[:last_name]}",
        "line1" => "Calle #{Faker::Address.street_name}, #{rng.rand(1..90)}",
        "city" => region.name,
        "province" => region.name,
        "region_code" => region.code,
        "postal_code" => postal_code_for(region),
        "country_code" => "ES",
        "phone" => "6#{format('%08d', rng.rand(100_000_000))}"
      }
    end

    def store_name_for(store_id)
      store = @stores.find { |candidate| candidate[:id] == store_id }
      store ? store[:row][:name] : "PCMarket seller"
    end

    def create_listing_views
      timed(:listing_views) do
        return if published_listings.empty?

        rows = []
        published_listings.each do |listing|
          counts[:view_days].times do |offset|
            date = Date.current - offset
            views = rng.rand(0..35)
            next if views.zero?

            rows << { listing_id: listing[:id], date: date, views: views,
                      created_at: Time.current, updated_at: Time.current }
          end
        end

        rows.each_slice(2_000) { |slice| ListingView.insert_all!(slice) } if rows.any?
      end
    end

    def create_reports
      timed(:reports) do
        rows = counts[:reports].times.filter_map do
          listing = @listings.sample(random: rng)
          next if listing.blank?

          reporter = @users.sample(random: rng)
          created = Time.current - rng.rand(0..20).days
          {
            reporter_id: reporter[:id],
            reportable_type: "Listing",
            reportable_id: listing[:id],
            reason: Report.reasons[%w[scam_fraud misleading counterfeit spam other].sample(random: rng)],
            details: REPORT_DETAILS.sample(random: rng),
            status: Report.statuses["open"],
            created_at: created,
            updated_at: created
          }
        end

        Report.insert_all!(rows) if rows.any?
      end
    end

    def create_notifications
      timed(:notifications) do
        kinds = Notification::KINDS
        rows = counts[:notifications].times.map do
          recipient = @users.sample(random: rng)
          listing = published_listings.sample(random: rng)
          created = Time.current - rng.rand(0..45).days
          {
            recipient_id: recipient[:id],
            kind: kinds.sample(random: rng),
            notifiable_type: listing ? "Listing" : nil,
            notifiable_id: listing ? listing[:id] : nil,
            params: { "title" => listing ? listing[:row][:title] : "PCMarket" },
            read_at: rng.rand < 0.65 ? created + 1.hour : nil,
            created_at: created,
            updated_at: created
          }
        end

        Notification.insert_all!(rows) if rows.any?
      end
    end

    def recompute_counters
      timed(:counters) do
        connection = ActiveRecord::Base.connection

        connection.execute(<<~SQL)
          UPDATE stores
          SET listings_count = COALESCE(counts.total, 0)
          FROM (
            SELECT stores.id, COUNT(listings.id) AS total
            FROM stores
            LEFT JOIN listings ON listings.store_id = stores.id AND listings.status = 'published'
            GROUP BY stores.id
          ) AS counts
          WHERE stores.id = counts.id AND stores.demo = TRUE
        SQL

        connection.execute(<<~SQL)
          UPDATE stores
          SET rating_average = COALESCE(reviews.average, 0),
              ratings_count = COALESCE(reviews.total, 0)
          FROM (
            SELECT stores.id,
                   ROUND(AVG(reviews.rating), 2) AS average,
                   COUNT(reviews.id) AS total
            FROM stores
            LEFT JOIN reviews ON reviews.store_id = stores.id AND reviews.status = 0
            GROUP BY stores.id
          ) AS reviews
          WHERE stores.id = reviews.id AND stores.demo = TRUE
        SQL

        connection.execute(<<~SQL)
          UPDATE stores
          SET followers_count = COALESCE(follows.total, 0)
          FROM (
            SELECT stores.id, COUNT(follows.id) AS total
            FROM stores
            LEFT JOIN follows ON follows.store_id = stores.id
            GROUP BY stores.id
          ) AS follows
          WHERE stores.id = follows.id AND stores.demo = TRUE
        SQL

        connection.execute(<<~SQL)
          UPDATE stores
          SET sales_count = COALESCE(orders.total, 0)
          FROM (
            SELECT stores.id, COUNT(orders.id) AS total
            FROM stores
            LEFT JOIN orders ON orders.store_id = stores.id AND orders.status = 'completed'
            GROUP BY stores.id
          ) AS orders
          WHERE stores.id = orders.id AND stores.demo = TRUE
        SQL

        connection.execute(<<~SQL)
          UPDATE categories
          SET listings_count = COALESCE(counts.total, 0)
          FROM (
            SELECT categories.id, COUNT(listings.id) AS total
            FROM categories
            LEFT JOIN listings ON listings.category_id = categories.id AND listings.status = 'published'
            GROUP BY categories.id
          ) AS counts
          WHERE categories.id = counts.id
        SQL

        connection.execute(<<~SQL)
          UPDATE listings
          SET favorites_count = COALESCE(favourites.total, 0)
          FROM (
            SELECT listings.id, COUNT(favourites.id) AS total
            FROM listings
            LEFT JOIN favourites ON favourites.listing_id = listings.id
            WHERE listings.demo = TRUE
            GROUP BY listings.id
          ) AS favourites
          WHERE listings.id = favourites.id
        SQL

        connection.execute(<<~SQL)
          UPDATE listings
          SET views_count = COALESCE(views.total, 0)
          FROM (
            SELECT listings.id, SUM(listing_views.views) AS total
            FROM listings
            LEFT JOIN listing_views ON listing_views.listing_id = listings.id
            WHERE listings.demo = TRUE
            GROUP BY listings.id
          ) AS views
          WHERE listings.id = views.id
        SQL
      end
    end

    def database_counts
      {
        users: User.where(demo: true).count,
        stores: Store.where(demo: true).count,
        listings: Listing.where(demo: true).count,
        published_listings: Listing.where(demo: true, status: "published").count,
        photos: ListingPhoto.joins(:listing).where(listings: { demo: true }).count,
        favourites: Favourite.joins(:listing).where(listings: { demo: true }).count,
        follows: Follow.joins(:store).where(stores: { demo: true }).count,
        saved_searches: SavedSearch.joins(:user).where(users: { demo: true }).count,
        conversations: Conversation.where(buyer_id: User.where(demo: true).select(:id)).count,
        messages: Message.where(conversation_id: Conversation.where(buyer_id: User.where(demo: true).select(:id)).select(:id)).count,
        offers: Offer.joins(:buyer).where(users: { demo: true }).count,
        orders: Order.where(buyer_id: User.where(demo: true).select(:id)).count,
        reviews: Review.joins(:order).where(orders: { buyer_id: User.where(demo: true).select(:id) }).count,
        listing_views: ListingView.joins(:listing).where(listings: { demo: true }).count,
        reports: Report.where(reporter_id: User.where(demo: true).select(:id)).count,
        notifications: Notification.where(recipient_id: User.where(demo: true).select(:id)).count
      }
    end
  end
end
