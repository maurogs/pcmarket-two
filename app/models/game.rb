# frozen_string_literal: true

class Game < ApplicationRecord
  RESOLUTIONS = %w[1080p 1440p 4k].freeze
  FPS_BANDS = [ 60, 144, 240 ].freeze
  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  IMAGE_MAX_SIZE = 5.megabytes

  has_one_attached :cover do |attachable|
    attachable.variant :card, resize_to_limit: [ 480, 640 ], format: :webp
    attachable.variant :thumb, resize_to_limit: [ 160, 214 ], format: :webp
  end

  validates :name, presence: true, length: { in: 2..80 }
  validates :slug, presence: true, uniqueness: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :tier_requirements_are_integers
  validates :cover,
            content_type: { in: IMAGE_CONTENT_TYPES, message: :invalid_image_type },
            size: { less_than_or_equal_to: IMAGE_MAX_SIZE, message: :image_too_large }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name, :id) }

  before_validation :assign_slug, if: -> { slug.blank? }

  # Exact band first, then the nearest lower band for the resolution, then the
  # lowest band, and finally the highest requirement in the table. This makes
  # sparse admin-created requirement maps safe.
  def requirement_for(kind, resolution, fps)
    data = (kind.to_s == "cpu" ? min_cpu_tier : min_gpu_tier).to_h
    values = data.transform_keys(&:to_s).transform_values(&:to_i)
    exact = values["#{resolution}_#{fps}"]
    return exact if exact

    same_resolution = values.select { |key, _| key.start_with?("#{resolution}_") }
    if same_resolution.any?
      at_or_below = same_resolution.select { |key, _| key.split("_").last.to_i <= fps.to_i }
      chosen = if at_or_below.any?
        at_or_below.max_by { |key, _| key.split("_").last.to_i }
      else
        same_resolution.min_by { |key, _| key.split("_").last.to_i }
      end
      return chosen.last
    end

    values.values.max || 0
  end

  def gpu_requirement(resolution, fps)
    requirement_for(:gpu, resolution, fps)
  end

  def cpu_requirement(resolution, fps)
    requirement_for(:cpu, resolution, fps)
  end

  private

  def assign_slug
    self.slug = name.to_s.parameterize
  end

  def tier_requirements_are_integers
    %i[min_gpu_tier min_cpu_tier].each do |attribute|
      value = public_send(attribute)
      next if value.blank?
      next if value.is_a?(Hash) && value.values.all? { |tier| tier.to_s.match?(/\A\d+\z/) }

      errors.add(attribute, :invalid)
    end
  end
end
