require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  setup do
    @project = projects(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:projects)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create project" do
    skip("TL to fix")
    assert_difference('Project.count') do
      post :create, project: { funding_current: @project.funding_current, funding_limit: @project.funding_limit, funding_threshold: @project.funding_threshold, has_started: @project.has_started, investors_count: @project.investors_count, location: @project.location, source: @project.source, title: @project.title, url: @project.url }
    end

    assert_redirected_to project_path(assigns(:project))
  end

  test "should show project" do
    get :show, id: @project
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @project
    assert_response :success
  end

  test "should update project" do
    patch :update, id: @project, project: { funding_current: @project.funding_current, funding_limit: @project.funding_limit, funding_threshold: @project.funding_threshold, has_started: @project.has_started, investors_count: @project.investors_count, location: @project.location, source: @project.source, title: @project.title, url: @project.url }
    assert_redirected_to project_path(assigns(:project))
  end

  test "should destroy project" do
    assert_difference('Project.count', -1) do
      delete :destroy, id: @project
    end

    assert_redirected_to projects_path
  end
end
