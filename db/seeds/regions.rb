# frozen_string_literal: true

# 50 provinces plus the autonomous cities of Ceuta and Melilla (ISO 3166-2:ES).
spanish_provinces = [
  [ "ES-A",  "Alicante" ],
  [ "ES-AB", "Albacete" ],
  [ "ES-AL", "Almería" ],
  [ "ES-AV", "Ávila" ],
  [ "ES-B",  "Barcelona" ],
  [ "ES-BA", "Badajoz" ],
  [ "ES-BI", "Bizkaia" ],
  [ "ES-BU", "Burgos" ],
  [ "ES-C",  "A Coruña" ],
  [ "ES-CA", "Cádiz" ],
  [ "ES-CC", "Cáceres" ],
  [ "ES-CE", "Ceuta" ],
  [ "ES-CO", "Córdoba" ],
  [ "ES-CR", "Ciudad Real" ],
  [ "ES-CS", "Castellón" ],
  [ "ES-CU", "Cuenca" ],
  [ "ES-GC", "Las Palmas" ],
  [ "ES-GI", "Girona" ],
  [ "ES-GR", "Granada" ],
  [ "ES-GU", "Guadalajara" ],
  [ "ES-H",  "Huelva" ],
  [ "ES-HU", "Huesca" ],
  [ "ES-J",  "Jaén" ],
  [ "ES-L",  "Lleida" ],
  [ "ES-LE", "León" ],
  [ "ES-LO", "La Rioja" ],
  [ "ES-LU", "Lugo" ],
  [ "ES-M",  "Madrid" ],
  [ "ES-MA", "Málaga" ],
  [ "ES-ML", "Melilla" ],
  [ "ES-MU", "Murcia" ],
  [ "ES-NA", "Navarra" ],
  [ "ES-O",  "Asturias" ],
  [ "ES-OR", "Ourense" ],
  [ "ES-P",  "Palencia" ],
  [ "ES-PM", "Illes Balears" ],
  [ "ES-PO", "Pontevedra" ],
  [ "ES-S",  "Cantabria" ],
  [ "ES-SA", "Salamanca" ],
  [ "ES-SE", "Sevilla" ],
  [ "ES-SG", "Segovia" ],
  [ "ES-SO", "Soria" ],
  [ "ES-SS", "Gipuzkoa" ],
  [ "ES-T",  "Tarragona" ],
  [ "ES-TE", "Teruel" ],
  [ "ES-TF", "Santa Cruz de Tenerife" ],
  [ "ES-TO", "Toledo" ],
  [ "ES-V",  "València" ],
  [ "ES-VA", "Valladolid" ],
  [ "ES-VI", "Araba" ],
  [ "ES-Z",  "Zaragoza" ],
  [ "ES-ZA", "Zamora" ]
].freeze

spanish_provinces.each_with_index do |(code, name), index|
  Region.find_or_create_by!(country_code: "ES", code: code) do |region|
    region.name = name
    region.position = index + 1
  end
end

# Phase 7b launch regions. GB keeps the four nations (counties can be imported
# from the admin screen); the other countries carry their top-level regions.
launch_regions = {
  "FR" => [
    [ "FR-ARA", "Auvergne-Rhône-Alpes" ], [ "FR-BFC", "Bourgogne-Franche-Comté" ],
    [ "FR-BRE", "Bretagne" ], [ "FR-CVL", "Centre-Val de Loire" ],
    [ "FR-COR", "Corse" ], [ "FR-GES", "Grand Est" ],
    [ "FR-HDF", "Hauts-de-France" ], [ "FR-IDF", "Île-de-France" ],
    [ "FR-NOR", "Normandie" ], [ "FR-NAQ", "Nouvelle-Aquitaine" ],
    [ "FR-OCC", "Occitanie" ], [ "FR-PDL", "Pays de la Loire" ],
    [ "FR-PAC", "Provence-Alpes-Côte d'Azur" ]
  ],
  "GB" => [
    [ "GB-ENG", "England" ], [ "GB-SCT", "Scotland" ],
    [ "GB-WLS", "Wales" ], [ "GB-NIR", "Northern Ireland" ]
  ],
  "DE" => [
    [ "DE-BW", "Baden-Württemberg" ], [ "DE-BY", "Bayern" ], [ "DE-BE", "Berlin" ],
    [ "DE-BB", "Brandenburg" ], [ "DE-HB", "Bremen" ], [ "DE-HH", "Hamburg" ],
    [ "DE-HE", "Hessen" ], [ "DE-MV", "Mecklenburg-Vorpommern" ],
    [ "DE-NI", "Niedersachsen" ], [ "DE-NW", "Nordrhein-Westfalen" ],
    [ "DE-RP", "Rheinland-Pfalz" ], [ "DE-SL", "Saarland" ], [ "DE-SN", "Sachsen" ],
    [ "DE-ST", "Sachsen-Anhalt" ], [ "DE-SH", "Schleswig-Holstein" ],
    [ "DE-TH", "Thüringen" ]
  ],
  "IT" => [
    [ "IT-21", "Piemonte" ], [ "IT-23", "Valle d'Aosta" ], [ "IT-25", "Lombardia" ],
    [ "IT-32", "Trentino-Alto Adige" ], [ "IT-34", "Veneto" ],
    [ "IT-36", "Friuli-Venezia Giulia" ], [ "IT-42", "Liguria" ],
    [ "IT-45", "Emilia-Romagna" ], [ "IT-52", "Toscana" ], [ "IT-55", "Umbria" ],
    [ "IT-57", "Marche" ], [ "IT-62", "Lazio" ], [ "IT-65", "Abruzzo" ],
    [ "IT-67", "Molise" ], [ "IT-72", "Campania" ], [ "IT-75", "Puglia" ],
    [ "IT-77", "Basilicata" ], [ "IT-78", "Calabria" ], [ "IT-82", "Sicilia" ],
    [ "IT-88", "Sardegna" ]
  ],
  "PT" => [
    [ "PT-01", "Aveiro" ], [ "PT-02", "Beja" ], [ "PT-03", "Braga" ],
    [ "PT-04", "Bragança" ], [ "PT-05", "Castelo Branco" ], [ "PT-06", "Coimbra" ],
    [ "PT-07", "Évora" ], [ "PT-08", "Faro" ], [ "PT-09", "Guarda" ],
    [ "PT-10", "Leiria" ], [ "PT-11", "Lisboa" ], [ "PT-12", "Portalegre" ],
    [ "PT-13", "Porto" ], [ "PT-14", "Santarém" ], [ "PT-15", "Setúbal" ],
    [ "PT-16", "Viana do Castelo" ], [ "PT-17", "Vila Real" ], [ "PT-18", "Viseu" ],
    [ "PT-20", "Açores" ], [ "PT-30", "Madeira" ]
  ]
}.freeze

launch_regions.each do |country_code, regions|
  regions.each_with_index do |(code, name), index|
    region = Region.find_or_initialize_by(country_code: country_code, code: code)
    region.assign_attributes(name: name, position: index + 1)
    region.save!
  end
end
