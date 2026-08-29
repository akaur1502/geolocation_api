module Api
    module V1
      class LocationsController < BaseController
        # POST /api/v1/locations
        # Body: { "query": "<ip or url>" }
        #
        # Store-and-reuse: if we've already stored this query, return it instead
        # of calling the provider again.
        def create
          query = params[:query] || params.dig(:location, :query)
          existing = Location.find_by(query: query&.strip)
          return render_location(existing, status: :ok) if existing

          data = Geolocation::Lookup.new.call(query.to_s)
          location = Location.create!(data)
          render_location(location, status: :created)
        end

        # GET /api/v1/locations/:query
        def show
          location = Location.find_by!(query: params[:query])
          render_location(location, status: :ok)
        end

        # DELETE /api/v1/locations/:query
        def destroy
          location = Location.find_by!(query: params[:query])
          location.destroy
          head :no_content
        end

        private

        def render_location(location, status:)
          render json: LocationSerializer.new(location).serializable_hash, status: status
        end
      end
    end
end
