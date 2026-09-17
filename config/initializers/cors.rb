Rails.application.config.middleware.insert_before 0, Rack::Cors do
allow do
origins(
"http://localhost:3001",
"http://localhost:5000",
"https://task-19-628h.onrender.com"
)


resource "/api/*",
  headers: :any,
  methods: [
    :get,
    :post,
    :put,
    :patch,
    :delete,
    :options,
    :head
  ]


end
end
