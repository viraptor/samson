# frozen_string_literal: true

class DockerRegistry
  class << self
    def check_config!
      return if ENV['DOCKER_REGISTRIES'].present?
      if ENV['DOCKER_REGISTRY']
        abort <<~DOC
          DOCKER_REGISTRY is deprecated!
          Build this url 'DOCKER_REGISTRY_USER:DOCKER_REGISTRY_PASS@DOCKER_REGISTRY/DOCKER_REPO_NAMESPACE'
          and set it as DOCKER_REGISTRIES env var
        DOC
      else
        abort '*** DOCKER_REGISTRIES environment variable must be configured when DOCKER_FEATURE is enabled ***'
      end
    end

    # TODO: might be best to use .fetch here and fail when it is an empty string to prevent weird usecases
    def all
      @all ||= ENV['DOCKER_REGISTRIES'].to_s.split(',').map { |url| new(url) }
    end

    def first
      all.first
    end
  end

  attr_accessor :username, :password, :credentials_expire_at # modified by ECR plugin

  def initialize(url)
    url = "https://#{url}" unless url.include?("://")
    @uri = URI.parse(url)
    @username = @uri.user
    @password = @uri.password
    @password = File.read(CGI.unescape(@password)) if @username == "_json_key"
  end

  def host
    @uri.host
  end

  def base
    @uri.host + @uri.path
  end
end
