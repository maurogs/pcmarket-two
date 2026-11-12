# frozen_string_literal: true

# Normalises public URLs:
#   * the Spanish home page is duplicated at /es; it redirects to / (other
#     Spanish pages stay reachable and canonicalise to the unprefixed URL).
#   * trailing slashes are removed (except for the root path).
# Both redirects are permanent and keep the query string.
class CanonicalUrlMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    path = env["PATH_INFO"].to_s
    target = nil

    if path == "/es" || path == "/es/"
      target = "/"
    elsif path.length > 1 && path.end_with?("/")
      target = path.sub(%r{/+\z}, "")
      target = "/" if target.empty?
    end

    return redirect(env, target) if target && target != path

    @app.call(env)
  end

  private

  def redirect(env, target)
    query = env["QUERY_STRING"].to_s
    location = query.empty? ? target : "#{target}?#{query}"
    body = "<html><body>Redirecting to <a href=\"#{location}\">#{location}</a></body></html>"

    [
      301,
      {
        "Location" => location,
        "Content-Type" => "text/html; charset=utf-8",
        "Content-Length" => body.bytesize.to_s,
        "Cache-Control" => "public, max-age=3600"
      },
      [ body ]
    ]
  end
end
