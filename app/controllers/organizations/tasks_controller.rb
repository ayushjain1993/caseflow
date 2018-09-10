class Organizations::TasksController < OrganizationsController
  before_action :verify_organization_access, only: [:index]
  before_action :verify_role_access, only: [:index]
  before_action :verify_feature_access, only: [:index]

  def index
    tasks = organization.tasks.where.not(status: "completed")
    appeals = tasks.map(&:appeal).uniq

    render json: {
      tasks: json_tasks(tasks),
      appeals: json_appeals(appeals)
    }
  end

  private

  def organization_url
    params[:organization_url]
  end

  def json_tasks(tasks)
    ActiveModelSerializers::SerializableResource.new(
      tasks,
      each_serializer: ::WorkQueue::TaskSerializer
    ).as_json
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::AppealSerializer
    ).as_json
  end
end
