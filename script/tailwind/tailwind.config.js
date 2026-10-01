module.exports = {
  content: [
    "../../lib/templates/index.html.erb",
    "../../lib/assets/logo.svg"
  ],
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography")
  ]
}
