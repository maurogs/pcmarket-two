# frozen_string_literal: true

module Api
  module V1
    class ConversationsController < AuthenticatedController
      def index
        inbox = Inbox.new(user: current_user, params: request.query_parameters).call
        pagy, records = paginate_array(inbox.conversations)
        set_pagination_headers(pagy)
        render_collection(
          records, ConversationSerializer,
          meta: collection_meta(pagy, extra: { tab: inbox.tab }),
          options: { params: { user: current_user } }
        )
      end

      def show
        conversation = Conversation.for_user(current_user).find(params[:id])
        authorize conversation
        conversation.mark_read_for!(current_user)

        messages = conversation.messages.visible
                               .includes(:sender, images_attachments: :blob)
                               .order(id: :desc).limit(30).to_a.reverse
        offers = conversation.offers.recent.includes(:offerer).limit(20).to_a

        render_data({
          conversation: ConversationSerializer.new(
            conversation, params: { user: current_user }
          ).serializable_hash,
          messages: messages.map { |message| MessageSerializer.new(message).serializable_hash },
          offers: offers.map { |offer| OfferSerializer.new(offer, params: { user: current_user }).serializable_hash }
        })
      end

      def create
        authorize Conversation
        result = Conversations::FindOrCreate.new(
          buyer: current_user,
          listing: listing_param,
          store: store_param
        ).call

        unless result.success?
          raise Api::V1::Error.validation_failed(details: { base: result.errors })
        end

        render_resource(result.conversation, ConversationSerializer, status: :created,
                        options: { params: { user: current_user } })
      end

      private

      def listing_param
        return if params[:listing_id].blank?

        Listing.find(params[:listing_id])
      end

      def store_param
        return if params[:store_id].blank?

        Store.friendly.find(params[:store_id])
      end
    end
  end
end
