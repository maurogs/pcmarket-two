# frozen_string_literal: true

# 50 provinces plus the autonomous cities of Ceuta and Melilla (ISO 3166-2:ES).
SPANISH_PROVINCES = [
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

SPANISH_PROVINCES.each_with_index do |(code, name), index|
  Region.find_or_create_by!(country_code: "ES", code: code) do |region|
    region.name = name
    region.position = index + 1
  end
end
