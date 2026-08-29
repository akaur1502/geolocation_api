module Api
    module V1
      # Base controller for all v1 API endpoints. Handles:
      #   - bearer-token authentication (endpoints are not public)
      #   - centralized error handling, so every failure returns a consistent
      #     JSON:API `errors` shape with a meaningful status code.
      class BaseController < ApplicationController
        before_action :authenticate!

        rescue_from Geolocation::Lookup::InvalidInput, with: :render_unprocessable
        rescue_from Geolocation::Lookup::UnsupportedIP, with: :render_unprocessable
        rescue_from ActiveRecord::RecordInvalid,        with: :render_unprocessable
        rescue_from ActiveRecord::RecordNotFound,       with: :render_not_found
        rescue_from Geolocation::ProviderError,         with: :render_bad_gateway

        private

        def authenticate!
          provided = request.headers["Authorization"].to_s.split(" ").last
          expected = ENV.fetch("API_TOKEN", "dev-local-token")

          return if ActiveSupport::SecurityUtils.secure_compare(provided.to_s, expected)

          render_error(status: :unauthorized, title: "Unauthorized",
                       detail: "A valid bearer token is required.")
        end

        def render_unprocessable(exception)
          render_error(status: :unprocessable_content, title: "Invalid request",
                       detail: exception.message)
        end

        def render_not_found(_exception)
          render_error(status: :not_found, title: "Not found",
                       detail: "The requested location was not found.")
        end

        def render_bad_gateway(exception)
          render_error(status: :bad_gateway, title: "Provider error",
                       detail: exception.message)
        end

        # Consistent JSON:API error envelope.
        def render_error(status:, title:, detail:)
          code = Rack::Utils.status_code(status)
          render json: {
            errors: [ { status: code.to_s, title: title, detail: detail } ]
          }, status: status
        end
      end
    end
end
