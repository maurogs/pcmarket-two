# frozen_string_literal: true

# PC Finder reference data: the games used by the quiz and the GPU/CPU model
# → performance tier tables. Everything is idempotent and keyed by slug or
# pattern so repeat runs update values without duplicating rows.

band_deltas = {
  "1080p_60" => 0, "1080p_144" => 1, "1080p_240" => 3,
  "1440p_60" => 1, "1440p_144" => 2, "1440p_240" => 4,
  "4k_60" => 3, "4k_144" => 5, "4k_240" => 6
}
cpu_deltas = { 0 => 0, 1 => 0, 2 => 1, 3 => 1, 4 => 2, 5 => 2, 6 => 3 }

requirements = lambda do |base_gpu, base_cpu|
  band_deltas.to_h do |key, delta|
    [ key, {
      gpu: [ [ base_gpu + delta, 1 ].max, 10 ].min,
      cpu: [ [ base_cpu + cpu_deltas.fetch(delta, 0), 1 ].max, 10 ].min
    } ]
  end
end

games = [
  { slug: "fortnite", name: "Fortnite", gpu: 4, cpu: 3 },
  { slug: "league-of-legends", name: "League of Legends", gpu: 2, cpu: 2 },
  { slug: "valorant", name: "Valorant", gpu: 2, cpu: 2 },
  { slug: "counter-strike-2", name: "Counter-Strike 2", gpu: 4, cpu: 3 },
  { slug: "minecraft", name: "Minecraft", gpu: 3, cpu: 2 },
  { slug: "call-of-duty-warzone", name: "Call of Duty: Warzone", gpu: 6, cpu: 5 },
  { slug: "cyberpunk-2077", name: "Cyberpunk 2077", gpu: 8, cpu: 6 },
  { slug: "baldurs-gate-3", name: "Baldur's Gate 3", gpu: 7, cpu: 6 },
  { slug: "gta-v", name: "GTA V", gpu: 4, cpu: 3 },
  { slug: "ea-sports-fc", name: "EA Sports FC", gpu: 4, cpu: 3 },
  { slug: "marvel-rivals", name: "Marvel Rivals", gpu: 6, cpu: 5 },
  { slug: "elden-ring", name: "Elden Ring", gpu: 6, cpu: 5 }
]

games.each_with_index do |data, index|
  tiers = requirements.call(data[:gpu], data[:cpu])
  game = Game.find_or_initialize_by(slug: data[:slug])
  game.assign_attributes(
    name: data[:name],
    position: index + 1,
    active: true,
    min_gpu_tier: tiers.transform_values { |entry| entry[:gpu] },
    min_cpu_tier: tiers.transform_values { |entry| entry[:cpu] }
  )
  game.save!

  cover_path = Rails.root.join("db/seeds/game_covers/#{data[:slug]}.png")
  next if game.cover.attached? || !File.exist?(cover_path)

  game.cover.attach(
    io: File.open(cover_path),
    filename: "#{data[:slug]}.png",
    content_type: "image/png"
  )
end

gpu_tiers = {
  "gtx 1650" => 2, "gtx 1660" => 3,
  "rtx 2060" => 4, "rtx 2070" => 5, "rtx 2080" => 6,
  "rtx 3050" => 4, "rtx 3060" => 5, "rtx 3070" => 6, "rtx 3080" => 7, "rtx 3090" => 8,
  "rtx 4060" => 6, "rtx 4070" => 7, "rtx 4070 ti" => 8, "rtx 4080" => 9, "rtx 4090" => 10,
  "rtx 5060" => 7, "rtx 5070" => 8, "rtx 5080" => 9, "rtx 5090" => 10,
  "rx 5500" => 2, "rx 5600" => 3, "rx 5700" => 4,
  "rx 6600" => 5, "rx 6700" => 6, "rx 6800" => 7, "rx 6900" => 8,
  "rx 7600" => 6, "rx 7700" => 7, "rx 7800" => 8, "rx 7900" => 9,
  "rx 9060" => 7, "rx 9070" => 8, "rx 9080" => 9, "rx 9090" => 10,
  "arc a380" => 3, "arc a580" => 4, "arc a750" => 5, "arc a770" => 6, "arc b580" => 6
}

gpu_tiers.each_with_index do |(pattern, tier), index|
  row = GpuTier.find_or_initialize_by(pattern: pattern)
  row.assign_attributes(tier: tier, position: index + 1, active: true)
  row.save!
end

cpu_tiers = {}
(10..15).each do |generation|
  cpu_tiers["i3-#{generation}"] = { 10 => 2, 11 => 2, 12 => 3, 13 => 3, 14 => 3, 15 => 4 }.fetch(generation)
  cpu_tiers["i5-#{generation}"] = { 10 => 4, 11 => 4, 12 => 5, 13 => 5, 14 => 5, 15 => 6 }.fetch(generation)
  cpu_tiers["i7-#{generation}"] = { 10 => 5, 11 => 5, 12 => 6, 13 => 6, 14 => 6, 15 => 7 }.fetch(generation)
  cpu_tiers["i9-#{generation}"] = { 10 => 6, 11 => 6, 12 => 7, 13 => 7, 14 => 7, 15 => 8 }.fetch(generation)
end
cpu_tiers.merge!(
  "core ultra 5" => 6, "core ultra 7" => 7, "core ultra 9" => 8,
  "ryzen 3 3" => 3, "ryzen 3 5" => 4, "ryzen 3 7" => 4, "ryzen 3 9" => 5,
  "ryzen 5 3" => 4, "ryzen 5 5" => 5, "ryzen 5 7" => 6, "ryzen 5 9" => 6,
  "ryzen 7 3" => 5, "ryzen 7 5" => 6, "ryzen 7 7" => 7, "ryzen 7 9" => 7,
  "ryzen 9 3" => 6, "ryzen 9 5" => 7, "ryzen 9 7" => 8, "ryzen 9 9" => 8
)

cpu_tiers.each_with_index do |(pattern, tier), index|
  row = CpuTier.find_or_initialize_by(pattern: pattern)
  row.assign_attributes(tier: tier, position: index + 1, active: true)
  row.save!
end
