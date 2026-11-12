# frozen_string_literal: true

module Api
  # Public API reference page. The pinned Redoc bundle is loaded only here.
  class DocsController < ApplicationController
    # The pinned Redoc bundle is loaded only on this page, so the CDN origin is
    # added to the policy here instead of for the whole site.
    content_security_policy do |policy|
      policy.script_src :self, "https://cdn.jsdelivr.net"
      policy.style_src :self, "https://fonts.googleapis.com", :unsafe_inline
      policy.img_src :self, :data, :blob
      policy.connect_src :self
      policy.worker_src :self, :blob
      policy.frame_src :self
    end
  end
end
