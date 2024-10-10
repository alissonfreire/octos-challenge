defmodule OctosChallengeWeb.CameraController do
  @moduledoc false
  use OctosChallengeWeb, :controller

  use PhoenixSwagger

  alias OctosChallenge.UserService

  swagger_path :index do
    get("/cameras")
    summary("List all users")
    description("List all users with all cameras enabled")

    parameters do
      camera_name(:query, :string, "Camera name",
        required: false,
        example: "John - 1 Hikvision - 1"
      )

      camera_brand(:query, :string, "Camera brand", required: false, example: "Hikvision")
      order_by(:query, :string, "Order by camera name", required: false, example: "ASC")

      paginate(:query, :boolean, "Whether to return paged users or not",
        required: false,
        example: true
      )

      per_page(:query, :integer, "number of items per pages", required: false, example: true)
      page(:query, :integer, "Pager number", required: false, example: true)
    end

    response(200, "Ok", Schema.ref(:DataPaginated))
  end

  def index(conn, params) do
    data = UserService.get_all_users(params)

    render(conn, :index, data: data)
  end

  def swagger_definitions do
    %{
      User:
        swagger_schema do
          title("User")
          description("A normal user")

          properties do
            id(:string, "The ID of the user")
            name(:string, "The name of user", required: true)
            disconnected_at(:string, "When was the is disconnected", format: "ISO-8601")
            inserted_at(:string, "When was the user initially inserted", format: "ISO-8601")
            updated_at(:string, "When was the user last updated", format: "ISO-8601")

            cameras(
              Schema.new do
                type(:array)
                items(Schema.ref(:Camera))
              end
            )
          end

          example(%{
            id: 1,
            name: "John",
            disconnected_at: "2017-03-21T14:00:00Z",
            inserted_at: "2017-03-21T14:00:00Z",
            updated_at: "2017-03-21T14:00:00Z",
            cameras: [
              %{
                id: 1,
                name: "John Hikvision - 1",
                brand: "Hikvision",
                is_active: true,
                inserted_at: "2017-03-21T14:00:00Z",
                updated_at: "2017-03-21T14:00:00Z"
              }
            ]
          })
        end,
      Camera:
        swagger_schema do
          title("Camera")
          description("A user's camera")

          properties do
            id(:string, "The ID of the camera")
            name(:string, "The camera name", required: true)
            brand(:string, "The camera brand", required: true)
            is_active(:boolean, "The camera status", required: true)
            inserted_at(:string, "When was the camera initially inserted", format: "ISO-8601")
            updated_at(:string, "When was the camera last updated", format: "ISO-8601")
          end

          example(%{
            id: 1,
            name: "John Hikvision - 1",
            brand: "Hikvision",
            is_active: true,
            inserted_at: "2017-03-21T14:00:00Z",
            updated_at: "2017-03-21T14:00:00Z"
          })
        end,
      DataPaginated:
        swagger_schema do
          properties do
            meta(
              Schema.new do
                properties do
                  page(:integer, "Number of page")
                  per_page(:integer, "Number of items per page")
                  total(:integer, "Number total of items")
                  total_pages(:integer, "Number total of pages")
                end

                example(%{
                  page: 1,
                  per_page: 15,
                  total: 100,
                  total_pages: 6
                })
              end
            )

            data(
              Schema.new do
                type(:array)
                items(Schema.ref(:User))
              end
            )
          end
        end
    }
  end
end
