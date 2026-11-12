# frozen_string_literal: true

# Builds the three inbox tabs: chats, offers and blocked users.
class Inbox
  TABS = %w[chats offers blocked].freeze

  def initialize(user:, params: {})
    @user = user
    raw = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    @params = raw.deep_stringify_keys
  end

  def call
    self
  end

  def tab
    value = @params["tab"].to_s
    value = "chats" if value == "offers" && !Flipper.enabled?(:offers)
    TABS.include?(value) ? value : "chats"
  end

  def conversations
    @conversations ||= Conversation.visible_for(@user)
                                    .recent
                                    .includes(
                                      { listing: { photos: { image_attachment: :blob } } },
                                      :store,
                                      { buyer: { avatar_attachment: :blob } },
                                      { seller: { avatar_attachment: :blob } },
                                      messages: [ :sender, { images_attachments: :blob } ]
                                    )
                                    .to_a
                                    .reject { |conversation| Block.between?(@user, conversation.other_party_for(@user)) }
  end

  def offers
    @offers ||= Offer.for_user(@user)
                     .recent
                     .includes({ listing: { photos: { image_attachment: :blob } } },
                               :buyer, :offerer, :conversation)
                     .to_a
  end

  def blocks
    @blocks ||= @user.blocks.includes(blocked: { avatar_attachment: :blob }).order(created_at: :desc).to_a
  end

  def unread_total
    conversations.sum { |conversation| conversation.unread_count_for(@user) }
  end
end
