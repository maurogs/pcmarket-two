# frozen_string_literal: true

class BuybackRequest < ApplicationRecord
  include AASM

  STATUSES = %w[quoted accepted label_sent received inspected offer_revised
                paid rejected returned].freeze
  TIMELINE = %w[quoted accepted label_sent received inspected offer_revised].freeze
  TIMESTAMP_COLUMNS = {
    "quoted" => :created_at,
    "accepted" => :accepted_at,
    "label_sent" => :label_sent_at,
    "received" => :received_at,
    "inspected" => :inspected_at,
    "offer_revised" => :revised_at,
    "paid" => :paid_at,
    "rejected" => :rejected_at,
    "returned" => :returned_at
  }.freeze

  belongs_to :buyback_quote
  belongs_to :user

  enum :component_type, { gpu: 0, cpu: 1 }, scopes: false

  encrypts :iban

  validates :component_model, presence: true
  validates :condition, inclusion: { in: BuybackPrice::CONDITION_KEYS }
  validates :status, inclusion: { in: STATUSES }
  validates :reference, presence: true, uniqueness: true
  validates :offer_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :iban, presence: true, iban: true
  validates :full_name, :line1, :city, :postal_code, :country_code, presence: true

  before_validation :assign_reference, on: :create
  before_validation :normalise_iban
  before_validation :extract_iban_last4

  scope :recent, -> { order(created_at: :desc, id: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  aasm column: :status, whiny_transitions: false do
    state :quoted, initial: true
    state :accepted
    state :label_sent
    state :received
    state :inspected
    state :offer_revised
    state :paid
    state :rejected
    state :returned

    event :accept do
      before :stamp_accepted
      transitions from: :quoted, to: :accepted
    end

    event :send_label do
      before :stamp_label_sent
      transitions from: :accepted, to: :label_sent, guard: :tracking_present?
    end

    event :receive do
      before :stamp_received
      transitions from: :label_sent, to: :received
    end

    event :mark_inspected do
      before :stamp_inspected
      transitions from: :received, to: :inspected
    end

    event :revise_offer do
      before :stamp_revised
      transitions from: :inspected, to: :offer_revised, guard: :revised_offer_present?
    end

    event :accept_revision do
      before :stamp_accepted
      transitions from: :offer_revised, to: :accepted
    end

    event :mark_paid do
      before :stamp_paid
      transitions from: %i[inspected accepted], to: :paid
    end

    event :reject do
      before :stamp_rejected
      transitions from: :inspected, to: :rejected
    end

    event :return_to_sender do
      before :stamp_returned
      transitions from: %i[inspected offer_revised], to: :returned
    end
  end

  def final_offer_cents
    revised_offer_cents.presence || offer_cents
  end

  def masked_iban
    return if iban_last4.blank?

    "•••• #{iban_last4}"
  end

  def timeline
    terminal = status if %w[paid rejected returned].include?(status)
    TIMELINE.filter_map do |key|
      next if key == "offer_revised" && revised_offer_cents.blank?

      at = timestamp_for(key)
      state = if at.present?
        :done
      elsif key == status
        :current
      else
        :pending
      end
      { key: key, at: at, state: state }
    end + Array(terminal_timeline(terminal))
  end

  private

  def assign_reference
    self.reference ||= "PCM-T-#{Time.current.year}-#{SecureRandom.hex(3).upcase}"
  end

  def normalise_iban
    self.iban = IbanValidator.normalise(iban) if iban.present?
  end

  def extract_iban_last4
    self.iban_last4 = IbanValidator.last4(iban) if iban.present?
  end

  def tracking_present?
    tracking_number.present?
  end

  def revised_offer_present?
    revised_offer_cents.to_i.positive?
  end

  def stamp_accepted = self.accepted_at ||= Time.current
  def stamp_label_sent = self.label_sent_at ||= Time.current
  def stamp_received = self.received_at ||= Time.current
  def stamp_inspected = self.inspected_at ||= Time.current
  def stamp_revised = self.revised_at ||= Time.current
  def stamp_paid = self.paid_at ||= Time.current
  def stamp_rejected = self.rejected_at ||= Time.current
  def stamp_returned = self.returned_at ||= Time.current

  def timestamp_for(key)
    column = TIMESTAMP_COLUMNS[key.to_s]
    public_send(column) if column
  end

  def terminal_timeline(status)
    return [] if status.blank?

    [ { key: status, at: timestamp_for(status), state: :current } ]
  end
end
